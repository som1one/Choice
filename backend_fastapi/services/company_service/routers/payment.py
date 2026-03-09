"""Роутеры для управления платежными данными компании"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from ..models_payment import PaymentData
from ..models import Company
from ..repositories import CompanyRepository
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/company/payment", tags=["payment"])

class PaymentDataRequest(BaseModel):
    """Запрос на создание/обновление платежных данных"""
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    bik: Optional[str] = None
    inn: Optional[str] = None
    kpp: Optional[str] = None
    correspondent_account: Optional[str] = None
    card_number: Optional[str] = None
    cardholder_name: Optional[str] = None
    is_active: bool = True

class PaymentDataResponse(BaseModel):
    """Ответ с платежными данными"""
    id: int
    company_guid: str
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    bik: Optional[str] = None
    inn: Optional[str] = None
    kpp: Optional[str] = None
    correspondent_account: Optional[str] = None
    card_number: Optional[str] = None
    cardholder_name: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True

@router.post("/create", response_model=PaymentDataResponse)
async def create_payment_data(
    request: PaymentDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание платежных данных компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    # Проверяем, есть ли уже платежные данные
    existing = db.query(PaymentData).filter(
        PaymentData.company_guid == company.guid
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment data already exists. Use update endpoint."
        )
    
    payment_data = PaymentData(
        company_guid=company.guid,
        bank_name=request.bank_name,
        account_number=request.account_number,
        bik=request.bik,
        inn=request.inn,
        kpp=request.kpp,
        correspondent_account=request.correspondent_account,
        card_number=request.card_number,
        cardholder_name=request.cardholder_name,
        is_active=request.is_active
    )
    
    db.add(payment_data)
    db.commit()
    db.refresh(payment_data)
    
    return payment_data

@router.get("/get", response_model=PaymentDataResponse)
async def get_payment_data(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение платежных данных компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    payment_data = db.query(PaymentData).filter(
        PaymentData.company_guid == company.guid
    ).first()
    
    if not payment_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment data not found"
        )
    
    return payment_data

@router.put("/update", response_model=PaymentDataResponse)
async def update_payment_data(
    request: PaymentDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Обновление платежных данных компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    payment_data = db.query(PaymentData).filter(
        PaymentData.company_guid == company.guid
    ).first()
    
    if not payment_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment data not found"
        )
    
    # Обновляем поля
    if request.bank_name is not None:
        payment_data.bank_name = request.bank_name
    if request.account_number is not None:
        payment_data.account_number = request.account_number
    if request.bik is not None:
        payment_data.bik = request.bik
    if request.inn is not None:
        payment_data.inn = request.inn
    if request.kpp is not None:
        payment_data.kpp = request.kpp
    if request.correspondent_account is not None:
        payment_data.correspondent_account = request.correspondent_account
    if request.card_number is not None:
        payment_data.card_number = request.card_number
    if request.cardholder_name is not None:
        payment_data.cardholder_name = request.cardholder_name
    if request.is_active is not None:
        payment_data.is_active = request.is_active
    
    db.commit()
    db.refresh(payment_data)
    
    return payment_data

@router.delete("/delete")
async def delete_payment_data(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление платежных данных компании"""
    user_email = current_user["email"]
    repository = CompanyRepository(db)
    company = await repository.get_by_email(user_email)
    
    if not company:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Company not found"
        )
    
    payment_data = db.query(PaymentData).filter(
        PaymentData.company_guid == company.guid
    ).first()
    
    if not payment_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment data not found"
        )
    
    db.delete(payment_data)
    db.commit()
    
    return {"message": "Payment data deleted successfully"}
