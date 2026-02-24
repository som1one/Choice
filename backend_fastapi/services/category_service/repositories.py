"""Репозиторий для работы с категориями"""
from sqlalchemy.orm import Session
from sqlalchemy import select
from .models import Category

class CategoryRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, category: Category):
        """Добавление категории"""
        self.db.add(category)
        self.db.commit()
        self.db.refresh(category)
        return category
    
    async def get(self, category_id: int) -> Category | None:
        """Получение категории по ID"""
        return self.db.query(Category).filter(Category.id == category_id).first()
    
    async def get_all(self) -> list[Category]:
        """Получение всех категорий"""
        return self.db.query(Category).all()
    
    async def update(self, category: Category) -> bool:
        """Обновление категории"""
        try:
            self.db.commit()
            self.db.refresh(category)
            return True
        except Exception:
            self.db.rollback()
            return False
    
    async def delete(self, category_id: int):
        """Удаление категории"""
        category = await self.get(category_id)
        if category:
            self.db.delete(category)
            self.db.commit()
