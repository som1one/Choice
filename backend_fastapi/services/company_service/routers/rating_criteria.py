"""Роутеры для управления фразами отзывов."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from common.database import get_db
from common.dependencies import require_admin

from ..models_rating import RatingCriterion
from ..repositories_rating import RatingCriterionRepository
from ..schemas_rating import RatingCriterionRequest, RatingCriterionResponse

router = APIRouter(prefix="/api/rating-criteria", tags=["rating-criteria"])


@router.get("/", response_model=list[RatingCriterionResponse])
async def get_all_criteria(
    grade: int | None = None,
    is_active: bool | None = None,
    db: Session = Depends(get_db),
):
    """Получение фраз отзывов с опциональной фильтрацией."""
    repo = RatingCriterionRepository(db)
    return await repo.get_all(grade=grade, is_active=is_active)


@router.post("/", response_model=RatingCriterionResponse)
async def create_criterion(
    request: RatingCriterionRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """Создание новой фразы отзыва (только админ)."""
    repo = RatingCriterionRepository(db)
    normalized_text = request.text.strip()
    existing = await repo.get_by_text_and_grade(normalized_text, request.grade)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Criterion with this text already exists for the selected grade",
        )

    criterion = RatingCriterion(
        grade=request.grade,
        text=normalized_text,
        sort_order=request.sort_order,
        is_active=request.is_active,
    )
    return await repo.add(criterion)


@router.put("/{criterion_id}", response_model=RatingCriterionResponse)
async def update_criterion(
    criterion_id: int,
    request: RatingCriterionRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """Обновление фразы отзыва (только админ)."""
    repo = RatingCriterionRepository(db)
    criterion = await repo.get(criterion_id)
    if not criterion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Criterion not found",
        )

    normalized_text = request.text.strip()
    existing = await repo.get_by_text_and_grade(normalized_text, request.grade)
    if existing and existing.id != criterion.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Criterion with this text already exists for the selected grade",
        )

    criterion.grade = request.grade
    criterion.text = normalized_text
    criterion.sort_order = request.sort_order
    criterion.is_active = request.is_active

    result = await repo.update(criterion)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update criterion",
        )
    return criterion


@router.delete("/{criterion_id}")
async def delete_criterion(
    criterion_id: int,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin),
):
    """Удаление фразы отзыва (только админ)."""
    repo = RatingCriterionRepository(db)
    result = await repo.delete(criterion_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Criterion not found",
        )
    return {"message": "Criterion deleted successfully"}
