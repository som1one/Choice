"""Pydantic схемы для Company Service"""
from pydantic import BaseModel, EmailStr
from typing import List, Optional

class Address(BaseModel):
    """Адрес компании"""
    city: str
    street: str

class CompanyBase(BaseModel):
    guid: str
    title: str
    phone_number: str
    email: EmailStr
    city: str
    street: str
    coordinates: str

class CompanyDetailsResponse(BaseModel):
    """Детальная информация о компании"""
    id: int
    guid: str
    title: str
    phone_number: str
    email: EmailStr
    icon_uri: str
    site_url: str
    address: Address
    coords: str
    average_grade: float
    social_medias: List[str]
    photo_uris: List[str]
    categories_id: List[int]
    prepayment_available: bool
    reviews_count: int
    description: str
    
    class Config:
        from_attributes = True

class CompanyViewModel(BaseModel):
    """Модель компании с расстоянием"""
    id: int
    guid: str
    title: str
    phone_number: str
    email: EmailStr
    icon_uri: str
    site_url: str
    address: Address
    coords: str
    distance: int  # Расстояние в метрах
    average_grade: float
    social_medias: List[str]
    photo_uris: List[str]
    categories_id: List[int]
    prepayment_available: bool
    reviews_count: int
    description: str
    
    class Config:
        from_attributes = True

class ChangeDataRequest(BaseModel):
    """Запрос на изменение данных компании"""
    title: str
    phone_number: str
    email: EmailStr
    site_url: str
    city: str
    street: str
    social_medias: List[str]
    photo_uris: List[str]
    categories_id: List[int]
    description: str
    
    @property
    def is_valid(self) -> bool:
        return all([
            self.title,
            self.phone_number,
            self.email,
            self.city,
            self.street
        ])

class ChangeDataAdminRequest(ChangeDataRequest):
    """Запрос на изменение данных компании (админ)"""
    guid: str

class FillCompanyDataRequest(BaseModel):
    """Запрос на заполнение данных компании"""
    site_url: str
    social_medias: List[str]
    photo_uris: List[str]
    categories_id: List[int]
    prepayment_available: bool
    description: str
    
    @property
    def is_valid(self) -> bool:
        return bool(self.site_url or self.social_medias or self.photo_uris)
