"""WebSocket endpoints для Chat Service"""
from fastapi import WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from common.database import get_db
from common.security import decode_token
from .models import ChatUser, UserStatus
from .repositories import UserRepository
from typing import Dict

# Хранилище активных подключений
active_connections: Dict[str, WebSocket] = {}

async def get_current_user_ws(websocket: WebSocket, token: str) -> dict:
    """Получение пользователя из токена для WebSocket"""
    payload = decode_token(token)
    if not payload or "id" not in payload:
        await websocket.close(code=1008, reason="Invalid token")
        return {}
    return payload

async def websocket_endpoint(websocket: WebSocket, token: str, db: Session):
    """WebSocket endpoint для чата"""
    await websocket.accept()
    
    user_data = await get_current_user_ws(websocket, token)
    if not user_data:
        return
    
    user_id = user_data["id"]
    active_connections[user_id] = websocket
    
    # Обновление статуса пользователя
    user_repo = UserRepository(db)
    user = await user_repo.get(user_id)
    if user:
        user.status = UserStatus.ONLINE.value
        await user_repo.update(user)
        # Отправить всем об изменении статуса
        await broadcast_user_status(user_id, user.status)
    
    try:
        while True:
            data = await websocket.receive_text()
            # Обработка сообщений
            # TODO: Обработка различных типов сообщений
    except WebSocketDisconnect:
        active_connections.pop(user_id, None)
        if user:
            user.status = UserStatus.OFFLINE.value
            await user_repo.update(user)
            await broadcast_user_status(user_id, user.status)

async def broadcast_user_status(user_id: str, status: str):
    """Отправка статуса пользователя всем подключенным"""
    for connection in active_connections.values():
        try:
            await connection.send_json({
                "type": "userStatusChanged",
                "user_id": user_id,
                "status": status
            })
        except Exception:
            pass

async def send_message_to_user(receiver_id: str, message: dict):
    """Отправка сообщения конкретному пользователю"""
    connection = active_connections.get(receiver_id)
    if connection:
        try:
            await connection.send_json(message)
        except Exception:
            pass
