"""Модели для рейтинговых критериев и услуг компании"""
from sqlalchemy import Column, Integer, String, ForeignKey
from common.database import Base

class RatingCriterion(Base):
    """Модель рейтингового критерия (действие для оценки)"""
    __tablename__ = "rating_criteria"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, nullable=False, unique=True)  # Название критерия (например: "Качество работы")
    description = Column(String, nullable=True)  # Описание (опционально)
    
    def __repr__(self):
        return f"<RatingCriterion(id={self.id}, name={self.name})>"

class CompanyService(Base):
    """Модель услуги компании"""
    __tablename__ = "company_services"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    company_guid = Column(String, ForeignKey("Companies.guid"), nullable=False, index=True)
    name = Column(String, nullable=False)  # Название услуги
    
    def __repr__(self):
        return f"<CompanyService(id={self.id}, company_guid={self.company_guid}, name={self.name})>"

class CompanyProduct(Base):
    """Модель товара компании"""
    __tablename__ = "company_products"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    company_guid = Column(String, ForeignKey("Companies.guid"), nullable=False, index=True)
    name = Column(String, nullable=False)  # Название товара
    description = Column(String, nullable=True)  # Описание товара
    price = Column(Integer, nullable=True)  # Цена (опционально)
    
    def __repr__(self):
        return f"<CompanyProduct(id={self.id}, company_guid={self.company_guid}, name={self.name})>"
