"""Модели базы данных для Company Service"""
from sqlalchemy import Column, Integer, String, Boolean, Float, ARRAY, JSON
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy.ext.declarative import declarative_base
from common.database import Base, engine
import uuid
import json

# Определяем тип БД для выбора правильного типа колонок
_is_postgresql = engine.url.drivername.startswith("postgresql")

class Company(Base):
    """Модель компании"""
    __tablename__ = "Companies"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    guid = Column(String, unique=True, nullable=False, index=True)
    title = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)
    email = Column(String, nullable=False)
    site_url = Column(String, default="")
    icon_uri = Column(String, default="defaulturi-png")
    city = Column(String, nullable=False)
    street = Column(String, nullable=False)
    coordinates = Column(String, nullable=False)
    description = Column(String, default="")
    average_grade = Column(Float, default=0.0)
    reviews_count = Column(Integer, default=0)
    
    # Используем ARRAY для PostgreSQL и JSON для SQLite
    if _is_postgresql:
        social_medias = Column(PG_ARRAY(String), default=[])
        photo_uris = Column(PG_ARRAY(String), default=[])
        categories_id = Column(PG_ARRAY(Integer), default=[])
    else:
        # Для SQLite используем JSON
        social_medias = Column(JSON, default=lambda: [])
        photo_uris = Column(JSON, default=lambda: [])
        categories_id = Column(JSON, default=lambda: [])
    prepayment_available = Column(Boolean, default=False)
    is_data_filled = Column(Boolean, default=False)
    card_color = Column(String, default="#2196F3")  # Цвет карточки компании (hex)
    is_blocked = Column(Boolean, default=False)  # Блокировка компании
    is_on_map = Column(Boolean, default=True)  # Отображение компании на карте
    
    def __repr__(self):
        return f"<Company(id={self.id}, guid={self.guid}, title={self.title})>"
