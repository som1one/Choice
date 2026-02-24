"""Роутеры для Company Service"""
from fastapi import APIRouter, Depends, HTTPException, status
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
import uuid

router = APIRouter(prefix="/api/company", tags=["company"])

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
            description=c.description
        )
        for c in companies if c.is_data_filled
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
            description=c.description
        )
        for c in companies
    ]

@router.get("/get", response_model=CompanyDetailsResponse)
async def get_company(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение компании текущего пользователя"""
    user_id = current_user["id"]
    
    repository = CompanyRepository(db)
    company = await repository.get(user_id)
    
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
        description=company.description
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
        description=company.description
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
        description=company.description
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
            detail={"error": ["All fields should not be empty"]}
        )
    
    user_id = current_user["id"]
    repository = CompanyRepository(db)
    company = await repository.get(user_id)
    
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
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update company"
        )
    
    # TODO: Отправить событие UserDataChangedEvent в RabbitMQ
    
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
        description=company.description
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
            detail={"error": ["All fields should not be empty"]}
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
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update company"
        )
    
    # TODO: Отправить событие UserDataChangedEvent в RabbitMQ
    
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
        description=company.description
    )

@router.put("/changeIconUri", response_model=CompanyDetailsResponse)
async def change_icon_uri(
    uri: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение иконки компании"""
    user_id = current_user["id"]
    repository = CompanyRepository(db)
    company = await repository.get(user_id)
    
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
    
    # TODO: Отправить событие UserIconUriChangedEvent в RabbitMQ
    
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
        description=company.description
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
    
    # TODO: Отправить событие UserIconUriChangedEvent в RabbitMQ
    
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
        description=company.description
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
    
    # TODO: Отправить событие UserDeletedEvent в RabbitMQ
    
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
            detail={"error": ["All fields should not be empty"]}
        )
    
    user_id = current_user["id"]
    repository = CompanyRepository(db)
    company = await repository.get(user_id)
    
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
    
    result = await repository.update(company)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to fill company data"
        )
    
    # TODO: Отправить событие CompanyDataFilledEvent в RabbitMQ
    
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
        description=company.description
    )
