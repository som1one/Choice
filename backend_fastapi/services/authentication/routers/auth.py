"""Роутеры для аутентификации"""
import os
import sys
from pathlib import Path

# Добавить корневую директорию в путь для импортов ДО всех остальных импортов
# Находим корень проекта по наличию папки common
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent

# Проверяем, что это действительно корень (есть папка common)
# Если нет, пробуем найти корень другим способом
if not (project_root / "common").exists():
    # Пробуем подняться еще на один уровень или найти по другому признаку
    for potential_root in [project_root.parent, current_file.parent.parent.parent.parent]:
        if (potential_root / "common").exists():
            project_root = potential_root
            break

# Добавляем в sys.path если еще не добавлен
if (project_root / "common").exists() and str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import or_

from common.database import get_db
from common.dependencies import require_admin
from common.security import verify_password, get_password_hash, decode_token, create_access_token
from ..models import User, UserType
from ..schemas import (
    LoginRequest, LoginByPhoneRequest, VerifyCodeRequest,
    RegisterRequest, ResetPasswordRequest, VerifyPasswordResetRequest,
    SetNewPasswordRequest, ChangePasswordRequest, TokenResponse, UserResponse
)
from ..services.token_service import generate_token, generate_password_reset_token
from ..services.phone_verification import send_code as send_phone_code, verify_code as verify_phone_code
from ..services.email_verification import send_code as send_email_code, verify_code as verify_email_code
import uuid

# Импортируем модуль для инициализации Firebase (инициализация происходит автоматически при импорте)
try:
    import common.push_notification_service
except ImportError:
    # Fallback: если импорт не удался, это не критично - push notifications просто не будут работать
    import logging
    logging.getLogger(__name__).warning("Could not import push_notification_service. Push notifications will be disabled.")

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Вход по email и паролю"""
    # Bootstrap admin login (без регистрации).
    # Включается только если заданы ADMIN_EMAIL и ADMIN_PASSWORD в окружении/.env.
    admin_email = (os.getenv("ADMIN_EMAIL") or "").strip().lower()
    admin_password = os.getenv("ADMIN_PASSWORD") or ""
    if admin_email and admin_password:
        if request.email.strip().lower() == admin_email and request.password == admin_password:
            token = create_access_token(data={
                "id": "00000000-0000-0000-0000-000000000001",
                "email": admin_email,
                "user_type": "Admin",
                "address": None,
            })
            return TokenResponse(access_token=token)

    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid password"
        )
    
    token = generate_token(user)
    
    # Сохраняем device token если указан
    if request.device_token:
        user.device_token = request.device_token
        db.commit()
    
    # Отправка события UserAuthenticatedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserAuthenticatedEvent", {
            "user_id": str(user.id),
            "email": user.email,
            "user_type": user.user_type.value,
            "device_token": request.device_token if hasattr(request, 'device_token') else None
        })
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to publish UserAuthenticatedEvent: {e}")
    
    return TokenResponse(access_token=token)

@router.post("/loginByPhone")
async def login_by_phone(request: LoginByPhoneRequest, db: Session = Depends(get_db)):
    """Вход по телефону (отправка кода)"""
    user = db.query(User).filter(User.phone_number == request.phone).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not send_phone_code(request.phone):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification code"
        )
    
    return {"message": "Verification code sent"}

@router.post("/verify", response_model=TokenResponse)
async def verify_code(request: VerifyCodeRequest, db: Session = Depends(get_db)):
    """Подтверждение кода и получение токена"""
    if not verify_phone_code(request.phone, request.code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid verification code"
        )
    
    user = db.query(User).filter(User.phone_number == request.phone).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    token = generate_token(user)
    return TokenResponse(access_token=token)

@router.post("/register", response_model=UserResponse)
async def register(request: RegisterRequest, db: Session = Depends(get_db)):
    """Регистрация нового пользователя"""
    if request.type == UserType.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You can not register admin account"
        )
    
    # Проверка уникальности email
    existing_user = db.query(User).filter(User.email == request.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"email": ["Email already in use"]})
        )
    
    # Проверка уникальности телефона (только если указан)
    if request.phone_number and request.phone_number.strip():
        existing_user = db.query(User).filter(User.phone_number == request.phone_number).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str({"phone_number": ["Phone already in use"]})
            )
    
    # Создание пользователя
    user = User(
        id=uuid.uuid4(),
        email=request.email,
        user_name=request.name,
        phone_number=request.phone_number,
        city=request.city,
        street=request.street,
        user_type=request.type,
        password_hash=get_password_hash(request.password)
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Сохраняем device token если указан
    if request.device_token:
        user.device_token = request.device_token
        db.commit()
    
    # Создание Client или Company при регистрации
    try:
        import sys
        from pathlib import Path
        sys.path.append(str(Path(__file__).parent.parent.parent.parent))
        from common.address_service import geocode
        
        user_guid = str(user.id)
        user_email = user.email
        user_name = user.user_name
        phone_number = user.phone_number or ""
        city = user.city or ""
        street = user.street or ""
        
        # Получаем координаты адреса
        coordinates = await geocode(city, street)
        
        if request.type == UserType.CLIENT:
            # Создаем клиента
            from services.client_service.models import Client
            
            # Разделяем имя на name и surname
            name_parts = user_name.split(maxsplit=1)
            name = name_parts[0] if name_parts else user_name
            surname = name_parts[1] if len(name_parts) > 1 else ""
            
            # Используем дефолтное значение для phone_number, если он пустой
            # Модель Client требует непустое значение для phone_number
            client_phone = phone_number if phone_number and phone_number.strip() else "0000000000"
            client_city = city if city and city.strip() else "-"
            client_street = street if street and street.strip() else "-"
            
            client = Client(
                guid=user_guid,
                name=name,
                surname=surname,
                email=user_email,
                phone_number=client_phone,
                city=client_city,
                street=client_street,
                coordinates=coordinates
            )
            db.add(client)
            db.commit()
        elif request.type == UserType.COMPANY:
            # Создаем компанию
            from services.company_service.models import Company
            
            # Используем дефолтное значение для phone_number, если он пустой
            # Модель Company требует непустое значение для phone_number
            company_phone = phone_number if phone_number and phone_number.strip() else "0000000000"
            company_city = city if city and city.strip() else "-"
            company_street = street if street and street.strip() else "-"
            
            company = Company(
                guid=user_guid,
                title=user_name,
                phone_number=company_phone,
                email=user_email,
                city=company_city,
                street=company_street,
                coordinates=coordinates
            )
            db.add(company)
            db.commit()
            db.refresh(company)
    except Exception as e:
        # Если не удалось создать Client/Company, логируем ошибку и откатываем транзакцию
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Failed to create Client/Company for user {user.id}: {e}", exc_info=True)
        db.rollback()
        # Удаляем созданного пользователя, так как не удалось создать связанную сущность
        db.delete(user)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create company profile: {str(e)}"
        )
    
    # Отправка события UserCreatedEvent в RabbitMQ
    try:
        from common.rabbitmq_service import publish_event_sync
        publish_event_sync("UserCreatedEvent", {
            "user_id": str(user.id),
            "user_name": user.user_name,
            "email": user.email,
            "city": user.city,
            "street": user.street,
            "phone_number": user.phone_number,
            "user_type": user.user_type.value,
            "device_token": request.device_token if hasattr(request, 'device_token') else None
        })
    except Exception as e:
        logger.warning(f"Failed to publish UserCreatedEvent: {e}")
    
    # Возвращаем UserResponse для правильной сериализации
    try:
        return UserResponse.model_validate(user)
    except Exception as e:
        # Если не удалось сериализовать, возвращаем базовые данные
        logger.error(f"Failed to serialize UserResponse: {e}")
        return UserResponse(
            id=user.id,
            email=user.email,
            user_name=user.user_name,
            phone_number=user.phone_number,
            city=user.city,
            street=user.street,
            user_type=user.user_type,
            icon_uri=user.icon_uri
        )

@router.post("/resetPassword")
async def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Запрос на сброс пароля"""
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not send_email_code(request.email):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification code"
        )
    
    return {"message": "Verification code sent"}

@router.post("/verifyPasswordReset")
async def verify_password_reset(request: VerifyPasswordResetRequest, db: Session = Depends(get_db)):
    """Подтверждение кода для сброса пароля"""
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not verify_email_code(request.email, request.code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid verification code"
        )
    
    reset_token = generate_password_reset_token(user)
    return {"reset_token": reset_token}

@router.put("/setNewPassword")
async def set_new_password(
    request: SetNewPasswordRequest,
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    db: Session = Depends(get_db)
):
    """Установка нового пароля после сброса"""
    token = credentials.credentials
    payload = decode_token(token)
    user_id = payload.get("id")
    
    if not user_id or not payload.get("onlyForPasswordReset"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"token": ["Token is invalid"]})
        )
    
    user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.password_hash = get_password_hash(request.password)
    db.commit()
    
    return {"message": "Password reset successfully"}

@router.put("/changePassword")
async def change_password(
    request: ChangePasswordRequest,
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    db: Session = Depends(get_db)
):
    """Смена пароля"""
    token = credentials.credentials
    payload = decode_token(token)
    current_user_id = payload.get("id")
    
    if not current_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user = db.query(User).filter(User.id == uuid.UUID(current_user_id)).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not verify_password(request.current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str({"oldPassword": ["Password did not match"]})
        )
    
    user.password_hash = get_password_hash(request.new_password)
    db.commit()
    
    return {"message": "Password changed successfully"}

@router.put("/updateDeviceToken")
async def update_device_token(
    device_token: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Обновление device token для push-уведомлений"""
    if not device_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="device_token is required"
        )
    
    user_id = current_user["id"]
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.device_token = device_token
    db.commit()
    
    return {"message": "Device token updated successfully"}

@router.put("/blockUser/{user_id}")
async def block_user(
    user_id: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Блокировка пользователя (только для админа)"""
    from uuid import UUID
    
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    user = db.query(User).filter(User.id == user_uuid).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_blocked = True
    db.commit()
    
    return {"message": "User blocked successfully", "user_id": str(user.id), "is_blocked": True}

@router.put("/unblockUser/{user_id}")
async def unblock_user(
    user_id: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Разблокировка пользователя (только для админа)"""
    from uuid import UUID
    
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    user = db.query(User).filter(User.id == user_uuid).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_blocked = False
    db.commit()
    
    return {"message": "User unblocked successfully", "user_id": str(user.id), "is_blocked": False}