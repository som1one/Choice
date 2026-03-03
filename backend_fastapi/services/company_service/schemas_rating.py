"""Схемы для рейтинговых критериев и услуг"""
from pydantic import BaseModel

class RatingCriterionRequest(BaseModel):
    """Запрос на создание/обновление критерия"""
    name: str
    description: str | None = None

class RatingCriterionResponse(BaseModel):
    """Ответ с критерием"""
    id: int
    name: str
    description: str | None

    class Config:
        from_attributes = True

class CompanyServiceRequest(BaseModel):
    """Запрос на создание/обновление услуги"""
    name: str

class CompanyServiceResponse(BaseModel):
    """Ответ с услугой"""
    id: int
    company_guid: str
    name: str

    class Config:
        from_attributes = True

class CompanyProductRequest(BaseModel):
    """Запрос на создание/обновление товара"""
    name: str
    description: str | None = None
    price: int | None = None

class CompanyProductResponse(BaseModel):
    """Ответ с товаром"""
    id: int
    company_guid: str
    name: str
    description: str | None
    price: int | None

    class Config:
        from_attributes = True
