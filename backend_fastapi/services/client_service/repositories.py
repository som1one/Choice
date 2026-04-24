"""Репозиторий для работы с клиентами"""
from datetime import datetime, timedelta

from sqlalchemy.orm import Session
from .models import Client, OrderRequest
import json

class ClientRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def get(self, guid: str) -> Client | None:
        """Получение клиента по GUID"""
        return self.db.query(Client).filter(Client.guid == guid).first()
    
    async def get_by_email(self, email: str) -> Client | None:
        """Получение клиента по email"""
        return self.db.query(Client).filter(Client.email == email).first()
    
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

    @staticmethod
    def _active_cutoff() -> datetime:
        return datetime.utcnow() - timedelta(hours=24)

    @staticmethod
    def _supports_creation_date() -> bool:
        return hasattr(OrderRequest, "creation_date")
    
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
        return (
            self.db.query(OrderRequest)
            .filter(OrderRequest.client_id == client_id)
            .all()
        )
    
    async def get_by_category(self, category_id: int) -> list[OrderRequest]:
        """Получение заявок по категории"""
        query = self.db.query(OrderRequest).filter(
            OrderRequest.category_id == category_id,
            OrderRequest.status == 0,
        )
        if self._supports_creation_date():
            query = query.filter(
                OrderRequest.creation_date >= self._active_cutoff(),
            )
        return query.all()

    async def expire_stale_active_requests(self) -> int:
        """Переводит просроченные активные заявки в завершенное состояние."""
        if not self._supports_creation_date():
            return 0

        stale_requests = (
            self.db.query(OrderRequest)
            .filter(
                OrderRequest.status == 0,
                OrderRequest.creation_date < self._active_cutoff(),
            )
            .all()
        )

        for request in stale_requests:
            request.status = 2

        if stale_requests:
            self.db.commit()

        return len(stale_requests)
    
    async def update(self, request: OrderRequest) -> bool:
        """Обновление заявки"""
        try:
            self.db.commit()
            self.db.refresh(request)
            return True
        except Exception:
            self.db.rollback()
            return False
