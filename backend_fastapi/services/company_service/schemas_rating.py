"""Схемы для фраз отзывов и услуг."""

from pydantic import BaseModel, Field, model_validator


class RatingCriterionRequest(BaseModel):
    """Запрос на создание/обновление фразы отзыва."""

    grade: int = Field(..., ge=1, le=5)
    text: str = Field(..., min_length=1)
    sort_order: int = 0
    is_active: bool = True

    @model_validator(mode="before")
    @classmethod
    def map_legacy_fields(cls, data):
        if not isinstance(data, dict):
            return data

        mapped = dict(data)
        if "text" not in mapped and "name" in mapped:
            mapped["text"] = mapped["name"]
        if "grade" not in mapped and "description" in mapped:
            try:
                mapped["grade"] = int(mapped["description"])
            except (TypeError, ValueError):
                pass
        return mapped


class RatingCriterionResponse(BaseModel):
    """Ответ с фразой отзыва."""

    id: int
    grade: int
    text: str
    sort_order: int
    is_active: bool

    class Config:
        from_attributes = True


class CompanyServiceRequest(BaseModel):
    """Запрос на создание/обновление услуги."""

    name: str


class CompanyServiceResponse(BaseModel):
    """Ответ с услугой."""

    id: int
    company_guid: str
    name: str

    class Config:
        from_attributes = True


class CompanyProductRequest(BaseModel):
    """Запрос на создание/обновление товара."""

    name: str
    description: str | None = None
    price: int | None = None


class CompanyProductResponse(BaseModel):
    """Ответ с товаром."""

    id: int
    company_guid: str
    name: str
    description: str | None
    price: int | None

    class Config:
        from_attributes = True
