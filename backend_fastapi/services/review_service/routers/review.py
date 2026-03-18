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
    
    # Проверка через Ordering Service: можно ли оставить отзыв
    import httpx
    import os
    
    ordering_service_url = os.getenv("ORDERING_SERVICE_URL", "http://localhost:8005")
    ordering_service_url = f"{ordering_service_url}/api/order/addReview"

    user_type = current_user.get("user_type")
    # Клиент оценивает компанию, компания оценивает клиента
    if user_type == "Company":
        client_id = request.guid
        company_id = sender_id
    else:
        client_id = sender_id
        company_id = request.guid
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.put(
                ordering_service_url,
                params={
                    "client_id": client_id,
                    "company_id": company_id,
                    "reviewer_id": sender_id,
                    "reserve": "true",
                }
            )
            if response.status_code == 200:
                result = response.json()
                if not result.get("success", False):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Cannot leave review: no finished order found or review already added"
                    )
    except httpx.RequestError:
        # Если сервис недоступен, пропускаем проверку (для разработки)
        pass
    except HTTPException:
        raise
    
    repo = ReviewRepository(db)
    review = Review(
        sender_id=sender_id,
        receiver_id=request.guid,
        text=request.text,
        grade=request.grade,
        photo_uris=request.photo_uris or []
    )
    
    review = await repo.add(review)
    
    # Отправка события ReviewLeftEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        review_type = "Company" if current_user.get("user_type") == "Client" else "Client"
        publish_event_sync("ReviewLeftEvent", {
            "review_id": review.id,
            "reviewer_id": str(review.sender_id),
            "reviewed_id": str(review.receiver_id),
            "grade": review.grade,
            "review_type": review_type,
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish ReviewLeftEvent: {e}")
    
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

@router.get("/getClientReviews", response_model=list[ReviewResponse])
async def get_client_reviews(
    client_guid: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение отзывов о клиенте от компаний (для компаний)"""
    # Проверяем, что пользователь - компания
    if current_user.get("user_type") != "Company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only companies can access client reviews"
        )
    
    repo = ReviewRepository(db)
    # Получаем все отзывы, где receiver_id = client_guid (отзывы о клиенте)
    reviews = await repo.get_by_receiver(client_guid)
    
    # TODO: Можно добавить фильтрацию, чтобы показывать только отзывы от компаний
    # (если в будущем клиенты тоже смогут оставлять отзывы о компаниях)
    
    return reviews


@router.get("/getAll", response_model=list[ReviewResponse])
async def get_all_reviews_admin(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение всех отзывов (админ)"""
    repo = ReviewRepository(db)
    return await repo.get_all()


@router.delete("/delete")
async def delete_review_admin(
    id: int,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление отзыва (админ)"""
    repo = ReviewRepository(db)
    review = await repo.get(id)
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found"
        )
    ok = await repo.delete(review)
    if not ok:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to delete review"
        )
    return {"message": "Review deleted successfully"}
