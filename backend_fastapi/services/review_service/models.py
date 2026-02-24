"""Модели базы данных для Review Service"""
from sqlalchemy import Column, Integer, String, ARRAY
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base

class Review(Base):
    """Модель отзыва"""
    __tablename__ = "Reviews"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    sender_id = Column(String, nullable=False, index=True)
    receiver_id = Column(String, nullable=False, index=True)
    text = Column(String, nullable=True)
    grade = Column(Integer, nullable=False)  # 1-5
    photo_uris = Column(PG_ARRAY(String), default=[])
    
    def __repr__(self):
        return f"<Review(id={self.id}, sender={self.sender_id}, receiver={self.receiver_id}, grade={self.grade})>"
