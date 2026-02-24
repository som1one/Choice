"""Модели базы данных для Chat Service"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ARRAY
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from common.database import Base
from datetime import datetime
import enum

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
    device_tokens = Column(PG_ARRAY(String), default=[])
    
    def __repr__(self):
        return f"<ChatUser(guid={self.guid}, name={self.name}, status={self.status})>"
