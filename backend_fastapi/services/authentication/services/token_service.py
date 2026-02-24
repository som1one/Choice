"""Сервис для работы с JWT токенами"""
from datetime import timedelta
from common.security import create_access_token
from ..models import User

def generate_token(user: User) -> str:
    """Генерация JWT токена для пользователя"""
    token_data = {
        "id": str(user.id),
        "email": user.email,
        "user_type": user.user_type.value,
        "address": f"{user.city},{user.street}" if user.city and user.street else None
    }
    return create_access_token(data=token_data)

def generate_password_reset_token(user: User) -> str:
    """Генерация токена для сброса пароля"""
    token_data = {
        "id": str(user.id),
        "onlyForPasswordReset": True
    }
    return create_access_token(data=token_data, expires_delta=timedelta(hours=1))
