"""Роутеры для управления рейтинговыми критериями"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import require_admin
from ..models_rating import RatingCriterion
from ..schemas_rating import RatingCriterionRequest, RatingCriterionResponse
from ..repositories_rating import RatingCriterionRepository

router = APIRouter(prefix="/api/rating-criteria", tags=["rating-criteria"])

@router.get("/", response_model=list[RatingCriterionResponse])
async def get_all_criteria(
    db: Session = Depends(get_db)
):
    """Получение всех рейтинговых критериев"""
    repo = RatingCriterionRepository(db)
    criteria = await repo.get_all()
    return criteria

@router.post("/", response_model=RatingCriterionResponse)
async def create_criterion(
    request: RatingCriterionRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Создание нового критерия (только админ)"""
    repo = RatingCriterionRepository(db)
    
    # Проверяем, нет ли уже критерия с таким названием
    existing = await repo.get_by_name(request.name)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Criterion with this name already exists"
        )
    
    criterion = RatingCriterion(
        name=request.name,
        description=request.description
    )
    
    criterion = await repo.add(criterion)
    return criterion

@router.put("/{criterion_id}", response_model=RatingCriterionResponse)
async def update_criterion(
    criterion_id: int,
    request: RatingCriterionRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Обновление критерия (только админ)"""
    repo = RatingCriterionRepository(db)
    criterion = await repo.get(criterion_id)
    
    if not criterion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Criterion not found"
        )
    
    # Проверяем уникальность названия (если изменилось)
    if request.name != criterion.name:
        existing = await repo.get_by_name(request.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Criterion with this name already exists"
            )
    
    criterion.name = request.name
    criterion.description = request.description
    
    result = await repo.update(criterion)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update criterion"
        )
    
    return criterion

@router.delete("/{criterion_id}")
async def delete_criterion(
    criterion_id: int,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление критерия (только админ)"""
    repo = RatingCriterionRepository(db)
    result = await repo.delete(criterion_id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Criterion not found"
        )
    
    return {"message": "Criterion deleted successfully"}
