"""Модели базы данных для Authentication Service"""
from sqlalchemy import Column, String, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
import uuid
import enum
from common.database import Base

class UserType(str, enum.Enum):
    """Тип пользователя"""
    CLIENT = "Client"
    COMPANY = "Company"
    ADMIN = "Admin"

class User(Base):
    """Модель пользователя"""
    __tablename__ = "Users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    user_name = Column(String, nullable=False)
    phone_number = Column(String, unique=True, nullable=True, index=True)
    city = Column(String, nullable=True)
    street = Column(String, nullable=True)
    user_type = Column(SQLEnum(UserType), nullable=False)
    password_hash = Column(String, nullable=False)
    icon_uri = Column(String, nullable=True)
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, type={self.user_type})>"
