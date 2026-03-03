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
    
    # TODO: Отправить событие OrderCreatedEvent в RabbitMQ
    
    return order

@router.get("/get", response_model=list[OrderResponse])
async def get_orders(
    order_request_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заказов пользователя или по заявке"""
    repo = OrderRepository(db)
    
    # Если указан order_request_id, возвращаем заказы по заявке
    if order_request_id is not None:
        orders = await repo.get_by_order_request(order_request_id)
        # Фильтруем только заказы текущего пользователя (клиента)
        user_id = current_user["id"]
        orders = [o for o in orders if o.client_id == user_id]
        return orders
    
    # Иначе возвращаем все заказы пользователя
    user_id = current_user["id"]
    orders = await repo.get_by_user(user_id)
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
    
    # TODO: Отправить событие UserEnrolledEvent в RabbitMQ
    
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
    
    # TODO: Отправить событие OrderEnrollmentDateConfirmedEvent в RabbitMQ
    
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
    
    # TODO: Отправить событие OrderEnrollmentDateChangedEvent в RabbitMQ
    
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
    
    # TODO: Отправить событие OrderStatusChangedEvent в RabbitMQ
    
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
