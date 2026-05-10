"""Pydantic схемы для Review Service."""

from typing import List

from pydantic import BaseModel, Field, model_validator


class ReviewResponse(BaseModel):
    """Ответ с отзывом."""

    id: int
    sender_id: str
    receiver_id: str
    text: str | None
    grade: int = Field(..., ge=1, le=5)
    photo_uris: List[str]

    class Config:
        from_attributes = True


class CreateReviewRequest(BaseModel):
    """Запрос на создание отзыва."""

    guid: str
    criterion_id: int | None = None
    text: str | None = None
    grade: int = Field(..., ge=1, le=5)
    photo_uris: List[str] = []

    @model_validator(mode="before")
    @classmethod
    def validate_payload(cls, data):
        if not isinstance(data, dict):
            return data

        normalized = dict(data)
        criterion_id = normalized.get("criterion_id")
        text = normalized.get("text")
        if criterion_id is None and (text is None or not str(text).strip()):
            raise ValueError("criterion_id or text is required")
        if text is not None:
            normalized["text"] = str(text).strip() or None
        return normalized


class EditReviewRequest(BaseModel):
    """Запрос на редактирование отзыва."""

    id: int
    grade: int = Field(..., ge=1, le=5)
    text: str | None = None
    photo_uris: List[str] = []
