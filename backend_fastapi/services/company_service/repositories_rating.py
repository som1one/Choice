"""Репозитории для фраз отзывов, услуг и товаров компании."""

from sqlalchemy.orm import Session

from .models_rating import CompanyProduct, CompanyService, RatingCriterion


class RatingCriterionRepository:
    """Репозиторий для работы с фразами отзывов."""

    def __init__(self, db: Session):
        self.db = db

    async def get_all(
        self,
        *,
        grade: int | None = None,
        is_active: bool | None = None,
    ) -> list[RatingCriterion]:
        query = self.db.query(RatingCriterion)
        if grade is not None:
            query = query.filter(RatingCriterion.grade == grade)
        if is_active is not None:
            query = query.filter(RatingCriterion.is_active == is_active)
        return query.order_by(
            RatingCriterion.grade.asc(),
            RatingCriterion.sort_order.asc(),
            RatingCriterion.id.asc(),
        ).all()

    async def get(self, criterion_id: int) -> RatingCriterion | None:
        return self.db.query(RatingCriterion).filter(
            RatingCriterion.id == criterion_id
        ).first()

    async def get_by_text_and_grade(self, text: str, grade: int) -> RatingCriterion | None:
        return self.db.query(RatingCriterion).filter(
            RatingCriterion.text == text,
            RatingCriterion.grade == grade,
        ).first()

    async def add(self, criterion: RatingCriterion) -> RatingCriterion:
        self.db.add(criterion)
        self.db.commit()
        self.db.refresh(criterion)
        return criterion

    async def update(self, criterion: RatingCriterion) -> bool:
        try:
            self.db.commit()
            self.db.refresh(criterion)
            return True
        except Exception:
            self.db.rollback()
            return False

    async def delete(self, criterion_id: int) -> bool:
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
    """Репозиторий для работы с услугами компании."""

    def __init__(self, db: Session):
        self.db = db

    async def get_by_company(self, company_guid: str) -> list[CompanyService]:
        return self.db.query(CompanyService).filter(
            CompanyService.company_guid == company_guid
        ).all()

    async def get(self, service_id: int) -> CompanyService | None:
        return self.db.query(CompanyService).filter(
            CompanyService.id == service_id
        ).first()

    async def add(self, service: CompanyService) -> CompanyService:
        self.db.add(service)
        self.db.commit()
        self.db.refresh(service)
        return service

    async def update(self, service: CompanyService) -> bool:
        try:
            self.db.commit()
            self.db.refresh(service)
            return True
        except Exception:
            self.db.rollback()
            return False

    async def delete(self, service_id: int) -> bool:
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
    """Репозиторий для работы с товарами компании."""

    def __init__(self, db: Session):
        self.db = db

    async def get_by_company(self, company_guid: str) -> list[CompanyProduct]:
        return self.db.query(CompanyProduct).filter(
            CompanyProduct.company_guid == company_guid
        ).all()

    async def get(self, product_id: int) -> CompanyProduct | None:
        return self.db.query(CompanyProduct).filter(
            CompanyProduct.id == product_id
        ).first()

    async def add(self, product: CompanyProduct) -> CompanyProduct:
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return product

    async def update(self, product: CompanyProduct) -> bool:
        try:
            self.db.commit()
            self.db.refresh(product)
            return True
        except Exception:
            self.db.rollback()
            return False

    async def delete(self, product_id: int) -> bool:
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
