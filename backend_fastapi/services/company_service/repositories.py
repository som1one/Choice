"""Репозиторий для работы с компаниями"""
from sqlalchemy.orm import Session
from .models import Company

class CompanyRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, company: Company) -> int:
        """Добавление компании"""
        self.db.add(company)
        self.db.commit()
        self.db.refresh(company)
        return company.id
    
    async def get(self, guid: str) -> Company | None:
        """Получение компании по GUID"""
        return self.db.query(Company).filter(Company.guid == guid).first()
    
    async def get_all(self) -> list[Company]:
        """Получение всех компаний"""
        return self.db.query(Company).all()
    
    async def get_by_category(self, category_id: int) -> list[Company]:
        """Получение компаний по категории"""
        return self.db.query(Company).filter(
            Company.categories_id.contains([category_id]),
            Company.is_data_filled == True
        ).all()
    
    async def update(self, company: Company) -> bool:
        """Обновление компании"""
        try:
            self.db.commit()
            self.db.refresh(company)
            return True
        except Exception:
            self.db.rollback()
            return False
    
    async def delete(self, guid: str) -> bool:
        """Удаление компании"""
        company = await self.get(guid)
        if company:
            self.db.delete(company)
            self.db.commit()
            return True
        return False
