"""Роутеры для Client Service"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from common.address_service import geocode
from ..models import Client, OrderRequest
from ..schemas import (
    ClientResponse, ChangeUserDataRequest,
    OrderRequestResponse, SendOrderRequestRequest, ChangeOrderRequestRequest
)
from ..repositories import ClientRepository, OrderRequestRepository
import json

router = APIRouter(prefix="/api/client", tags=["client"])
logger = logging.getLogger(__name__)


def _normalize_radius_meters(search_radius: int | None) -> int:
    radius = search_radius or 0
    if radius <= 0:
        return 20_000
    return radius * 1000 if radius <= 100 else radius


def _parse_coordinates(raw: str | None) -> tuple[float, float] | None:
    if not raw:
        return None
    try:
        lat, lng = map(float, raw.split(","))
        return lat, lng
    except (ValueError, AttributeError):
        return None


def _normalize_category_ids(raw_categories) -> list[int]:
    if raw_categories is None:
        return []
    if isinstance(raw_categories, list):
        normalized = []
        for item in raw_categories:
            try:
                normalized.append(int(item))
            except (TypeError, ValueError):
                continue
        return normalized
    if isinstance(raw_categories, str):
        text = raw_categories.strip()
        if not text:
            return []
        try:
            decoded = json.loads(text)
            if isinstance(decoded, list):
                return _normalize_category_ids(decoded)
        except Exception:
            pass

        parts = [part.strip() for part in text.strip("[]").split(",")]
        return [int(part) for part in parts if part.isdigit()]
    return []


def _normalize_user_guid(raw: str) -> str:
    compact = (raw or "").replace("-", "")
    if len(compact) == 32:
        return (
            f"{compact[:8]}-{compact[8:12]}-{compact[12:16]}-"
            f"{compact[16:20]}-{compact[20:]}"
        )
    return raw


async def _expire_stale_requests(db: Session) -> None:
    repo = OrderRequestRepository(db)
    await repo.expire_stale_active_requests()


async def _ensure_current_client(
    db: Session,
    current_user: dict,
) -> Client | None:
    """Возвращает профиль клиента, а если его нет — самовосстанавливает из Users."""
    repository = ClientRepository(db)
    user_id = current_user.get("id")
    user_email = current_user.get("email")

    client = None
    if user_id:
        client = await repository.get(user_id)
    if not client and user_email:
        client = await repository.get_by_email(user_email)

    if client or current_user.get("user_type") != "Client":
        return client

    try:
        auth_user = None
        normalized_user_id = (user_id or "").replace("-", "")

        if user_email:
            auth_user = db.execute(
                text(
                    'SELECT id, email, user_name, phone_number, city, street, '
                    'user_type, icon_uri '
                    'FROM "Users" WHERE email = :email LIMIT 1'
                ),
                {"email": user_email},
            ).mappings().first()

        if not auth_user and normalized_user_id:
            auth_user = db.execute(
                text(
                    'SELECT id, email, user_name, phone_number, city, street, '
                    'user_type, icon_uri '
                    'FROM "Users" WHERE REPLACE(CAST(id AS TEXT), \'-\', \'\') = :user_id '
                    'LIMIT 1'
                ),
                {"user_id": normalized_user_id},
            ).mappings().first()

        if not auth_user or str(auth_user["user_type"]).upper() != "CLIENT":
            return None

        name_parts = (auth_user["user_name"] or "").split(maxsplit=1)
        name = name_parts[0] if name_parts else auth_user["email"]
        surname = name_parts[1] if len(name_parts) > 1 else ""

        city = (auth_user["city"] or "").strip() or "-"
        street = (auth_user["street"] or "").strip() or "-"
        phone_number = (auth_user["phone_number"] or "").strip() or "0000000000"
        coordinates = await geocode(city, street)
        if not coordinates or not coordinates.strip():
            coordinates = "55.7558,37.6173"

        client = Client(
            guid=_normalize_user_guid(str(auth_user["id"])),
            name=name,
            surname=surname,
            email=auth_user["email"],
            phone_number=phone_number,
            city=city,
            street=street,
            coordinates=coordinates,
            icon_uri=auth_user["icon_uri"],
        )
        db.add(client)
        db.commit()
        db.refresh(client)
        logger.info("Auto-created missing client profile for user %s", auth_user["id"])
        return client
    except IntegrityError:
        db.rollback()
        client = None
        if user_id:
            client = await repository.get(user_id)
        if not client and user_email:
            client = await repository.get_by_email(user_email)
        if client:
            logger.info(
                "Client profile was created concurrently for user %s",
                user_id or user_email,
            )
            return client
        logger.error(
            "Client profile creation hit IntegrityError but record is still missing "
            "for user %s",
            user_id or user_email,
        )
        return None
    except Exception as exc:
        db.rollback()
        logger.error("Failed to auto-create missing client profile: %s", exc)
        return None

@router.get("/get", response_model=ClientResponse)
async def get_client(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение данных клиента"""
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    return client

@router.get("/getClients", response_model=list[ClientResponse])
async def get_clients(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение всех клиентов (админ)"""
    repository = ClientRepository(db)
    clients = await repository.get_all()
    return clients

@router.get("/getClientAdmin", response_model=ClientResponse)
async def get_client_admin(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение клиента по GUID (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    return client

@router.get("/getClientByGuid", response_model=ClientResponse)
async def get_client_by_guid(
    guid: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение клиента по GUID (для компаний)"""
    # Проверяем, что пользователь - компания
    if current_user.get("user_type") != "Company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only companies can access this endpoint"
        )
    
    repository = ClientRepository(db)
    client = await repository.get(guid)
    # Backward compatibility: иногда на фронте прилетает внутренний numeric id клиента
    if not client and guid.isdigit():
        client = db.query(Client).filter(Client.id == int(guid)).first()
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    return client

@router.put("/changeUserData", response_model=ClientResponse)
async def change_user_data(
    request: ChangeUserDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение данных клиента"""
    repository = ClientRepository(db)
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    client.name = request.name
    client.surname = request.surname
    client.email = request.email
    client.phone_number = request.phone_number
    client.city = request.city
    client.street = request.street
    client.coordinates = coords
    
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update client"
        )
    
    # Отправка события UserDataChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDataChangedEvent", {
            "user_id": str(client.guid),
            "user_type": "Client",
            "email": client.email,
            "name": client.name,
            "surname": client.surname,
            "phone_number": client.phone_number,
            "city": client.city,
            "street": client.street,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDataChangedEvent: {e}")
    
    return client

@router.put("/changeUserDataAdmin", response_model=ClientResponse)
async def change_user_data_admin(
    guid: str,
    request: ChangeUserDataRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение данных клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    client.name = request.name
    client.surname = request.surname
    client.email = request.email
    client.phone_number = request.phone_number
    client.city = request.city
    client.street = request.street
    client.coordinates = coords
    
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update client"
        )
    
    # Отправка события UserDataChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDataChangedEvent", {
            "user_id": str(client.guid),
            "user_type": "Client",
            "email": client.email,
            "name": client.name,
            "surname": client.surname,
            "phone_number": client.phone_number,
            "city": client.city,
            "street": client.street,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDataChangedEvent: {e}")
    
    return client

@router.put("/changeIconUri", response_model=ClientResponse)
async def change_icon_uri(
    uri: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение иконки клиента"""
    repository = ClientRepository(db)
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.icon_uri = uri
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # Отправка события UserIconUriChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserIconUriChangedEvent", {
            "user_id": str(client.guid),
            "user_type": "Client",
            "icon_uri": client.icon_uri,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserIconUriChangedEvent: {e}")
    
    return client

@router.put("/changeIconUriAdmin", response_model=ClientResponse)
async def change_icon_uri_admin(
    guid: str,
    uri: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение иконки клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.icon_uri = uri
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # Отправка события UserIconUriChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserIconUriChangedEvent", {
            "user_id": str(client.guid),
            "user_type": "Client",
            "icon_uri": client.icon_uri,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserIconUriChangedEvent: {e}")
    
    return client

@router.delete("/deleteClientAdmin")
async def delete_client_admin(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    db.delete(client)
    db.commit()
    
    # Отправка события UserDeletedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDeletedEvent", {
            "user_id": str(client.guid),
            "user_type": "Client",
            "email": client.email,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDeletedEvent: {e}")
    
    return {"message": "Client deleted successfully"}

@router.post("/sendOrderRequest", response_model=OrderRequestResponse)
async def send_order_request(
    request: SendOrderRequestRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание заявки на заказ"""
    await _expire_stale_requests(db)
    client_repo = ClientRepository(db)
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    repo = OrderRequestRepository(db)
    order_request = OrderRequest(
        client_id=client.id,
        category_id=request.category_id,
        description=request.description,
        search_radius=request.search_radius,
        to_know_price="true" if request.to_know_price else "false",
        to_know_deadline="true" if request.to_know_deadline else "false",
        to_know_specialist="true" if request.to_know_specialist else "false",
        to_know_enrollment_date="true" if request.to_know_enrollment_date else "false",
        photo_uris=json.dumps(request.photo_uris) if request.photo_uris else None,
        status=0  # Active
    )
    
    order_request = await repo.add(order_request)
    
    # Отправка события OrderRequestSentEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("OrderRequestSentEvent", {
            "order_request_id": order_request.id,
            "client_id": str(client.guid),
            "category_id": order_request.category_id,
            "description": order_request.description,
            "search_radius": order_request.search_radius,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish OrderRequestSentEvent: {e}")
    
    return order_request

@router.get("/getOrderRequests", response_model=list[OrderRequestResponse])
async def get_order_requests(
    request: Request,
    category_id: int | None = None,
    categories_id: list[int] | None = Query(None, alias="categoriesId[]"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявок
    
    Поддерживает форматы:
    - ?category_id=1 (одна категория)
    - ?categories_id=1&categories_id=2 (массив категорий, стандартный FastAPI)
    - ?categoriesId[]=1&categoriesId[]=2 (массив категорий, старый формат)
    - ?categoriesId[0]=1&categoriesId[1]=2 (массив категорий, альтернативный формат)
    """
    from services.company_service.models import Company
    from services.company_service.repositories import CompanyRepository
    from common.address_service import get_distance

    await _expire_stale_requests(db)
    
    repo = OrderRequestRepository(db)
    user_type = current_user.get("user_type")
    user_id = current_user["id"]
    
    # Обработка различных форматов categoriesId для обратной совместимости
    # FastAPI автоматически обрабатывает categoriesId[] через alias, но также поддерживаем categoriesId[0], categoriesId[1]
    if not categories_id:
        query_params = request.query_params
        # Проверяем формат categoriesId[0], categoriesId[1], etc.
        categories_from_query = []
        for key, value in query_params.items():
            if key.startswith("categoriesId[") and key.endswith("]"):
                try:
                    categories_from_query.append(int(value))
                except ValueError:
                    pass
        if categories_from_query:
            categories_id = categories_from_query
    
    # Для клиентов - возвращаем их заявки
    if user_type == "Client":
        client = await _ensure_current_client(db, current_user)
        
        if not client:
            return []
        
        # Если передан массив категорий, фильтруем по ним
        if categories_id:
            # Получаем все заявки клиента и фильтруем по категориям
            all_client_requests = await repo.get_by_client(client.id)
            requests = [
                req for req in all_client_requests
                if req.category_id in categories_id
            ]
        # Если передан одна категория, используем метод репозитория
        elif category_id:
            requests = await repo.get_by_category(category_id)
            # Дополнительно фильтруем по клиенту (на случай, если метод возвращает все заявки категории)
            requests = [req for req in requests if req.client_id == client.id]
        # Если категории не указаны, возвращаем все заявки клиента
        else:
            requests = await repo.get_by_client(client.id)
        
        for req in requests:
            if not hasattr(req, "client_guid"):
                setattr(req, "client_guid", str(client.guid))
        return requests
    
    # Для компаний - фильтруем по категориям компании и радиусу
    if user_type == "Company":
        company_repo = CompanyRepository(db)
        # user_id из токена - это guid (строка)
        company = await company_repo.get(user_id)
        
        if not company:
            return []
        
        # Получаем категории компании
        company_categories = _normalize_category_ids(company.categories_id)
        
        # Если переданы категории в параметрах, используем их (для обратной совместимости)
        if categories_id:
            company_categories = categories_id
        elif category_id:
            company_categories = [category_id]
        
        # Если у компании нет категорий, возвращаем пустой список
        if not company_categories:
            return []
        
        # Получаем все активные заявки
        all_requests = db.query(OrderRequest).filter(
            OrderRequest.status == 0  # Active
        ).all()
        
        # Фильтруем по категориям компании
        filtered_requests = [
            req for req in all_requests
            if req.category_id in company_categories
        ]
        
        # Фильтруем по радиусу (расстояние между компанией и клиентом)
        requests_in_radius = []
        company_coords = company.coordinates
        def _is_legacy_default_coords(value: str | None) -> bool:
            if not value:
                return True
            normalized = value.replace(" ", "")
            return normalized in {"55.7558,37.6173", "55.755800,37.617300"}

        # Автовосстановление координат, если в базе остались старые заглушки
        if _is_legacy_default_coords(company_coords):
            try:
                company.coordinates = await geocode(company.city, company.street)
                db.commit()
                company_coords = company.coordinates
            except Exception:
                pass
        if not company_coords:
            company_coords_parsed = None
        else:
            company_coords_parsed = _parse_coordinates(company_coords)
        
        for req in filtered_requests:
            # Получаем клиента заявки по ID (client_id - это Integer)
            client = db.query(Client).filter(Client.id == req.client_id).first()
            
            if not client:
                continue
            if _is_legacy_default_coords(client.coordinates):
                try:
                    client.coordinates = await geocode(client.city, client.street)
                    db.commit()
                except Exception:
                    pass
            client_coords_parsed = _parse_coordinates(client.coordinates)
            if client_coords_parsed is None:
                setattr(req, "client_guid", str(client.guid))
                requests_in_radius.append(req)
                continue
            
            # Вычисляем расстояние между компанией и клиентом
            try:
                if company_coords_parsed is None:
                    setattr(req, "client_guid", str(client.guid))
                    requests_in_radius.append(req)
                    continue

                company_lat, company_lng = company_coords_parsed
                client_lat, client_lng = client_coords_parsed
                
                # Вычисляем расстояние в метрах (приблизительно, используя формулу гаверсинуса)
                from math import radians, cos, sin, asin, sqrt
                
                def haversine_distance(lat1, lon1, lat2, lon2):
                    """Вычисление расстояния между двумя точками в метрах"""
                    R = 6371000  # Радиус Земли в метрах
                    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
                    dlat = lat2 - lat1
                    dlon = lon2 - lon1
                    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
                    c = 2 * asin(sqrt(a))
                    return R * c
                
                distance = haversine_distance(company_lat, company_lng, client_lat, client_lng)

                # Backward compatibility по единицам:
                # исторически search_radius мог приходить в км (5/10/20/50),
                # при этом distance у нас в метрах.
                radius_meters = _normalize_radius_meters(req.search_radius)

                # Проверяем, что расстояние меньше или равно радиусу поиска заявки
                if distance <= radius_meters:
                    setattr(req, "client_guid", str(client.guid))
                    requests_in_radius.append(req)
            except (ValueError, AttributeError):
                setattr(req, "client_guid", str(client.guid))
                requests_in_radius.append(req)
        
        return requests_in_radius
    
    # Для других типов пользователей возвращаем пустой список
    return []

@router.get("/getClientRequests", response_model=list[OrderRequestResponse])
async def get_client_requests(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявок клиента"""
    await _expire_stale_requests(db)
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    repo = OrderRequestRepository(db)
    requests = await repo.get_by_client(client.id)
    for req in requests:
        if not hasattr(req, "client_guid"):
            setattr(req, "client_guid", str(client.guid))
    
    return requests

@router.get("/getRequest", response_model=OrderRequestResponse)
async def get_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявки по ID"""
    await _expire_stale_requests(db)
    repo = OrderRequestRepository(db)
    request = await repo.get(request_id)
    
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order request not found"
        )
    client = db.query(Client).filter(Client.id == request.client_id).first()
    if client:
        setattr(request, "client_guid", str(client.guid))
    
    return request

@router.put("/changeOrderRequest", response_model=OrderRequestResponse)
async def change_order_request(
    request: ChangeOrderRequestRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение заявки"""
    repo = OrderRequestRepository(db)
    order_request = await repo.get(request.id)
    
    if not order_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order request not found"
        )

    current_client = await _ensure_current_client(db, current_user)
    if not current_client or current_client.id != order_request.client_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the request owner can change the order request"
        )
    
    # Обновление данных
    order_request.category_id = request.category_id
    order_request.description = request.description
    order_request.search_radius = request.search_radius
    order_request.to_know_price = "true" if request.to_know_price else "false"
    order_request.to_know_deadline = "true" if request.to_know_deadline else "false"
    order_request.to_know_specialist = "true" if request.to_know_specialist else "false"
    order_request.to_know_enrollment_date = "true" if request.to_know_enrollment_date else "false"
    order_request.photo_uris = json.dumps(request.photo_uris) if request.photo_uris else None
    
    result = await repo.update(order_request)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update order request"
        )
    
    return order_request

@router.put("/blockClient/{guid}")
async def block_client(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Блокировка клиента (только для админа)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.is_blocked = True
    db.commit()
    
    return {"message": "Client blocked successfully", "guid": guid, "is_blocked": True}

@router.put("/unblockClient/{guid}")
async def unblock_client(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Разблокировка клиента (только для админа)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.is_blocked = False
    db.commit()
    
    return {"message": "Client unblocked successfully", "guid": guid, "is_blocked": False}

@router.delete("/deletePhoto")
async def delete_photo(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление фото клиента"""
    repository = ClientRepository(db)
    client = await _ensure_current_client(db, current_user)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.icon_uri = None
    db.commit()
    
    return {"message": "Photo deleted successfully"}
