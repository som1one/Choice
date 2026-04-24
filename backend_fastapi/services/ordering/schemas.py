"""Pydantic схемы для Ordering Service"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime

class OrderResponse(BaseModel):
    """Ответ с заказом"""
    id: int
    order_request_id: int
    company_id: str
    client_id: str
    price: int
    prepayment: int
    deadline: int
    response_text: Optional[str]
    specialist_name: Optional[str]
    specialist_phone: Optional[str]
    enrollment_date: Optional[datetime]
    is_enrolled: bool = False
    is_date_confirmed: bool = False
    reviews: List[str] = Field(default_factory=list)
    status: int = 1
    user_changed_enrollment_date_guid: Optional[str]

    @field_validator("reviews", mode="before")
    @classmethod
    def _normalize_reviews(cls, value):
        return [] if value is None else value

    @field_validator("is_enrolled", mode="before")
    @classmethod
    def _normalize_is_enrolled(cls, value):
        return False if value is None else value

    @field_validator("is_date_confirmed", mode="before")
    @classmethod
    def _normalize_is_date_confirmed(cls, value):
        return False if value is None else value

    @field_validator("status", mode="before")
    @classmethod
    def _normalize_status(cls, value):
        return 1 if value is None else value
    
    class Config:
        from_attributes = True

class CreateOrderRequest(BaseModel):
    """Запрос на создание заказа"""
    receiver_id: str
    order_request_id: int
    price: Optional[int] = None
    prepayment: Optional[int] = None
    deadline: Optional[int] = None
    response_text: Optional[str] = None
    specialist_name: Optional[str] = None
    specialist_phone: Optional[str] = None
    enrollment_date: Optional[datetime] = None

class ChangeEnrollmentDateRequest(BaseModel):
    """Запрос на изменение даты записи"""
    order_id: int
    enrollment_date: datetime
