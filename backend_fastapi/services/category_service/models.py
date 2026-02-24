"""Модели базы данных для Category Service"""
from sqlalchemy import Column, Integer, String
from common.database import Base

class Category(Base):
    """Модель категории"""
    __tablename__ = "Categories"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String, nullable=False)
    icon_uri = Column(String, nullable=False)
    
    def __repr__(self):
        return f"<Category(id={self.id}, title={self.title})>"
