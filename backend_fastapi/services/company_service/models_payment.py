"""Модели для платежных данных компании"""
from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from common.database import Base

class PaymentData(Base):
    """Модель платежных данных компании"""
    __tablename__ = "PaymentData"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    company_guid = Column(String, ForeignKey("Companies.guid"), nullable=False, index=True)
    bank_name = Column(String, nullable=True)
    account_number = Column(String, nullable=True)
    bik = Column(String, nullable=True)  # БИК банка
    inn = Column(String, nullable=True)  # ИНН компании
    kpp = Column(String, nullable=True)  # КПП компании
    correspondent_account = Column(String, nullable=True)  # Корреспондентский счет
    card_number = Column(String, nullable=True)  # Номер карты
    cardholder_name = Column(String, nullable=True)  # Имя держателя карты
    is_active = Column(Boolean, default=True)  # Активны ли платежные данные
    
    def __repr__(self):
        return f"<PaymentData(id={self.id}, company_guid={self.company_guid})>"
