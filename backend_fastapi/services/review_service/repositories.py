"""Репозиторий для работы с отзывами"""
from sqlalchemy.orm import Session
from .models import Review

class ReviewRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, review: Review):
        """Добавление отзыва"""
        self.db.add(review)
        self.db.commit()
        self.db.refresh(review)
        return review
    
    async def get(self, review_id: int) -> Review | None:
        """Получение отзыва по ID"""
        return self.db.query(Review).filter(Review.id == review_id).first()
    
    async def get_by_receiver(self, receiver_id: str) -> list[Review]:
        """Получение отзывов получателя"""
        return self.db.query(Review).filter(Review.receiver_id == receiver_id).all()

    async def get_all(self) -> list[Review]:
        """Получение всех отзывов (админ)"""
        return self.db.query(Review).order_by(Review.id.desc()).all()
    
    async def update(self, review: Review) -> bool:
        """Обновление отзыва"""
        try:
            self.db.commit()
            self.db.refresh(review)
            return True
        except Exception:
            self.db.rollback()
            return False

    async def delete(self, review: Review) -> bool:
        """Удаление отзыва"""
        try:
            self.db.delete(review)
            self.db.commit()
            return True
        except Exception:
            self.db.rollback()
            return False
