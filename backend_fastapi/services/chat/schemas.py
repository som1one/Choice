"""Pydantic схемы для Chat Service"""
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class MessageResponse(BaseModel):
    """Ответ с сообщением"""
    id: int
    sender_id: str
    receiver_id: str
    text: str
    message_type: str
    is_read: bool
    creation_time: datetime
    
    class Config:
        from_attributes = True

class ChatResponse(BaseModel):
    """Ответ с чатом"""
    name: str
    icon_uri: Optional[str]
    guid: str
    is_deleted: bool = False
    messages: List[MessageResponse]
    status: int  # 0 = Offline, 1 = Online
    last_time_online: Optional[datetime] = None

class SendMessageRequest(BaseModel):
    """Запрос на отправку сообщения"""
    text: str
    receiver_id: str

class SendImageRequest(BaseModel):
    """Запрос на отправку изображения"""
    uri: str
    receiver_id: str
