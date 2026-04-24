"""Роутеры для Company Service"""
from fastapi import APIRouter, Depends, HTTPException, status, Request, Query
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin, require_client
from common.security import decode_token
from ..models import Company
from ..schemas import (
    CompanyDetailsResponse, CompanyViewModel,
    ChangeDataRequest, ChangeDataAdminRequest, FillCompanyDataRequest
)
from ..repositories import CompanyRepository
from common.address_service import geocode, get_distance
from services.client_service.models import OrderRequest, Client
from services.client_service.schemas import OrderRequestResponse
from services.client_service.repositories import OrderRequestRepository
from math import radians, cos, sin, asin, sqrt
import uuid

router = APIRouter(prefix="/api/company", tags=["company"])


def _normalize_radius_meters(search_radius: int | None) -> int:
    """Нормализует радиус поиска в метры.

    Исторически он приходил то в км (5/10/20/50), то в метрах.
    Для нулевых/битых значений используем безопасный дефолт 20 км,
    чтобы активные заявки не пропадали из выдачи.
    """
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
            import json

            decoded = json.loads(text)
            if isinstance(decoded, list):
                return _normalize_category_ids(decoded)
        except Exception:
            pass

        parts = [part.strip() for part in text.strip("[]").split(",")]
        return [int(part) for part in parts if part.isdigit()]
    return []


async def _expire_stale_requests(db: Session) -> None:
    repo = OrderRequestRepository(db)
    await repo.expire_stale_active_requests()

@router.get("/getAll", response_model=list[CompanyDetailsResponse])
async def get_all_companies(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение всех компаний"""
    repository = CompanyRepository(db)
    companies = await repository.get_all()
    
    return [
        CompanyDetailsResponse(
            id=c.id,
            guid=c.guid,
            title=c.title,
            phone_number=c.phone_number,
            email=c.email,
            icon_uri=c.icon_uri,
            site_url=c.site_url,
            address={"city": c.city, "street": c.street},
            coords=c.coordinates,
            average_grade=c.average_grade,
            social_medias=c.social_medias or [],
            photo_uris=c.photo_uris or [],
            categories_id=c.categories_id or [],
            prepayment_available=c.prepayment_available,
            reviews_count=c.reviews_count,
            description=c.description,
            card_color=getattr(c, 'card_color', '#2196F3') or '#2196F3'
        )
        for c in companies if c.is_data_filled
    ]


@router.get("/getAllAdmin", response_model=list[CompanyDetailsResponse])
async def get_all_companies_admin(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение всех компаний (админ, без фильтра is_data_filled)"""
    repository = CompanyRepository(db)
    companies = await repository.get_all()
    return [
        CompanyDetailsResponse(
            id=c.id,
            guid=c.guid,
            title=c.title,
            phone_number=c.phone_number,
            email=c.email,
            icon_uri=c.icon_uri,
            site_url=c.site_url,
            address={"city": c.city, "street": c.street},
            coords=c.coordinates,
            average_grade=c.average_grade,
            social_medias=c.social_medias or [],
            photo_uris=c.photo_uris or [],
            categories_id=c.categories_id or [],
            prepayment_available=c.prepayment_available,
            reviews_count=c.reviews_count,
            description=c.description,
            card_color=getattr(c, 'card_color', '#2196F3') or '#2196F3'
        )
        for c in companies
    ]

@router.get("/getByCategory", response_model=list[CompanyDetailsResponse])
async def get_companies_by_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение компаний по категории"""
    repository = CompanyRepository(db)
    companies = await repository.get_by_category(category_id)
    
    return [
        CompanyDetailsResponse(
            id=c.id,
            guid=c.guid,
            title=c.title,
            phone_number=c.phone_number,
            email=c.email,
            icon_uri=c.icon_uri,
            site_url=c.site_url,
            address={"city": c.city, "street": c.street},
            coords=c.coordinates,
            average_grade=c.average_grade,
            social_medias=c.social_medias or [],
            photo_uris=c.photo_uris or [],
            categories_id=c.categories_id or [],
            prepayment_available=c.prepayment_available,
            reviews_count=c.reviews_count,
            description=c.description,
            card_color=getattr(c, 'card_color', '#2196F3') or '#2196F3'
        )
        for c in companies
    ]

@router.get("/get", response_model=CompanyDetailsResponse)
async def get_company(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение компании текущего пользователя"""
    user_email = current_user["email"]
    
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.get("/getCompanyAdmin", response_model=CompanyDetailsResponse)
async def get_company_admin(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение компании (админ)"""
    repository = CompanyRepository(db)
    company = await repository.get(guid)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.get("/getCompany", response_model=CompanyViewModel)
async def get_company_for_client(
    guid: str,
    db: Session = Depends(get_db),
    client: dict = Depends(require_client)
):
    """Получение компании для клиента (с расстоянием)"""
    repository = CompanyRepository(db)
    company = await repository.get(guid)
    
    if not company or not company.is_data_filled:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    # Получение адреса клиента из токена
    client_address = client.get("address", "").split(",")
    client_city = client_address[0] if len(client_address) > 0 else ""
    client_street = client_address[1] if len(client_address) > 1 else ""
    
    # Расчет расстояния
    distance = await get_distance(
        (client_city, client_street),
        (company.city, company.street)
    )
    
    return CompanyViewModel(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        distance=distance,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.put("/changeData", response_model=CompanyDetailsResponse)
async def change_data(
    request: ChangeDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение данных компании"""
    if not request.is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"error": ["All fields should not be empty"]})
        )
    
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    company.title = request.title
    company.phone_number = request.phone_number
    company.email = request.email
    company.site_url = request.site_url
    company.city = request.city
    company.street = request.street
    company.social_medias = request.social_medias
    company.photo_uris = request.photo_uris
    company.categories_id = request.categories_id
    company.coordinates = coords
    company.description = request.description
    company.card_color = request.card_color
    company.is_data_filled = True
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update company"
        )
    
    # Отправка события UserDataChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDataChangedEvent", {
            "user_id": str(company.guid),
            "user_type": "Company",
            "email": company.email,
            "title": company.title,
            "phone_number": company.phone_number,
            "city": company.city,
            "street": company.street,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDataChangedEvent: {e}")
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.put("/changeDataAdmin", response_model=CompanyDetailsResponse)
async def change_data_admin(
    request: ChangeDataAdminRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение данных компании (админ)"""
    if not request.is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"error": ["All fields should not be empty"]})
        )
    
    repository = CompanyRepository(db)
    company = await repository.get(request.guid)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    company.title = request.title
    company.phone_number = request.phone_number
    company.email = request.email
    company.site_url = request.site_url
    company.city = request.city
    company.street = request.street
    company.social_medias = request.social_medias
    company.photo_uris = request.photo_uris
    company.categories_id = request.categories_id
    company.coordinates = coords
    company.description = request.description
    company.card_color = request.card_color
    company.is_data_filled = True
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update company"
        )
    
    # Отправка события UserDataChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDataChangedEvent", {
            "user_id": str(company.guid),
            "user_type": "Company",
            "email": company.email,
            "title": company.title,
            "phone_number": company.phone_number,
            "city": company.city,
            "street": company.street,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDataChangedEvent: {e}")
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.put("/changeIconUri", response_model=CompanyDetailsResponse)
async def change_icon_uri(
    uri: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение иконки компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.icon_uri = uri
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # Отправка события UserIconUriChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserIconUriChangedEvent", {
            "user_id": str(company.guid),
            "user_type": "Company",
            "icon_uri": company.icon_uri,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserIconUriChangedEvent: {e}")
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.put("/changeIconUriAdmin", response_model=CompanyDetailsResponse)
async def change_icon_uri_admin(
    guid: str,
    uri: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение иконки компании (админ)"""
    repository = CompanyRepository(db)
    company = await repository.get(guid)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.icon_uri = uri
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # Отправка события UserIconUriChangedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserIconUriChangedEvent", {
            "user_id": str(company.guid),
            "user_type": "Company",
            "icon_uri": company.icon_uri,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserIconUriChangedEvent: {e}")
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.delete("/delete")
async def delete_company(
    id: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление компании (админ)"""
    repository = CompanyRepository(db)
    result = await repository.delete(id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to delete company"
        )
    
    # Отправка события UserDeletedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserDeletedEvent", {
            "user_id": str(company.guid),
            "user_type": "Company",
            "email": company.email,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserDeletedEvent: {e}")
    
    return {"message": "Company deleted successfully"}

@router.put("/fillCompanyData", response_model=CompanyDetailsResponse)
async def fill_company_data(
    request: FillCompanyDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Заполнение данных компании"""
    if not request.is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"error": ["All fields should not be empty"]})
        )
    
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    # Заполнение данных
    company.site_url = request.site_url
    company.social_medias = request.social_medias
    company.photo_uris = request.photo_uris
    company.categories_id = request.categories_id
    company.prepayment_available = request.prepayment_available
    company.description = request.description
    company.is_data_filled = True
    if request.card_color is not None:
        company.card_color = request.card_color
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to fill company data"
        )
    
    # Отправка события CompanyDataFilledEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("CompanyDataFilledEvent", {
            "company_id": str(company.guid),
            "email": company.email,
            "title": company.title,
            "is_data_filled": company.is_data_filled,
            "categories_id": company.categories_id,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish CompanyDataFilledEvent: {e}")
    
    return CompanyDetailsResponse(
        id=company.id,
        guid=company.guid,
        title=company.title,
        phone_number=company.phone_number,
        email=company.email,
        icon_uri=company.icon_uri,
        site_url=company.site_url,
        address={"city": company.city, "street": company.street},
        coords=company.coordinates,
        average_grade=company.average_grade,
        social_medias=company.social_medias or [],
        photo_uris=company.photo_uris or [],
        categories_id=company.categories_id or [],
        prepayment_available=company.prepayment_available,
        reviews_count=company.reviews_count,
        description=company.description,
        card_color=getattr(company, 'card_color', '#2196F3') or '#2196F3'
    )

@router.get("/getOrderRequests", response_model=list[OrderRequestResponse])
async def get_order_requests(
    request: Request,
    categories_id: list[int] | None = Query(None, alias="categoriesId[]"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявок для компании
    
    Фильтрует заявки по:
    - Категориям компании (или переданным categoriesId[])
    - Радиусу поиска заявки (расстояние между компанией и клиентом)
    
    Поддерживает форматы:
    - ?categoriesId[]=1&categoriesId[]=2 (массив категорий)
    - ?categoriesId[0]=1&categoriesId[1]=2 (альтернативный формат)
    """
    # Проверка, что пользователь - компания
    await _expire_stale_requests(db)

    if current_user.get("user_type") != "Company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only companies can get order requests"
        )
    
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        return []
    
    # Обработка различных форматов categoriesId для обратной совместимости
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
    
    # Получаем категории компании
    company_categories = _normalize_category_ids(company.categories_id)
    
    # Если переданы категории в параметрах, используем их (для фильтрации)
    if categories_id:
        # Фильтруем только те категории, которые есть у компании
        company_categories = [cat for cat in company_categories if cat in categories_id]
    
    # Если у компании нет категорий или после фильтрации список пуст, возвращаем пустой список
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
    
    def haversine_distance(lat1, lon1, lat2, lon2):
        """Вычисление расстояния между двумя точками в метрах"""
        R = 6371000  # Радиус Земли в метрах
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        return R * c
    
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

            distance = haversine_distance(company_lat, company_lng, client_lat, client_lng)

            radius_meters = _normalize_radius_meters(req.search_radius)

            # Проверяем, что расстояние меньше или равно радиусу поиска заявки
            if distance <= radius_meters:
                setattr(req, "client_guid", str(client.guid))
                requests_in_radius.append(req)
        except (ValueError, AttributeError):
            setattr(req, "client_guid", str(client.guid))
            requests_in_radius.append(req)
    
    return requests_in_radius

@router.put("/blockCompany/{guid}")
async def block_company(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Блокировка компании (только для админа)"""
    repository = CompanyRepository(db)
    company = await repository.get(guid)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.is_blocked = True
    db.commit()
    
    return {"message": "Company blocked successfully", "guid": guid, "is_blocked": True}

@router.put("/unblockCompany/{guid}")
async def unblock_company(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Разблокировка компании (только для админа)"""
    repository = CompanyRepository(db)
    company = await repository.get(guid)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.is_blocked = False
    db.commit()
    
    return {"message": "Company unblocked successfully", "guid": guid, "is_blocked": False}

@router.delete("/deletePhoto")
async def delete_photo(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление фото/логотипа компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.icon_uri = "defaulturi-png"
    db.commit()
    
    return {"message": "Photo deleted successfully"}

@router.put("/removeFromMap")
async def remove_from_map(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление компании с карты"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.is_on_map = False
    db.commit()
    
    return {"message": "Company removed from map successfully", "is_on_map": False}

@router.put("/addToMap")
async def add_to_map(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Добавление компании на карту"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    company.is_on_map = True
    db.commit()
    
    return {"message": "Company added to map successfully", "is_on_map": True}
