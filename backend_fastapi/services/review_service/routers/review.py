"""Роутеры для Review Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from ..models import Review
from ..schemas import ReviewResponse, CreateReviewRequest, EditReviewRequest
from ..repositories import ReviewRepository

router = APIRouter(prefix="/api/review", tags=["review"])

@router.post("/send", response_model=ReviewResponse)
async def send_review(
    request: CreateReviewRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отправка отзыва"""
    sender_id = current_user["id"]
    
    if sender_id == request.guid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot review yourself"
        )
    
    # TODO: Проверить, что пользователь может оставить отзыв (через Ordering Service)
    # result = await ordering_service.add_review(sender_id, request.guid)
    # if not result:
    #     raise HTTPException(...)
    
    repo = ReviewRepository(db)
    review = Review(
        sender_id=sender_id,
        receiver_id=request.guid,
        text=request.text,
        grade=request.grade,
        photo_uris=request.photo_uris or []
    )
    
    review = await repo.add(review)
    
    # TODO: Отправить событие ReviewLeftEvent в RabbitMQ
    
    return review

@router.put("/edit", response_model=ReviewResponse)
async def edit_review(
    request: EditReviewRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Редактирование отзыва (админ)"""
    repo = ReviewRepository(db)
    review = await repo.get(request.id)
    
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found"
        )
    
    review.grade = request.grade
    review.text = request.text
    review.photo_uris = request.photo_uris or []
    
    result = await repo.update(review)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update review"
        )
    
    return review

@router.get("/get", response_model=list[ReviewResponse])
async def get_reviews(
    guid: str,
    db: Session = Depends(get_db)
):
    """Получение отзывов пользователя"""
    repo = ReviewRepository(db)
    reviews = await repo.get_by_receiver(guid)
    return reviews
