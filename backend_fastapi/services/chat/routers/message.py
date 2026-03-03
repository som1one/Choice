"""Роутеры для Chat Service"""
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user
from ..models import Message, MessageType, ChatUser
from ..schemas import MessageResponse, ChatResponse, SendMessageRequest, SendImageRequest
from ..repositories import MessageRepository, UserRepository
from ..websocket import send_message_to_user

router = APIRouter(prefix="/api/message", tags=["message"])

@router.post("/send", response_model=MessageResponse)
async def send_message(
    request: SendMessageRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отправка текстового сообщения"""
    sender_id = current_user["id"]
    
    repo = MessageRepository(db)
    message = Message(
        sender_id=sender_id,
        receiver_id=request.receiver_id,
        text=request.text,
        message_type=MessageType.TEXT.value
    )
    
    message = await repo.add(message)
    
    # Отправка через WebSocket
    await send_message_to_user(request.receiver_id, {
        "type": "send",
        "message": MessageResponse.model_validate(message).model_dump()
    })
    
    # TODO: Отправить push-уведомление
    
    return message

@router.post("/sendImage", response_model=MessageResponse)
async def send_image(
    request: SendImageRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отправка изображения"""
    sender_id = current_user["id"]
    
    repo = MessageRepository(db)
    message = Message(
        sender_id=sender_id,
        receiver_id=request.receiver_id,
        text=request.uri,
        message_type=MessageType.IMAGE.value
    )
    
    message = await repo.add(message)
    
    # Отправка через WebSocket
    await send_message_to_user(request.receiver_id, {
        "type": "send",
        "message": MessageResponse.model_validate(message).model_dump()
    })
    
    # TODO: Отправить push-уведомление
    
    return message

@router.put("/read")
async def read_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Отметка сообщения как прочитанного"""
    repo = MessageRepository(db)
    message = await repo.get(message_id)
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
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
    sender_id = current_user["id"]
    repo = MessageRepository(db)
    messages = await repo.get_all(sender_id, receiver_id)
    return messages

@router.get("/getChat", response_model=ChatResponse)
async def get_chat(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение чата с пользователем"""
    current_id = current_user["id"]
    
    user_repo = UserRepository(db)
    user = await user_repo.get(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    message_repo = MessageRepository(db)
    messages = await message_repo.get_all(current_id, user_id)
    messages = sorted(messages, key=lambda m: m.creation_time)
    
    status_int = 1 if user.status == "Online" else 0
    
    return ChatResponse(
        name=user.name,
        icon_uri=user.icon_uri,
        guid=user.guid,
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
    user_id = current_user["id"]
    
    message_repo = MessageRepository(db)
    all_messages = await message_repo.get_all()
    
    # Получаем уникальные ID пользователей, с которыми есть переписка
    user_ids = set()
    for msg in all_messages:
        if msg.sender_id == user_id:
            user_ids.add(msg.receiver_id)
        elif msg.receiver_id == user_id:
            user_ids.add(msg.sender_id)
    
    user_repo = UserRepository(db)
    chats = []
    
    for uid in user_ids:
        user = await user_repo.get(uid)
        if not user:
            continue
        
        messages = await message_repo.get_all(user_id, uid)
        messages = sorted(messages, key=lambda m: m.creation_time)
        
        status_int = 1 if user.status == "Online" else 0
        
        chats.append(ChatResponse(
            name=user.name,
            icon_uri=user.icon_uri,
            guid=user.guid,
            is_deleted=user.is_deleted if hasattr(user, 'is_deleted') else False,
            messages=[MessageResponse.model_validate(m) for m in messages],
            status=status_int,
            last_time_online=user.last_time_online if hasattr(user, 'last_time_online') else None
        ))
    
    return chats
