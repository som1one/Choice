"""Роутеры для Chat Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user
from ..models import Message, MessageType, ChatUser
from ..schemas import MessageResponse, ChatResponse, SendMessageRequest, SendImageRequest
from ..repositories import MessageRepository, UserRepository
from ..websocket import send_message_to_user
import uuid as uuid_lib
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
from common.push_notification_service import send_push_notification
from services.authentication.models import User
from services.client_service.models import Client
from services.company_service.models import Company

router = APIRouter(prefix="/api/message", tags=["message"])

def _parse_uuid(value: str | None) -> uuid_lib.UUID | None:
    if not value:
        return None
    try:
        return uuid_lib.UUID(str(value))
    except Exception:
        return None

async def _normalize_user_identifier(db: Session, raw_id: str | None) -> str | None:
    """Нормализует ID пользователя в GUID (UUID-строка).

    Поддерживает:
    - GUID/UUID из JWT/базы
    - legacy numeric id клиентов/компаний
    - существующие ChatUser.guid
    """
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

    chat_user = db.query(ChatUser).filter(ChatUser.guid == candidate).first()
    if chat_user:
        return candidate

    return None

async def _ensure_chat_user(db: Session, guid: str) -> ChatUser | None:
    """Гарантирует, что ChatUser существует для guid."""
    user_repo = UserRepository(db)
    existing = await user_repo.get(guid)
    if existing:
        return existing

    auth_user = None
    parsed_guid = _parse_uuid(guid)
    if parsed_guid:
        auth_user = db.query(User).filter(User.id == parsed_guid).first()

    name = (
        auth_user.user_name
        if auth_user and getattr(auth_user, "user_name", None)
        else "Пользователь"
    )
    email = (
        auth_user.email
        if auth_user and getattr(auth_user, "email", None)
        else f"{guid}@chat.local"
    )

    try:
        created = await user_repo.get_or_create(guid, name, email)
        if auth_user and getattr(auth_user, "icon_uri", None):
            if created.icon_uri != auth_user.icon_uri:
                created.icon_uri = auth_user.icon_uri
                await user_repo.update(created)
        return created
    except Exception:
        return None

async def _get_messages_with_peer_ids(db: Session, current_id: str, peer_ids: list[str]) -> list[Message]:
    cleaned_peer_ids = [
        str(pid).strip() for pid in peer_ids if pid is not None and str(pid).strip()
    ]
    if not cleaned_peer_ids:
        return []

    return db.query(Message).filter(
        ((Message.sender_id == current_id) & (Message.receiver_id.in_(cleaned_peer_ids))) |
        ((Message.receiver_id == current_id) & (Message.sender_id.in_(cleaned_peer_ids)))
    ).order_by(Message.creation_time).all()

def _migrate_peer_id(db: Session, messages: list[Message], legacy_id: str, canonical_id: str) -> bool:
    if not legacy_id or not canonical_id or legacy_id == canonical_id:
        return False

    changed = False
    for msg in messages:
        if msg.sender_id == legacy_id:
            msg.sender_id = canonical_id
            changed = True
        if msg.receiver_id == legacy_id:
            msg.receiver_id = canonical_id
            changed = True

    if changed:
        db.commit()

    return changed

@router.post("/send", response_model=MessageResponse)
async def send_message(
    request: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отправка текстового сообщения"""
    sender_id = str(current_user["id"])
    receiver_id = await _normalize_user_identifier(db, request.receiver_id)
    if not receiver_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receiver not found"
        )

    await _ensure_chat_user(db, sender_id)
    await _ensure_chat_user(db, receiver_id)
    
    repo = MessageRepository(db)
    message = Message(
        sender_id=sender_id,
        receiver_id=receiver_id,
        text=request.text,
        message_type=MessageType.TEXT.value
    )
    
    message = await repo.add(message)
    
    # Отправка через WebSocket
    await send_message_to_user(receiver_id, {
        "type": "send",
        "message": MessageResponse.model_validate(message).model_dump()
    })
    
    # Отправка push-уведомления
    try:
        receiver_uuid = _parse_uuid(receiver_id)
        sender_uuid = _parse_uuid(sender_id)
        receiver = db.query(User).filter(User.id == receiver_uuid).first() if receiver_uuid else None
        if receiver and receiver.device_token:
            # Получаем имя отправителя
            sender = db.query(User).filter(User.id == sender_uuid).first() if sender_uuid else None
            sender_name = sender.user_name if sender else "Пользователь"
            
            send_push_notification(
                device_token=receiver.device_token,
                title="Новое сообщение",
                body=f"{sender_name}: {request.text[:50]}",
                data={
                    "type": "message",
                    "sender_id": str(sender_id),
                    "receiver_id": receiver_id,
                    "message_id": str(message.id)
                }
            )
    except Exception as e:
        # Не прерываем выполнение, если push не отправился
        print(f"Error sending push notification: {e}")
    
    return message

@router.post("/sendImage", response_model=MessageResponse)
async def send_image(
    request: SendImageRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отправка изображения"""
    sender_id = str(current_user["id"])
    receiver_id = await _normalize_user_identifier(db, request.receiver_id)
    if not receiver_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receiver not found"
        )

    await _ensure_chat_user(db, sender_id)
    await _ensure_chat_user(db, receiver_id)
    
    repo = MessageRepository(db)
    message = Message(
        sender_id=sender_id,
        receiver_id=receiver_id,
        text=request.uri,
        message_type=MessageType.IMAGE.value
    )
    
    message = await repo.add(message)
    
    # Отправка через WebSocket
    await send_message_to_user(receiver_id, {
        "type": "send",
        "message": MessageResponse.model_validate(message).model_dump()
    })
    
    # Отправка push-уведомления
    try:
        receiver_uuid = _parse_uuid(receiver_id)
        sender_uuid = _parse_uuid(sender_id)
        receiver = db.query(User).filter(User.id == receiver_uuid).first() if receiver_uuid else None
        if receiver and receiver.device_token:
            # Получаем имя отправителя
            sender = db.query(User).filter(User.id == sender_uuid).first() if sender_uuid else None
            sender_name = sender.user_name if sender else "Пользователь"
            
            send_push_notification(
                device_token=receiver.device_token,
                title="Новое изображение",
                body=f"{sender_name} отправил(а) изображение",
                data={
                    "type": "image",
                    "sender_id": str(sender_id),
                    "receiver_id": receiver_id,
                    "message_id": str(message.id)
                }
            )
    except Exception as e:
        # Не прерываем выполнение, если push не отправился
        print(f"Error sending push notification: {e}")
    
    return message

@router.put("/read")
async def read_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отметка сообщения как прочитанного"""
    current_id = str(current_user["id"])
    repo = MessageRepository(db)
    message = await repo.get(message_id)
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )

    if str(message.receiver_id) != current_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    if not message.is_read:
        message.is_read = True
        await repo.update(message)
        
        # Отправка через WebSocket
        await send_message_to_user(message.sender_id, {
            "type": "read",
            "message": MessageResponse.model_validate(message).model_dump()
        })
    
    return {"message": "Message marked as read"}

@router.get("/getMessages", response_model=list[MessageResponse])
async def get_messages(
    receiver_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение сообщений"""
    sender_id = str(current_user["id"])
    normalized_receiver_id = await _normalize_user_identifier(db, receiver_id)
    if not normalized_receiver_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    await _ensure_chat_user(db, sender_id)
    await _ensure_chat_user(db, normalized_receiver_id)

    peer_ids = [receiver_id, normalized_receiver_id]
    messages = await _get_messages_with_peer_ids(db, sender_id, peer_ids)

    if receiver_id != normalized_receiver_id:
        migrated = _migrate_peer_id(db, messages, receiver_id, normalized_receiver_id)
        if migrated:
            messages = await _get_messages_with_peer_ids(db, sender_id, [normalized_receiver_id])

    return messages

@router.get("/getChat", response_model=ChatResponse)
async def get_chat(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение чата с пользователем"""
    current_id = str(current_user["id"])
    normalized_user_id = await _normalize_user_identifier(db, user_id)
    if not normalized_user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    user = await _ensure_chat_user(db, normalized_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    messages = await _get_messages_with_peer_ids(
        db, current_id, [user_id, normalized_user_id]
    )
    if user_id != normalized_user_id:
        migrated = _migrate_peer_id(db, messages, user_id, normalized_user_id)
        if migrated:
            messages = await _get_messages_with_peer_ids(db, current_id, [normalized_user_id])
    messages = sorted(messages, key=lambda m: m.creation_time)
    
    status_int = 1 if user.status == "Online" else 0
    
    return ChatResponse(
        name=user.name,
        icon_uri=user.icon_uri,
        guid=normalized_user_id,
        is_deleted=user.is_deleted if hasattr(user, 'is_deleted') else False,
        messages=[MessageResponse.model_validate(m) for m in messages],
        status=status_int,
        last_time_online=user.last_time_online if hasattr(user, 'last_time_online') else None
    )

@router.get("/getChats", response_model=list[ChatResponse])
async def get_chats(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение всех чатов пользователя"""
    user_id = str(current_user["id"])
    
    message_repo = MessageRepository(db)
    all_messages = await message_repo.get_all()
    
    # Получаем уникальные ID пользователей, с которыми есть переписка
    user_ids = set()
    for msg in all_messages:
        if msg.sender_id == user_id:
            user_ids.add(msg.receiver_id)
        elif msg.receiver_id == user_id:
            user_ids.add(msg.sender_id)
    
    chats = []
    processed_ids = set()
    
    for raw_uid in user_ids:
        normalized_uid = await _normalize_user_identifier(db, raw_uid)
        if not normalized_uid:
            continue
        if normalized_uid in processed_ids:
            continue
        processed_ids.add(normalized_uid)

        messages = await _get_messages_with_peer_ids(
            db, user_id, [raw_uid, normalized_uid]
        )
        if raw_uid != normalized_uid:
            migrated = _migrate_peer_id(db, messages, raw_uid, normalized_uid)
            if migrated:
                messages = await _get_messages_with_peer_ids(db, user_id, [normalized_uid])

        user = await _ensure_chat_user(db, normalized_uid)
        if not user:
            continue

        messages = sorted(messages, key=lambda m: m.creation_time)
        
        status_int = 1 if user.status == "Online" else 0
        
        chats.append(ChatResponse(
            name=user.name,
            icon_uri=user.icon_uri,
            guid=normalized_uid,
            is_deleted=user.is_deleted if hasattr(user, 'is_deleted') else False,
            messages=[MessageResponse.model_validate(m) for m in messages],
            status=status_int,
            last_time_online=user.last_time_online if hasattr(user, 'last_time_online') else None
        ))

    from datetime import datetime
    chats = sorted(
        chats,
        key=lambda c: (
            c.messages[-1].creation_time
            if c.messages
            else (c.last_time_online or datetime.min)
        ),
        reverse=True,
    )

    return chats
