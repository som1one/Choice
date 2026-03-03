"""Репозитории для рейтинговых критериев и услуг"""
from sqlalchemy.orm import Session
from .models_rating import RatingCriterion, CompanyService, CompanyProduct

class RatingCriterionRepository:
    """Репозиторий для работы с рейтинговыми критериями"""
    def __init__(self, db: Session):
        self.db = db
    
    async def get_all(self) -> list[RatingCriterion]:
        """Получение всех критериев"""
        return self.db.query(RatingCriterion).all()
    
    async def get(self, criterion_id: int) -> RatingCriterion | None:
        """Получение критерия по ID"""
        return self.db.query(RatingCriterion).filter(RatingCriterion.id == criterion_id).first()
    
    async def get_by_name(self, name: str) -> RatingCriterion | None:
        """Получение критерия по названию"""
        return self.db.query(RatingCriterion).filter(RatingCriterion.name == name).first()
    
    async def add(self, criterion: RatingCriterion) -> RatingCriterion:
        """Добавление критерия"""
        self.db.add(criterion)
        self.db.commit()
        self.db.refresh(criterion)
        return criterion
    
    async def update(self, criterion: RatingCriterion) -> bool:
        """Обновление критерия"""
        try:
            self.db.commit()
            self.db.refresh(criterion)
            return True
        except Exception:
            self.db.rollback()
            return False
    
    async def delete(self, criterion_id: int) -> bool:
        """Удаление критерия"""
        criterion = await self.get(criterion_id)
        if not criterion:
            return False
        try:
            self.db.delete(criterion)
            self.db.commit()
            return True
        except Exception:
            self.db.rollback()
            return False

class CompanyServiceRepository:
    """Репозиторий для работы с услугами компании"""
    def __init__(self, db: Session):
        self.db = db
    
    async def get_by_company(self, company_guid: str) -> list[CompanyService]:
        """Получение всех услуг компании"""
        return self.db.query(CompanyService).filter(
            CompanyService.company_guid == company_guid
        ).all()
    
    async def get(self, service_id: int) -> CompanyService | None:
        """Получение услуги по ID"""
        return self.db.query(CompanyService).filter(CompanyService.id == service_id).first()
    
    async def add(self, service: CompanyService) -> CompanyService:
        """Добавление услуги"""
        self.db.add(service)
        self.db.commit()
        self.db.refresh(service)
        return service
    
    async def update(self, service: CompanyService) -> bool:
        """Обновление услуги"""
        try:
            self.db.commit()
            self.db.refresh(service)
            return True
        except Exception:
            self.db.rollback()
            return False
    
    async def delete(self, service_id: int) -> bool:
        """Удаление услуги"""
        service = await self.get(service_id)
        if not service:
            return False
        try:
            self.db.delete(service)
            self.db.commit()
            return True
        except Exception:
            self.db.rollback()
            return False

class CompanyProductRepository:
    """Репозиторий для работы с товарами компании"""
    def __init__(self, db: Session):
        self.db = db
    
    async def get_by_company(self, company_guid: str) -> list[CompanyProduct]:
        """Получение всех товаров компании"""
        return self.db.query(CompanyProduct).filter(
            CompanyProduct.company_guid == company_guid
        ).all()
    
    async def get(self, product_id: int) -> CompanyProduct | None:
        """Получение товара по ID"""
        return self.db.query(CompanyProduct).filter(CompanyProduct.id == product_id).first()
    
    async def add(self, product: CompanyProduct) -> CompanyProduct:
        """Добавление товара"""
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return product
    
    async def update(self, product: CompanyProduct) -> bool:
        """Обновление товара"""
        try:
            self.db.commit()
            self.db.refresh(product)
            return True
        except Exception:
            self.db.rollback()
            return False
    
    async def delete(self, product_id: int) -> bool:
        """Удаление товара"""
        product = await self.get(product_id)
        if not product:
            return False
        try:
            self.db.delete(product)
            self.db.commit()
            return True
        except Exception:
            self.db.rollback()
            return False
