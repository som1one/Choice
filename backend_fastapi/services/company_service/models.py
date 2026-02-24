"""Модели базы данных для Company Service"""
from sqlalchemy import Column, Integer, String, Boolean, Float, ARRAY
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy.ext.declarative import declarative_base
from common.database import Base
import uuid

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
    social_medias = Column(PG_ARRAY(String), default=[])
    photo_uris = Column(PG_ARRAY(String), default=[])
    categories_id = Column(PG_ARRAY(Integer), default=[])
    prepayment_available = Column(Boolean, default=False)
    is_data_filled = Column(Boolean, default=False)
    
    def __repr__(self):
        return f"<Company(id={self.id}, guid={self.guid}, title={self.title})>"
