"""Роутеры для управления услугами компании"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from ..models_rating import CompanyService
from ..schemas_rating import CompanyServiceRequest, CompanyServiceResponse
from ..repositories_rating import CompanyServiceRepository

router = APIRouter(prefix="/api/company-services", tags=["company-services"])

@router.get("/", response_model=list[CompanyServiceResponse])
async def get_company_services(
    company_guid: str | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение услуг компании"""
    repo = CompanyServiceRepository(db)
    
    # Если указан company_guid, возвращаем услуги этой компании
    # Иначе возвращаем услуги текущей компании
    if company_guid is None:
        if current_user.get("user_type") != "Company":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only companies can access their services"
            )
        company_guid = current_user["id"]
    
    services = await repo.get_by_company(company_guid)
    return services

@router.post("/", response_model=CompanyServiceResponse)
async def create_service(
    request: CompanyServiceRequest,
    company_guid: str | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание услуги (компания или админ)"""
    repo = CompanyServiceRepository(db)
    
    # Определяем GUID компании
    if company_guid is None:
        if current_user.get("user_type") == "Company":
            company_guid = current_user["id"]
        elif current_user.get("user_type") == "Admin":
            # Админ должен указать company_guid
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must provide company_guid"
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only companies or admins can create services"
            )
    
    service = CompanyService(
        company_guid=company_guid,
        name=request.name
    )
    
    service = await repo.add(service)
    return service

@router.put("/{service_id}", response_model=CompanyServiceResponse)
async def update_service(
    service_id: int,
    request: CompanyServiceRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Обновление услуги"""
    repo = CompanyServiceRepository(db)
    service = await repo.get(service_id)
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Проверяем права доступа
    if current_user.get("user_type") == "Company" and service.company_guid != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own services"
        )
    
    service.name = request.name
    result = await repo.update(service)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update service"
        )
    
    return service

@router.delete("/{service_id}")
async def delete_service(
    service_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление услуги"""
    repo = CompanyServiceRepository(db)
    service = await repo.get(service_id)
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Проверяем права доступа
    if current_user.get("user_type") == "Company" and service.company_guid != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own services"
        )
    
    result = await repo.delete(service_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to delete service"
        )
    
    return {"message": "Service deleted successfully"}
