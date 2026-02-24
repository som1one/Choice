"""Модели базы данных для Ordering Service"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ARRAY
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base
from datetime import datetime
import enum

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
    enrollment_date = Column(DateTime, nullable=True)
    is_enrolled = Column(Boolean, default=False)
    is_date_confirmed = Column(Boolean, default=True)
    reviews = Column(PG_ARRAY(String), default=[])
    status = Column(Integer, default=OrderStatus.ACTIVE.value)
    user_changed_enrollment_date_guid = Column(String, nullable=True)
    
    def __repr__(self):
        return f"<Order(id={self.id}, company_id={self.company_id}, client_id={self.client_id})>"
