"""Модели базы данных для Client Service"""
from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from common.database import Base
import uuid

class Client(Base):
    """Модель клиента"""
    __tablename__ = "Clients"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    guid = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    surname = Column(String, nullable=False)
    email = Column(String, nullable=False, index=True)
    phone_number = Column(String, nullable=False)
    city = Column(String, nullable=False)
    street = Column(String, nullable=False)
    coordinates = Column(String, nullable=False)
    icon_uri = Column(String, nullable=True)
    average_grade = Column(Float, default=0.0)
    review_count = Column(Integer, default=0)
    
    requests = relationship("OrderRequest", back_populates="client")
    
    def __repr__(self):
        return f"<Client(id={self.id}, guid={self.guid}, name={self.name})>"

class OrderRequest(Base):
    """Модель заявки на заказ"""
    __tablename__ = "OrderRequests"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    client_id = Column(Integer, ForeignKey("Clients.id"), nullable=False)
    category_id = Column(Integer, nullable=False)
    description = Column(String, nullable=False)
    search_radius = Column(Integer, default=0)
    to_know_price = Column(String, default="false")
    to_know_deadline = Column(String, default="false")
    to_know_enrollment_date = Column(String, default="false")
    photo_uris = Column(String, nullable=True)  # JSON string
    status = Column(Integer, default=0)  # 0 - Active, 1 - Draft
    
    client = relationship("Client", back_populates="requests")
    
    def __repr__(self):
        return f"<OrderRequest(id={self.id}, client_id={self.client_id})>"
