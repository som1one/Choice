"""Модели базы данных для Review Service"""
from sqlalchemy import Column, Integer, String, ARRAY, JSON
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base, engine

# Определяем тип БД для выбора правильного типа колонок
_is_postgresql = engine.url.drivername.startswith("postgresql")

class Review(Base):
    """Модель отзыва"""
    __tablename__ = "Reviews"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    sender_id = Column(String, nullable=False, index=True)
    receiver_id = Column(String, nullable=False, index=True)
    text = Column(String, nullable=True)
    grade = Column(Integer, nullable=False)  # 1-5
    # Используем ARRAY для PostgreSQL и JSON для SQLite
    if _is_postgresql:
        photo_uris = Column(PG_ARRAY(String), default=[])
    else:
        photo_uris = Column(JSON, default=lambda: [])
    
    def __repr__(self):
        return f"<Review(id={self.id}, sender={self.sender_id}, receiver={self.receiver_id}, grade={self.grade})>"
