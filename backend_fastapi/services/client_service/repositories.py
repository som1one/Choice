"""Репозиторий для работы с клиентами"""
from sqlalchemy.orm import Session
from .models import Client, OrderRequest
import json

class ClientRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def get(self, guid: str) -> Client | None:
        """Получение клиента по GUID"""
        return self.db.query(Client).filter(Client.guid == guid).first()
    
    async def get_all(self) -> list[Client]:
        """Получение всех клиентов"""
        return self.db.query(Client).all()
    
    async def update(self, client: Client) -> bool:
        """Обновление клиента"""
        try:
            self.db.commit()
            self.db.refresh(client)
            return True
        except Exception:
            self.db.rollback()
            return False

class OrderRequestRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, request: OrderRequest):
        """Добавление заявки"""
        self.db.add(request)
        self.db.commit()
        self.db.refresh(request)
        return request
    
    async def get(self, request_id: int) -> OrderRequest | None:
        """Получение заявки по ID"""
        return self.db.query(OrderRequest).filter(OrderRequest.id == request_id).first()
    
    async def get_by_client(self, client_id: int) -> list[OrderRequest]:
        """Получение заявок клиента"""
        return self.db.query(OrderRequest).filter(OrderRequest.client_id == client_id).all()
    
    async def get_by_category(self, category_id: int) -> list[OrderRequest]:
        """Получение заявок по категории"""
        return self.db.query(OrderRequest).filter(
            OrderRequest.category_id == category_id,
            OrderRequest.status == 0  # Active
        ).all()
    
    async def update(self, request: OrderRequest) -> bool:
        """Обновление заявки"""
        try:
            self.db.commit()
            self.db.refresh(request)
            return True
        except Exception:
            self.db.rollback()
            return False
