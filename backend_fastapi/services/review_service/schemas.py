"""Pydantic схемы для Review Service"""
from pydantic import BaseModel, Field
from typing import List

class ReviewResponse(BaseModel):
    """Ответ с отзывом"""
    id: int
    sender_id: str
    receiver_id: str
    text: str | None
    grade: int = Field(..., ge=1, le=5)
    photo_uris: List[str]
    
    class Config:
        from_attributes = True

class CreateReviewRequest(BaseModel):
    """Запрос на создание отзыва"""
    guid: str
    text: str | None = None
    grade: int = Field(..., ge=1, le=5)
    photo_uris: List[str] = []

class EditReviewRequest(BaseModel):
    """Запрос на редактирование отзыва"""
    id: int
    grade: int = Field(..., ge=1, le=5)
    text: str | None = None
    photo_uris: List[str] = []
