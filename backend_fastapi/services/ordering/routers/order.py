"""Роутеры для Ordering Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_client
from ..models import Order, OrderStatus
from ..schemas import OrderResponse, CreateOrderRequest, ChangeEnrollmentDateRequest
from ..repositories import OrderRepository
from datetime import datetime

router = APIRouter(prefix="/api/order", tags=["order"])

@router.post("/create", response_model=OrderResponse)
async def create_order(
    request: CreateOrderRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание заказа (компания)"""
    company_id = current_user["id"]
    
    # Проверка, что пользователь - компания
    if current_user.get("user_type") != "Company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only companies can create orders"
        )
    
    repo = OrderRepository(db)
    
    # Проверка, нет ли уже заказа
    existing = await repo.get_by_request_and_company(request.order_request_id, company_id)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order already exists"
        )
    
    order = Order(
        order_request_id=request.order_request_id,
        company_id=company_id,
        client_id=request.receiver_id,
        price=request.price or 0,
        prepayment=request.prepayment or 0,
        deadline=request.deadline or 0,
        enrollment_date=request.enrollment_date,
        status=OrderStatus.ACTIVE.value
    )
    
    order = await repo.add(order)
    
    # Отправка push-уведомления клиенту о новом ответе компании
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from common.push_notification_service import send_push_notification
        from services.authentication.models import User
        
        client = db.query(User).filter(User.id == request.receiver_id).first()
        if client and client.device_token:
            # Получаем название компании
            from services.company_service.models import Company
            company = db.query(Company).filter(Company.guid == company_id).first()
            company_name = company.title if company else "Компания"
            
            send_push_notification(
                device_token=client.device_token,
                title="Новый ответ на заявку",
                body=f"{company_name} ответил(а) на вашу заявку",
                data={
                    "type": "order_created",
                    "order_id": str(order.id),
                    "order_request_id": str(request.order_request_id),
                    "company_id": str(company_id)
                }
            )
    except Exception as e:
        print(f"Error sending push notification: {e}")
    
    # Отправка события OrderCreatedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("OrderCreatedEvent", {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "price": str(order.price) if order.price else None,
            "deadline": str(order.deadline) if order.deadline else None,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish OrderCreatedEvent: {e}")
    
    return order

@router.get("/get", response_model=list[OrderResponse])
async def get_orders(
    order_request_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заказов пользователя или по заявке"""
    repo = OrderRepository(db)
    user_id = current_user["id"]
    user_type = current_user.get("user_type")
    
    # Если указан order_request_id, возвращаем заказы по заявке
    if order_request_id is not None:
        orders = await repo.get_by_order_request(order_request_id)
        
        # Фильтруем по типу пользователя
        if user_type == "Client":
            # Для клиентов - только заказы, где клиент - это текущий пользователь
            orders = [o for o in orders if o.client_id == user_id]
        elif user_type == "Company":
            # Для компаний - только заказы, где компания - это текущий пользователь
            orders = [o for o in orders if o.company_id == user_id]
        else:
            # Для других типов - пустой список
            orders = []
        
        return orders
    
    # Иначе возвращаем все заказы пользователя с явной фильтрацией по типу
    if user_type == "Client":
        # Для клиентов - только заказы, где клиент - это текущий пользователь
        orders = db.query(Order).filter(Order.client_id == user_id).all()
    elif user_type == "Company":
        # Для компаний - только заказы, где компания - это текущий пользователь
        orders = db.query(Order).filter(Order.company_id == user_id).all()
    else:
        # Для других типов - пустой список
        orders = []
    
    return orders

@router.put("/enroll", response_model=OrderResponse)
async def enroll(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Записаться на услугу"""
    repo = OrderRepository(db)
    order = await repo.get(order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order.is_enrolled = True
    result = await repo.update(order)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to enroll"
        )
    
    # Отправка события через WebSocket
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from services.chat.websocket import send_order_event_to_user
        
        order_data = {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": order.client_id,
            "company_id": order.company_id,
            "enrollment_date": order.enrollment_date.isoformat() if order.enrollment_date else None,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": True,
            "status": order.status
        }
        
        await send_order_event_to_user(order.client_id, "enrolled", order_data)
        await send_order_event_to_user(order.company_id, "enrolled", order_data)
    except Exception as e:
        print(f"Error sending WebSocket event: {e}")
    
    # Отправка push-уведомления компании о записи клиента
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from common.push_notification_service import send_push_notification
        from services.authentication.models import User
        
        company = db.query(User).filter(User.id == order.company_id).first()
        if company and company.device_token:
            # Получаем имя клиента
            client = db.query(User).filter(User.id == order.client_id).first()
            client_name = client.user_name if client else "Клиент"
            
            send_push_notification(
                device_token=company.device_token,
                title="Клиент записался",
                body=f"{client_name} записался на услугу",
                data={
                    "type": "order_enrolled",
                    "order_id": str(order.id),
                    "client_id": str(order.client_id)
                }
            )
    except Exception as e:
        print(f"Error sending push notification: {e}")
    
    # Отправка события UserEnrolledEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserEnrolledEvent", {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserEnrolledEvent: {e}")
    
    return order

@router.put("/confirmEnrollmentDate", response_model=OrderResponse)
async def confirm_enrollment_date(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Подтверждение даты записи"""
    repo = OrderRepository(db)
    order = await repo.get(order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order.is_date_confirmed = True
    order.is_enrolled = True
    result = await repo.update(order)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to confirm date"
        )
    
    # Отправка события через WebSocket
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from services.chat.websocket import send_order_event_to_user
        
        order_data = {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": order.client_id,
            "company_id": order.company_id,
            "enrollment_date": order.enrollment_date.isoformat() if order.enrollment_date else None,
            "is_date_confirmed": True,
            "is_enrolled": True,
            "status": order.status
        }
        
        await send_order_event_to_user(order.client_id, "confirmed", order_data)
        await send_order_event_to_user(order.company_id, "confirmed", order_data)
    except Exception as e:
        print(f"Error sending WebSocket event: {e}")
    
    # Отправка события OrderEnrollmentDateConfirmedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("OrderEnrollmentDateConfirmedEvent", {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish OrderEnrollmentDateConfirmedEvent: {e}")
    
    return order

@router.put("/changeOrderEnrollmentDate", response_model=OrderResponse)
async def change_enrollment_date(
    request: ChangeEnrollmentDateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение даты записи"""
    user_id = current_user["id"]
    repo = OrderRepository(db)
    order = await repo.get(request.order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order.enrollment_date = request.enrollment_date
    order.is_date_confirmed = (user_id != order.client_id)
    order.user_changed_enrollment_date_guid = user_id
    result = await repo.update(order)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to change date"
        )
    
    # Отправка события через WebSocket
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from services.chat.websocket import send_order_event_to_user
        
        # Отправляем событие клиенту и компании
        order_data = {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": order.client_id,
            "company_id": order.company_id,
            "enrollment_date": order.enrollment_date.isoformat() if order.enrollment_date else None,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": order.is_enrolled,
            "status": order.status
        }
        
        await send_order_event_to_user(order.client_id, "enrollmentDateChanged", order_data)
        await send_order_event_to_user(order.company_id, "enrollmentDateChanged", order_data)
    except Exception as e:
        print(f"Error sending WebSocket event: {e}")
    
    # Отправка события OrderEnrollmentDateChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("OrderEnrollmentDateChangedEvent", {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish OrderEnrollmentDateChangedEvent: {e}")
    
    return order

@router.put("/finishOrder", response_model=OrderResponse)
async def finish_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Завершение заказа"""
    repo = OrderRepository(db)
    order = await repo.get(order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order.status = OrderStatus.FINISHED.value
    result = await repo.update(order)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to finish order"
        )
    
    # Отправка события через WebSocket
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from services.chat.websocket import send_order_event_to_user
        
        order_data = {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": order.client_id,
            "company_id": order.company_id,
            "enrollment_date": order.enrollment_date.isoformat() if order.enrollment_date else None,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": order.is_enrolled,
            "status": OrderStatus.FINISHED.value
        }
        
        await send_order_event_to_user(order.client_id, "statusChanged", order_data)
        await send_order_event_to_user(order.company_id, "statusChanged", order_data)
    except Exception as e:
        print(f"Error sending WebSocket event: {e}")
    
    # Отправка события OrderStatusChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        # Получаем старый статус из базы (если нужно)
        old_status = None  # Можно добавить логику для получения старого статуса
        publish_event_sync("OrderStatusChangedEvent", {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "status": order.status,
            "old_status": old_status,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish OrderStatusChangedEvent: {e}")
    
    return order

@router.put("/cancelEnrollment", response_model=OrderResponse)
async def cancel_enrollment(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отмена записи"""
    repo = OrderRepository(db)
    order = await repo.get(order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    order.is_enrolled = False
    order.enrollment_date = None
    result = await repo.update(order)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to cancel enrollment"
        )
    
    return order

@router.put("/addReview")
async def add_review(
    client_id: str,
    company_id: str,
    db: Session = Depends(get_db)
):
    """Проверка и добавление возможности оставить отзыв (используется Review Service)"""
    repo = OrderRepository(db)
    
    # Ищем завершенный заказ между клиентом и компанией
    orders = await repo.get_by_users(client_id, company_id)
    
    for order in orders:
        # Проверяем, что заказ завершен и отзыв еще не оставлен
        if order.status == OrderStatus.FINISHED.value:
            if not order.reviews or client_id not in order.reviews:
                # Добавляем ID клиента в список отзывов (как маркер, что отзыв можно оставить)
                if not order.reviews:
                    order.reviews = []
                if client_id not in order.reviews:
                    order.reviews.append(client_id)
                    result = await repo.update(order)
                    if result:
                        return {"success": True, "message": "Review can be added"}
    
    return {"success": False, "message": "No finished order found or review already added"}

@router.put("/addReviewToOrder")
async def add_review_to_order(
    order_id: int,
    review_guid: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Добавление отзыва к заказу (внутренний метод)"""
    repo = OrderRepository(db)
    order = await repo.get(order_id)
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )
    
    if not order.reviews:
        order.reviews = []
    
    if review_guid not in order.reviews:
        order.reviews.append(review_guid)
        result = await repo.update(order)
        
        if not result:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to add review"
            )
    
    return {"message": "Review added successfully"}
