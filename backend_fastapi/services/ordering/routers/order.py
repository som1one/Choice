"""Роутеры для Ordering Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user
from ..models import Order, OrderStatus
from ..schemas import OrderResponse, CreateOrderRequest, ChangeEnrollmentDateRequest
from ..repositories import OrderRepository
from services.client_service.models import Client, OrderRequest
from services.company_service.models import Company
import logging
import uuid

router = APIRouter(prefix="/api/order", tags=["order"])
logger = logging.getLogger(__name__)


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
        order.is_date_confirmed = False
    if order.status is None or order.status == 0:
        order.status = OrderStatus.ACTIVE.value
    return order


def _get_current_user_id(current_user: dict) -> str:
    return str(current_user.get("id") or "").strip()


def _ensure_order_participant(
    order: Order,
    current_user: dict,
    *,
    action: str,
) -> str:
    current_user_id = _get_current_user_id(current_user)
    if current_user_id not in {str(order.client_id), str(order.company_id)}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Only order participants can {action}"
        )
    return current_user_id


def _ensure_order_client(
    order: Order,
    current_user: dict,
    *,
    action: str,
) -> str:
    current_user_id = _ensure_order_participant(order, current_user, action=action)
    if (
        current_user.get("user_type") != "Client" or
        current_user_id != str(order.client_id)
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Only the client of this order can {action}"
        )
    return current_user_id


def _build_order_event_payload(order: Order) -> dict:
    return {
        "order_id": order.id,
        "order_request_id": order.order_request_id,
        "client_id": str(order.client_id),
        "company_id": str(order.company_id),
        "enrollment_date": order.enrollment_date.isoformat() if order.enrollment_date else None,
        "is_date_confirmed": bool(order.is_date_confirmed),
        "is_enrolled": bool(order.is_enrolled),
        "status": order.status,
    }


async def _emit_order_event(order: Order, event_type: str) -> None:
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from services.chat.websocket import send_order_event_to_user

        payload = _build_order_event_payload(order)
        await send_order_event_to_user(str(order.client_id), event_type, payload)
        await send_order_event_to_user(str(order.company_id), event_type, payload)
    except Exception as exc:
        logger.warning("Failed to send order websocket event '%s': %s", event_type, exc)


def _publish_event_safe(event_name: str, payload: dict) -> None:
    try:
        from common.rabbitmq_service import publish_event_sync

        publish_event_sync(event_name, payload)
    except Exception as exc:
        logger.warning("Failed to publish %s: %s", event_name, exc)


def _publish_status_changed(order: Order, *, old_status: int | None) -> None:
    _publish_event_safe(
        "OrderStatusChangedEvent",
        {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "status": order.status,
            "old_status": old_status,
        },
    )


def _ensure_active_order_state(order: Order, *, action: str) -> None:
    if order.status == 0:
        # Legacy compatibility: исторически активный заказ мог сохраняться как 0.
        order.status = OrderStatus.ACTIVE.value
    if order.status == OrderStatus.FINISHED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Finished order cannot {action}",
        )
    if order.status == OrderStatus.CANCELED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Canceled order cannot {action}",
        )
    if order.status != OrderStatus.ACTIVE.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Order must be active to {action}",
        )


def _resolve_receiver_client(db: Session, receiver_id: str) -> Client:
    raw_receiver = str(receiver_id).strip()
    if not raw_receiver:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="receiver_id is required",
        )

    if raw_receiver.isdigit():
        client_row = db.query(Client).filter(Client.id == int(raw_receiver)).first()
        if not client_row:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Receiver client not found",
            )
        return client_row

    # guid path (backward compatible with UUID-like and custom guid values)
    client_row = db.query(Client).filter(Client.guid == raw_receiver).first()
    if not client_row:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Receiver client not found",
        )
    return client_row

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

    request_row = (
        db.query(OrderRequest)
        .filter(OrderRequest.id == request.order_request_id)
        .first()
    )
    if not request_row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order request not found",
        )
    if request_row.status != 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order request is not active",
        )

    receiver_client = _resolve_receiver_client(db, request.receiver_id)
    normalized_receiver_id = str(receiver_client.guid)
    if request_row.client_id != receiver_client.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Receiver does not match order request owner",
        )

    repo = OrderRepository(db)

    # Проверка, нет ли уже заказа
    existing = await repo.get_by_request_and_company(request.order_request_id, company_id)
    if existing:
        previous_status = existing.status
        if previous_status == OrderStatus.FINISHED.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Finished order cannot be updated",
            )

        previous_enrollment_date = existing.enrollment_date
        if previous_status == OrderStatus.CANCELED.value:
            existing.status = OrderStatus.ACTIVE.value
            existing.is_date_confirmed = False
            existing.is_enrolled = False
            existing.user_changed_enrollment_date_guid = None

        date_changed = (
            request.enrollment_date is not None and
            request.enrollment_date != previous_enrollment_date
        )

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
        if date_changed or previous_status == OrderStatus.CANCELED.value:
            # После изменения даты/реактивации требуется новое подтверждение клиента.
            existing.is_date_confirmed = False
            existing.is_enrolled = False

        updated = await repo.update(existing)
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to update existing order"
            )

        if previous_status == OrderStatus.CANCELED.value:
            await _emit_order_event(existing, "statusChanged")
            _publish_status_changed(existing, old_status=previous_status)

        return _normalize_order(existing)

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
        is_enrolled=False,
        is_date_confirmed=False,
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
    except Exception as exc:
        logger.warning("Failed to send order creation push notification: %s", exc)

    # Отправка события OrderCreatedEvent в RabbitMQ
    _publish_event_safe(
        "OrderCreatedEvent",
        {
            "order_id": order.id,
            "order_request_id": order.order_request_id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "price": str(order.price) if order.price else None,
            "deadline": str(order.deadline) if order.deadline else None,
        },
    )

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

    _ensure_order_client(order, current_user, action="enroll in the order")

    _ensure_active_order_state(order, action="enroll in the order")
    if order.is_enrolled and order.is_date_confirmed:
        return _normalize_order(order)

    order.is_date_confirmed = True
    order.is_enrolled = True
    result = await repo.update(order)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to enroll"
        )

    await _emit_order_event(order, "enrolled")

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
    except Exception as exc:
        logger.warning("Failed to send enroll push notification: %s", exc)

    # Отправка события UserEnrolledEvent в RabbitMQ
    _publish_event_safe(
        "UserEnrolledEvent",
        {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
            "status": order.status,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": order.is_enrolled,
        },
    )

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

    _ensure_order_client(
        order,
        current_user,
        action="confirm the enrollment date",
    )

    _ensure_active_order_state(order, action="confirm the enrollment date")
    if order.is_enrolled and order.is_date_confirmed:
        return _normalize_order(order)

    order.is_date_confirmed = True
    order.is_enrolled = True
    result = await repo.update(order)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to confirm date"
        )

    await _emit_order_event(order, "confirmed")

    # Отправка события OrderEnrollmentDateConfirmedEvent в RabbitMQ
    _publish_event_safe(
        "OrderEnrollmentDateConfirmedEvent",
        {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
            "status": order.status,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": order.is_enrolled,
        },
    )

    return _normalize_order(order)

@router.put("/changeOrderEnrollmentDate", response_model=OrderResponse)
async def change_enrollment_date(
    request: ChangeEnrollmentDateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение даты записи"""
    repo = OrderRepository(db)
    order = await repo.get(request.order_id)

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found"
        )

    user_id = _ensure_order_participant(
        order,
        current_user,
        action="change the enrollment date",
    )

    _ensure_active_order_state(order, action="change the enrollment date")

    order.enrollment_date = request.enrollment_date
    # После любого изменения предложенной даты требуется новое подтверждение второй стороны.
    order.is_date_confirmed = False
    order.is_enrolled = False
    order.user_changed_enrollment_date_guid = user_id
    result = await repo.update(order)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to change date"
        )

    await _emit_order_event(order, "enrollmentDateChanged")

    # Отправка события OrderEnrollmentDateChangedEvent в RabbitMQ
    _publish_event_safe(
        "OrderEnrollmentDateChangedEvent",
        {
            "order_id": order.id,
            "client_id": str(order.client_id),
            "company_id": str(order.company_id),
            "enrollment_date": str(order.enrollment_date) if order.enrollment_date else None,
            "status": order.status,
            "is_date_confirmed": order.is_date_confirmed,
            "is_enrolled": order.is_enrolled,
            "user_changed_enrollment_date_guid": order.user_changed_enrollment_date_guid,
        },
    )

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

    _ensure_order_participant(order, current_user, action="finish the order")

    if order.status == OrderStatus.FINISHED.value:
        return _normalize_order(order)

    if order.status == OrderStatus.CANCELED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Canceled order cannot be finished"
        )

    if order.status != OrderStatus.ACTIVE.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order must be active to finish",
        )

    if not order.is_enrolled or not order.is_date_confirmed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order can be finished only after enrollment is confirmed"
        )

    old_status = order.status
    order.status = OrderStatus.FINISHED.value
    result = await repo.update(order)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to finish order"
        )

    await _emit_order_event(order, "statusChanged")
    _publish_status_changed(order, old_status=old_status)

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

    _ensure_order_participant(
        order,
        current_user,
        action="cancel the enrollment",
    )

    if order.status == OrderStatus.FINISHED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Finished order cannot be canceled",
        )

    if order.status == OrderStatus.CANCELED.value:
        return _normalize_order(order)

    if order.status != OrderStatus.ACTIVE.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order must be active to cancel enrollment",
        )

    old_status = order.status
    order.is_enrolled = False
    order.is_date_confirmed = False
    order.enrollment_date = None
    order.status = OrderStatus.CANCELED.value
    order.user_changed_enrollment_date_guid = None
    result = await repo.update(order)

    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to cancel enrollment"
        )

    await _emit_order_event(order, "statusChanged")
    _publish_status_changed(order, old_status=old_status)

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
