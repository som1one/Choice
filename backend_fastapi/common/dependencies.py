"""Общие зависимости для FastAPI"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from common.database import get_db
from common.security import decode_token
import uuid

security = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """Получение текущего пользователя из JWT токена"""
    token = credentials.credentials
    payload = decode_token(token)
    
    if not payload or "id" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload.get("id")
    user_type = payload.get("user_type")
    
    return {
        "id": user_id,
        "user_type": user_type,
        "email": payload.get("email"),
        "address": payload.get("address")
    }

def get_current_user_id(current_user: dict = Depends(get_current_user)) -> str:
    """Получение ID текущего пользователя"""
    return current_user["id"]

def require_admin(current_user: dict = Depends(get_current_user)):
    """Проверка, что пользователь - администратор"""
    if current_user.get("user_type") != "Admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

def require_client(current_user: dict = Depends(get_current_user)):
    """Проверка, что пользователь - клиент"""
    if current_user.get("user_type") != "Client":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user
