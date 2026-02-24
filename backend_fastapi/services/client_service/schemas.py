"""Pydantic схемы для Client Service"""
from pydantic import BaseModel, EmailStr
from typing import List, Optional

class ClientResponse(BaseModel):
    """Ответ с данными клиента"""
    id: int
    guid: str
    name: str
    surname: str
    email: EmailStr
    phone_number: str
    city: str
    street: str
    coordinates: str
    icon_uri: Optional[str]
    average_grade: float
    review_count: int
    
    class Config:
        from_attributes = True

class ChangeUserDataRequest(BaseModel):
    """Запрос на изменение данных клиента"""
    name: str
    surname: str
    email: EmailStr
    phone_number: str
    city: str
    street: str

class OrderRequestResponse(BaseModel):
    """Ответ с заявкой на заказ"""
    id: int
    client_id: int
    category_id: int
    description: str
    search_radius: int
    to_know_price: str
    to_know_deadline: str
    to_know_enrollment_date: str
    photo_uris: Optional[str]
    status: int
    
    class Config:
        from_attributes = True

class SendOrderRequestRequest(BaseModel):
    """Запрос на создание заявки"""
    category_id: int
    description: str
    search_radius: int
    to_know_price: bool = False
    to_know_deadline: bool = False
    to_know_enrollment_date: bool = False
    photo_uris: List[str] = []

class ChangeOrderRequestRequest(BaseModel):
    """Запрос на изменение заявки"""
    id: int
    category_id: int
    description: str
    search_radius: int
    to_know_price: bool = False
    to_know_deadline: bool = False
    to_know_enrollment_date: bool = False
    photo_uris: List[str] = []
