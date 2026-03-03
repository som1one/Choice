"""Роутеры для управления товарами компании"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from ..models_rating import CompanyProduct
from ..schemas_rating import CompanyProductRequest, CompanyProductResponse
from ..repositories_rating import CompanyProductRepository

router = APIRouter(prefix="/api/company-products", tags=["company-products"])

@router.get("/", response_model=list[CompanyProductResponse])
async def get_company_products(
    company_guid: str | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение товаров компании"""
    repo = CompanyProductRepository(db)
    
    # Если указан company_guid, возвращаем товары этой компании
    # Иначе возвращаем товары текущей компании
    if company_guid is None:
        if current_user.get("user_type") != "Company":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only companies can access their products"
            )
        company_guid = current_user["id"]
    
    products = await repo.get_by_company(company_guid)
    return products

@router.post("/", response_model=CompanyProductResponse)
async def create_product(
    request: CompanyProductRequest,
    company_guid: str | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание товара (компания или админ)"""
    repo = CompanyProductRepository(db)
    
    # Определяем GUID компании
    if company_guid is None:
        if current_user.get("user_type") == "Company":
            company_guid = current_user["id"]
        elif current_user.get("user_type") == "Admin":
            # Админ должен указать company_guid
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must provide company_guid"
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only companies or admins can create products"
            )
    
    product = CompanyProduct(
        company_guid=company_guid,
        name=request.name,
        description=request.description,
        price=request.price
    )
    
    product = await repo.add(product)
    return product

@router.put("/{product_id}", response_model=CompanyProductResponse)
async def update_product(
    product_id: int,
    request: CompanyProductRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Обновление товара"""
    repo = CompanyProductRepository(db)
    product = await repo.get(product_id)
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Проверяем права доступа
    if current_user.get("user_type") == "Company" and product.company_guid != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own products"
        )
    
    product.name = request.name
    product.description = request.description
    product.price = request.price
    
    result = await repo.update(product)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update product"
        )
    
    return product

@router.delete("/{product_id}")
async def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Удаление товара"""
    repo = CompanyProductRepository(db)
    product = await repo.get(product_id)
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found"
        )
    
    # Проверяем права доступа
    if current_user.get("user_type") == "Company" and product.company_guid != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own products"
        )
    
    result = await repo.delete(product_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to delete product"
        )
    
    return {"message": "Product deleted successfully"}
