"""Pydantic схемы для Company Service"""
from pydantic import BaseModel, EmailStr, field_validator, Field, model_validator, BeforeValidator
from typing import List, Optional, Any, Annotated
import re

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
    card_color: str = "#2196F3"  # Цвет карточки компании
    
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
    card_color: str = "#2196F3"  # Цвет карточки компании
    
    class Config:
        from_attributes = True

def normalize_phone_number(v: Any) -> str:
    """Нормализация номера телефона - убираем все нецифровые символы"""
    if v is None:
        raise ValueError('Номер телефона не может быть пустым')
    # Убираем все кроме цифр
    normalized = re.sub(r'[^\d]', '', str(v))
    # Проверяем, что после нормализации номер имеет от 7 до 15 цифр (стандарт E.164)
    if len(normalized) < 7 or len(normalized) > 15:
        raise ValueError(f'Номер телефона должен содержать от 7 до 15 цифр после нормализации. Получено: {len(normalized)} цифр')
    return normalized

class ChangeDataRequest(BaseModel):
    """Запрос на изменение данных компании"""
    title: str
    phone_number: Annotated[str, BeforeValidator(normalize_phone_number)] = Field(..., description="Номер телефона")
    email: EmailStr
    site_url: str
    city: str
    street: str
    social_medias: List[str]
    photo_uris: List[str]
    categories_id: List[int]
    description: str
    card_color: str = "#2196F3"  # Цвет карточки компании
    
    model_config = {
        "str_strip_whitespace": True,
        "validate_assignment": True,
    }
    
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
    site_url: str = ""  # Может быть пустым
    social_medias: List[str] = []  # Может быть пустым списком
    photo_uris: List[str] = []  # Может быть пустым списком
    categories_id: List[int] = []  # Может быть пустым списком
    prepayment_available: bool = False
    description: str = ""  # Может быть пустым
    card_color: str | None = None  # Цвет карточки компании (опционально)
    
    @property
    def is_valid(self) -> bool:
        return bool(self.site_url.strip() or self.social_medias or self.photo_uris or self.categories_id)
