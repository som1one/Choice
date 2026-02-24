"""Роутеры для аутентификации"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import or_
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent))

from common.database import get_db
from common.security import verify_password, get_password_hash, decode_token
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

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Вход по email и паролю"""
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
    
    # TODO: Отправить событие UserAuthenticatedEvent в RabbitMQ
    # await publish_event("UserAuthenticatedEvent", {
    #     "user_id": str(user.id),
    #     "device_token": request.device_token
    # })
    
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
            detail={"email": ["Email already in use"]}
        )
    
    # Проверка уникальности телефона
    existing_user = db.query(User).filter(User.phone_number == request.phone_number).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"phone_number": ["Phone already in use"]}
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
    
    # TODO: Отправить событие UserCreatedEvent в RabbitMQ
    # await publish_event("UserCreatedEvent", {
    #     "user_id": str(user.id),
    #     "user_name": user.user_name,
    #     "email": user.email,
    #     "city": user.city,
    #     "street": user.street,
    #     "phone_number": user.phone_number,
    #     "user_type": user.user_type.value,
    #     "device_token": request.device_token
    # })
    
    return user

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
            detail={"token": ["Token is invalid"]}
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
            detail={"oldPassword": ["Password did not match"]}
        )
    
    user.password_hash = get_password_hash(request.new_password)
    db.commit()
    
    return {"message": "Password changed successfully"}
