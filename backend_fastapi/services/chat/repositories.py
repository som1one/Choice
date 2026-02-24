"""Репозиторий для работы с чатом"""
from sqlalchemy.orm import Session
from .models import Message, ChatUser

class MessageRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, message: Message):
        """Добавление сообщения"""
        self.db.add(message)
        self.db.commit()
        self.db.refresh(message)
        return message
    
    async def get(self, message_id: int) -> Message | None:
        """Получение сообщения по ID"""
        return self.db.query(Message).filter(Message.id == message_id).first()
    
    async def get_all(self, sender_id: str, receiver_id: str) -> list[Message]:
        """Получение всех сообщений между пользователями"""
        return self.db.query(Message).filter(
            ((Message.sender_id == sender_id) & (Message.receiver_id == receiver_id)) |
            ((Message.sender_id == receiver_id) & (Message.receiver_id == sender_id))
        ).order_by(Message.creation_time).all()
    
    async def update(self, message: Message) -> bool:
        """Обновление сообщения"""
        try:
            self.db.commit()
            self.db.refresh(message)
            return True
        except Exception:
            self.db.rollback()
            return False

class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def get(self, guid: str) -> ChatUser | None:
        """Получение пользователя по GUID"""
        return self.db.query(ChatUser).filter(ChatUser.guid == guid).first()
    
    async def update(self, user: ChatUser) -> bool:
        """Обновление пользователя"""
        try:
            self.db.commit()
            self.db.refresh(user)
            return True
        except Exception:
            self.db.rollback()
            return False
