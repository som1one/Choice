"""Репозиторий для работы с заказами"""
from sqlalchemy.orm import Session
from .models import Order, OrderStatus

class OrderRepository:
    def __init__(self, db: Session):
        self.db = db
    
    async def add(self, order: Order):
        """Добавление заказа"""
        self.db.add(order)
        self.db.commit()
        self.db.refresh(order)
        return order
    
    async def get(self, order_id: int) -> Order | None:
        """Получение заказа по ID"""
        return self.db.query(Order).filter(Order.id == order_id).first()
    
    async def get_by_request_and_company(self, request_id: int, company_id: str) -> Order | None:
        """Получение заказа по заявке и компании"""
        return self.db.query(Order).filter(
            Order.order_request_id == request_id,
            Order.company_id == company_id
        ).first()
    
    async def get_by_user(self, user_id: str) -> list[Order]:
        """Получение заказов пользователя"""
        return self.db.query(Order).filter(
            (Order.company_id == user_id) | (Order.client_id == user_id)
        ).all()
    
    async def get_by_users(self, guid1: str, guid2: str) -> list[Order]:
        """Получение заказов между двумя пользователями"""
        return self.db.query(Order).filter(
            ((Order.company_id == guid1) & (Order.client_id == guid2)) |
            ((Order.client_id == guid1) & (Order.company_id == guid2))
        ).all()
    
    async def get_active_order(self, client_id: str, company_id: str) -> Order | None:
        """Получение активного заказа"""
        return self.db.query(Order).filter(
            Order.client_id == client_id,
            Order.company_id == company_id,
            Order.status == OrderStatus.ACTIVE.value
        ).first()
    
    async def update(self, order: Order) -> bool:
        """Обновление заказа"""
        try:
            self.db.commit()
            self.db.refresh(order)
            return True
        except Exception:
            self.db.rollback()
            return False
