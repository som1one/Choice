"""Модели базы данных для Ordering Service"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ARRAY, JSON
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base, engine
from datetime import datetime
import enum

# Определяем тип БД для выбора правильного типа колонок
_is_postgresql = engine.url.drivername.startswith("postgresql")

class OrderStatus(enum.Enum):
    """Статус заказа"""
    ACTIVE = 1
    FINISHED = 2
    CANCELED = 3

class Order(Base):
    """Модель заказа"""
    __tablename__ = "Orders"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    order_request_id = Column(Integer, nullable=False)
    company_id = Column(String, nullable=False, index=True)
    client_id = Column(String, nullable=False, index=True)
    price = Column(Integer, nullable=False)
    prepayment = Column(Integer, default=0)
    deadline = Column(Integer, nullable=False)  # в днях
    response_text = Column(String, nullable=True)
    specialist_name = Column(String, nullable=True)
    specialist_phone = Column(String, nullable=True)
    enrollment_date = Column(DateTime, nullable=True)
    is_enrolled = Column(Boolean, default=False)
    is_date_confirmed = Column(Boolean, default=True)
    # Используем ARRAY для PostgreSQL и JSON для SQLite
    reviews = (Column(PG_ARRAY(String), default=[]) if _is_postgresql 
               else Column(JSON, default=lambda: []))
    status = Column(Integer, default=OrderStatus.ACTIVE.value)
    user_changed_enrollment_date_guid = Column(String, nullable=True)
    
    def __repr__(self):
        return f"<Order(id={self.id}, company_id={self.company_id}, client_id={self.client_id})>"
