"""Pydantic схемы для Ordering Service"""
from pydantic import BaseModel
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
    enrollment_date: Optional[datetime]
    is_enrolled: bool
    is_date_confirmed: bool
    reviews: List[str]
    status: int
    user_changed_enrollment_date_guid: Optional[str]
    
    class Config:
        from_attributes = True

class CreateOrderRequest(BaseModel):
    """Запрос на создание заказа"""
    receiver_id: str
    order_request_id: int
    price: Optional[int] = None
    prepayment: Optional[int] = None
    deadline: Optional[int] = None
    enrollment_date: Optional[datetime] = None

class ChangeEnrollmentDateRequest(BaseModel):
    """Запрос на изменение даты записи"""
    order_id: int
    enrollment_date: datetime
