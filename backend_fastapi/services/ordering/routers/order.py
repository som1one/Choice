"""Роутеры для Ordering Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_client
from ..models import Order, OrderStatus
from ..schemas import OrderResponse, CreateOrderRequest, ChangeEnrollmentDateRequest
from ..repositories import OrderRepository
from datetime import datetime
from services.client_service.models import Client
from services.company_service.models import Company
import uuid

router = APIRouter(prefix="/api/order", tags=["order"])


def _parse_uuid(value: str | None) -> uuid.UUID | None:
    if not value:
        return None
    try:
        return uuid.UUID(str(value))
    except Exception:
        return None


def _normalize_order(order: Order) -> Order:
    """Нормализует старые записи заказа, чтобы response_model не падал."""
    if order.reviews is None:
        order.reviews = []
    if order.is_enrolled is None:
        order.is_enrolled = False
    if order.is_date_confirmed is None:
        order.is_date_confirmed = True
    if order.status is None:
        order.status = OrderStatus.ACTIVE.value
    return order

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
        # Повторный отклик по той же заявке трактуем как обновление существующего заказа
        if request.price is not None:
            existing.price = request.price
        if request.prepayment is not None:
            existing.prepayment = request.prepayment
        if request.deadline is not None:
            existing.deadline = request.deadline
        if request.response_text is not None:
            existing.response_text = request.response_text
        if request.specialist_name is not None:
            existing.specialist_name = request.specialist_name
        if request.specialist_phone is not None:
            existing.specialist_phone = request.specialist_phone
        if request.enrollment_date is not None:
            existing.enrollment_date = request.enrollment_date

        updated = await repo.update(existing)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update existing order"
            )
        return _normalize_order(existing)
    
    # receiver_id может прийти как GUID клиента или как внутренний numeric client_id
    normalized_receiver_id = str(request.receiver_id).strip()
    try:
        uuid.UUID(normalized_receiver_id)
    except Exception:
        # Пытаемся трактовать receiver_id как внутренний ID клиента и преобразовать в GUID
        if normalized_receiver_id.isdigit():
            client_row = db.query(Client).filter(Client.id == int(normalized_receiver_id)).first()
            if not client_row:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Receiver client not found"
                )
            normalized_receiver_id = str(client_row.guid)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="receiver_id must be client guid or numeric client id"
            )

    order = Order(
        order_request_id=request.order_request_id,
        company_id=company_id,
        client_id=normalized_receiver_id,
        price=request.price or 0,
        prepayment=request.prepayment or 0,
        deadline=request.deadline or 0,
        response_text=request.response_text,
        specialist_name=request.specialist_name,
        specialist_phone=request.specialist_phone,
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
        
        client_uuid = _parse_uuid(normalized_receiver_id)
        client = db.query(User).filter(User.id == client_uuid).first() if client_uuid else None
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
    
    return _normalize_order(order)

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
            user_id_str = str(user_id)
            orders = [o for o in orders if str(o.client_id) == user_id_str]
        elif user_type == "Company":
            # Для компаний - только заказы, где компания - это текущий пользователь
            user_id_str = str(user_id)
            orders = [o for o in orders if str(o.company_id) == user_id_str]
        else:
            # Для других типов - пустой список
            orders = []
        
        return [_normalize_order(order) for order in orders]
    
    # Иначе возвращаем все заказы пользователя с явной фильтрацией по типу
    if user_type == "Client":
        # Для клиентов - только заказы, где клиент - это текущий пользователь
        orders = db.query(Order).filter(Order.client_id == str(user_id)).all()
    elif user_type == "Company":
        # Для компаний - только заказы, где компания - это текущий пользователь
        orders = db.query(Order).filter(Order.company_id == str(user_id)).all()
    else:
        # Для других типов - пустой список
        orders = []
    
    return [_normalize_order(order) for order in orders]

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
    
    return _normalize_order(order)

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
    
    return _normalize_order(order)

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
    
    return _normalize_order(order)

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
    
    return _normalize_order(order)

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
    
    return _normalize_order(order)

@router.put("/addReview")
async def add_review(
    client_id: str,
    company_id: str,
    reviewer_id: str | None = None,
    reserve: bool = True,
    db: Session = Depends(get_db)
):
    """Проверка и добавление возможности оставить отзыв (используется Review Service)"""
    repo = OrderRepository(db)

    # Backward compatibility: client_id/company_id могут приходить как внутренние numeric id
    normalized_client_id = str(client_id).strip()
    try:
        uuid.UUID(normalized_client_id)
    except Exception:
        if normalized_client_id.isdigit():
            client_row = db.query(Client).filter(Client.id == int(normalized_client_id)).first()
            if client_row:
                normalized_client_id = str(client_row.guid)

    normalized_company_id = str(company_id).strip()
    try:
        uuid.UUID(normalized_company_id)
    except Exception:
        if normalized_company_id.isdigit():
            company_row = db.query(Company).filter(Company.id == int(normalized_company_id)).first()
            if company_row:
                normalized_company_id = str(company_row.guid)

    reviewer_marker = reviewer_id or normalized_client_id
    
    # Ищем завершенный заказ между клиентом и компанией
    orders = await repo.get_by_users(normalized_client_id, normalized_company_id)
    
    for order in orders:
        # Проверяем, что заказ завершен
        if order.status == OrderStatus.FINISHED.value:
            if not order.reviews:
                order.reviews = []

            already_left = reviewer_marker in order.reviews
            if already_left:
                return {"success": False, "message": "Review already added"}

            # Режим reserve=true: резервируем право отзыва (используется review-service)
            if reserve:
                order.reviews.append(reviewer_marker)
                result = await repo.update(order)
                if result:
                    return {"success": True, "message": "Review can be added"}
                return {"success": False, "message": "Failed to reserve review"}

            # Режим reserve=false: только проверка (используется frontend)
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
