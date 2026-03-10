"""Модели базы данных для Chat Service"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ARRAY, JSON
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base, engine
from datetime import datetime
import enum

# Определяем тип БД для выбора правильного типа колонок
_is_postgresql = engine.url.drivername.startswith("postgresql")

class MessageType(enum.Enum):
    """Тип сообщения"""
    TEXT = "Text"
    IMAGE = "Image"
    ORDER = "Order"

class UserStatus(enum.Enum):
    """Статус пользователя"""
    ONLINE = "Online"
    OFFLINE = "Offline"

class Message(Base):
    """Модель сообщения"""
    __tablename__ = "Messages"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    sender_id = Column(String, nullable=False, index=True)
    receiver_id = Column(String, nullable=False, index=True)
    text = Column(String, nullable=False)
    message_type = Column(String, default=MessageType.TEXT.value)
    is_read = Column(Boolean, default=False)
    creation_time = Column(DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f"<Message(id={self.id}, sender={self.sender_id}, receiver={self.receiver_id})>"

class ChatUser(Base):
    """Модель пользователя чата"""
    __tablename__ = "ChatUsers"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    guid = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    icon_uri = Column(String, nullable=True)
    status = Column(String, default=UserStatus.OFFLINE.value)
    # Используем ARRAY для PostgreSQL и JSON для SQLite
    device_tokens = (Column(PG_ARRAY(String), default=[]) if _is_postgresql 
                     else Column(JSON, default=lambda: []))
    is_deleted = Column(Boolean, default=False)
    last_time_online = Column(DateTime, nullable=True)
    
    def __repr__(self):
        return f"<ChatUser(guid={self.guid}, name={self.name}, status={self.status})>"
