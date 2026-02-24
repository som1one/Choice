"""Роутеры для Category Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import require_admin
from ..models import Category
from ..schemas import CategoryCreate, CategoryUpdate, CategoryResponse
from ..repositories import CategoryRepository

router = APIRouter(prefix="/api/category", tags=["category"])

@router.post("/create", response_model=CategoryResponse)
async def create_category(
    request: CategoryCreate,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Создание категории (только для админов)"""
    repository = CategoryRepository(db)
    
    category = Category(
        title=request.title,
        icon_uri=request.icon_uri
    )
    
    category = await repository.add(category)
    return category

@router.get("/get", response_model=list[CategoryResponse])
async def get_categories(
    db: Session = Depends(get_db)
):
    """Получение всех категорий"""
    repository = CategoryRepository(db)
    categories = await repository.get_all()
    return categories

@router.put("/update")
async def update_category(
    request: CategoryUpdate,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Обновление категории (только для админов)"""
    # Защита системных категорий (ID 1-7)
    if 1 <= request.id <= 7:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update system categories"
        )
    
    repository = CategoryRepository(db)
    category = await repository.get(request.id)
    
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found"
        )
    
    category.title = request.title
    category.icon_uri = request.icon_uri
    
    result = await repository.update(category)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update category"
        )
    
    return request

@router.delete("/delete")
async def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление категории (только для админов)"""
    # Защита системных категорий (ID 1-7)
    if 1 <= category_id <= 7:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete system categories"
        )
    
    repository = CategoryRepository(db)
    await repository.delete(category_id)
    
    return {"message": "Category deleted successfully"}
