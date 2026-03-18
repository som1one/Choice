"""WebSocket endpoints для Chat Service"""
from fastapi import WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session
from common.database import get_db
from common.security import decode_token
from .models import ChatUser, UserStatus, Message, MessageType
from .repositories import UserRepository, MessageRepository
from typing import Dict
import json
import uuid as uuid_lib
from services.client_service.models import Client
from services.company_service.models import Company

# Хранилище активных подключений
active_connections: Dict[str, WebSocket] = {}

def _parse_uuid(value: str | None) -> uuid_lib.UUID | None:
    if not value:
        return None
    try:
        return uuid_lib.UUID(str(value))
    except Exception:
        return None

def _normalize_user_identifier(db: Session, raw_id: str | None) -> str | None:
    if raw_id is None:
        return None
    candidate = str(raw_id).strip()
    if not candidate:
        return None
    if _parse_uuid(candidate):
        return candidate
    if candidate.isdigit():
        numeric_id = int(candidate)
        client = db.query(Client).filter(Client.id == numeric_id).first()
        if client:
            return str(client.guid)
        company = db.query(Company).filter(Company.id == numeric_id).first()
        if company:
            return str(company.guid)
    return candidate

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
    user_email = user_data.get("email", "")
    user_name = user_data.get("user_name", "Пользователь")
    active_connections[str(user_id)] = websocket
    
    # Получаем или создаем пользователя чата
    user_repo = UserRepository(db)
    user = await user_repo.get_or_create(str(user_id), user_name, user_email)
    user.status = UserStatus.ONLINE.value
    await user_repo.update(user)
    # Отправить всем об изменении статуса
    await broadcast_user_status(str(user_id), user.status)
    
    try:
        while True:
            data = await websocket.receive_text()
            # Обработка различных типов сообщений
            try:
                message_data = json.loads(data)
                message_type = message_data.get("type")
                
                if message_type == "sendMessage":
                    # Отправка сообщения через WebSocket (альтернатива REST API)
                    await handle_send_message(message_data, user_id, db)
                elif message_type == "readMessage":
                    # Отметка сообщения как прочитанного
                    await handle_read_message(message_data, user_id, db)
                elif message_type == "ping":
                    # Heartbeat для поддержания соединения
                    await websocket.send_json({"type": "pong"})
                else:
                    # Неизвестный тип сообщения
                    await websocket.send_json({
                        "type": "error",
                        "message": f"Unknown message type: {message_type}"
                    })
            except json.JSONDecodeError:
                # Некорректный JSON
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON format"
                })
            except Exception as e:
                # Ошибка обработки сообщения
                await websocket.send_json({
                    "type": "error",
                    "message": f"Error processing message: {str(e)}"
                })
    except WebSocketDisconnect:
        active_connections.pop(str(user_id), None)
        if user:
            user.status = UserStatus.OFFLINE.value
            await user_repo.update(user)
            await broadcast_user_status(str(user_id), user.status)

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
    # receiver_id может быть UUID (строка) или guid
    connection = active_connections.get(str(receiver_id))
    if connection:
        try:
            await connection.send_json(message)
        except Exception:
            pass

async def handle_send_message(message_data: dict, sender_id: str, db: Session):
    """Обработка отправки сообщения через WebSocket"""
    receiver_id = message_data.get("receiver_id")
    text = message_data.get("text")
    
    if not receiver_id or not text:
        return
    
    # Преобразуем ID в строки для единообразия
    sender_id_str = str(sender_id)
    receiver_id_str = _normalize_user_identifier(db, str(receiver_id))
    if not receiver_id_str:
        return
    
    # Создаем сообщение в БД
    repo = MessageRepository(db)
    message = Message(
        sender_id=sender_id_str,
        receiver_id=receiver_id_str,
        text=text,
        message_type=MessageType.TEXT.value
    )
    
    message = await repo.add(message)
    
    # Отправляем сообщение получателю через WebSocket
    await send_message_to_user(receiver_id_str, {
        "type": "send",
        "message": {
            "id": message.id,
            "sender_id": message.sender_id,
            "receiver_id": message.receiver_id,
            "text": message.text,
            "message_type": message.message_type,
            "is_read": message.is_read,
            "creation_time": message.creation_time.isoformat()
        }
    })
    
    # Отправка push-уведомления (если получатель не онлайн)
    if receiver_id_str not in active_connections:
        try:
            import sys
            from pathlib import Path
            sys.path.append(str(Path(__file__).parent.parent.parent.parent))
            from common.push_notification_service import send_push_notification
            from services.authentication.models import User
            
            # Пытаемся найти пользователя по UUID
            import uuid as uuid_lib
            try:
                receiver_uuid = uuid_lib.UUID(receiver_id_str)
                receiver = db.query(User).filter(User.id == receiver_uuid).first()
            except (ValueError, TypeError):
                receiver = None
            
            if receiver and receiver.device_token:
                try:
                    sender_uuid = uuid_lib.UUID(sender_id_str)
                    sender = db.query(User).filter(User.id == sender_uuid).first()
                except (ValueError, TypeError):
                    sender = None
                sender_name = sender.user_name if sender else "Пользователь"
                
                send_push_notification(
                    device_token=receiver.device_token,
                    title="Новое сообщение",
                    body=f"{sender_name}: {text[:50]}",
                    data={
                        "type": "message",
                        "sender_id": sender_id_str,
                        "receiver_id": receiver_id_str,
                        "message_id": str(message.id)
                    }
                )
        except Exception:
            pass

async def handle_read_message(message_data: dict, user_id: str, db: Session):
    """Обработка отметки сообщения как прочитанного"""
    message_id = message_data.get("message_id")
    
    if not message_id:
        return
    
    try:
        message_id_int = int(message_id)
    except (ValueError, TypeError):
        return
    
    repo = MessageRepository(db)
    message = await repo.get(message_id_int)
    
    if not message:
        return
    
    # Проверяем, что пользователь является получателем сообщения
    if str(message.receiver_id) != str(user_id):
        return
    
    # Отмечаем сообщение как прочитанное
    if not message.is_read:
        message.is_read = True
        await repo.update(message)
        
        # Отправляем уведомление отправителю, что сообщение прочитано
        await send_message_to_user(message.sender_id, {
            "type": "read",
            "message": {
                "id": message.id,
                "sender_id": message.sender_id,
                "receiver_id": message.receiver_id,
                "text": message.text,
                "message_type": message.message_type,
                "is_read": True,
                "creation_time": message.creation_time.isoformat()
            }
        })

async def send_order_event_to_user(user_id: str, event_type: str, order_data: dict):
    """Отправка события заказа пользователю через WebSocket"""
    connection = active_connections.get(user_id)
    if connection:
        try:
            await connection.send_json({
                "type": event_type,
                "order": order_data
            })
        except Exception:
            pass
