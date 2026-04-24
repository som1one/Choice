"""Pydantic схемы для Authentication Service"""
from pydantic import BaseModel, EmailStr, Field, field_validator, BeforeValidator, TypeAdapter
from typing import Optional, Annotated, Any
from datetime import datetime
from .models import UserType
import uuid
import re

email_adapter = TypeAdapter(EmailStr)

class UserBase(BaseModel):
    email: EmailStr
    user_name: str
    phone_number: Optional[str] = None
    city: Optional[str] = None
    street: Optional[str] = None
    user_type: UserType

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)
    device_token: Optional[str] = None
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone(cls, v):
        # Телефон необязателен, валидация отключена
        return v

class UserResponse(UserBase):
    id: uuid.UUID
    icon_uri: Optional[str] = None
    
    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: str
    password: str
    device_token: Optional[str] = None

    @field_validator('email')
    @classmethod
    def validate_login_email(cls, v: str) -> str:
        email = v.strip().lower()
        try:
            email_adapter.validate_python(email)
            return email
        except Exception:
            if re.fullmatch(r'[^@\s]+@[^@\s]+\.local', email):
                return email
            raise ValueError('Invalid email address')

def normalize_phone(v: Any) -> str:
    """Нормализация номера телефона - убираем все нецифровые символы"""
    if v is None:
        raise ValueError('Номер телефона не может быть пустым')
    # Убираем все кроме цифр
    normalized = re.sub(r'[^\d]', '', str(v))
    # Проверяем, что после нормализации номер имеет от 7 до 15 цифр (стандарт E.164)
    if len(normalized) < 7 or len(normalized) > 15:
        raise ValueError(f'Номер телефона должен содержать от 7 до 15 цифр после нормализации. Получено: {len(normalized)} цифр')
    return normalized

class LoginByPhoneRequest(BaseModel):
    phone: Annotated[str, BeforeValidator(normalize_phone)] = Field(..., description="Номер телефона (международный формат)")

class VerifyCodeRequest(BaseModel):
    phone: Annotated[str, BeforeValidator(normalize_phone)] = Field(..., description="Номер телефона (международный формат)")
    code: str

class RegisterRequest(BaseModel):
    email: EmailStr
    name: str
    password: str = Field(..., min_length=8, max_length=100)
    street: str
    city: str
    phone_number: Optional[str] = None
    device_token: Optional[str] = None
    type: UserType
    
    @field_validator('phone_number', mode='before')
    @classmethod
    def validate_phone(cls, v):
        # Телефон необязателен, но если указан - нормализуем
        if v is None or v == "":
            return None
        # Убираем все кроме цифр
        import re
        normalized = re.sub(r'[^\d]', '', str(v))
        return normalized if normalized else None
    
    @field_validator('type')
    @classmethod
    def validate_type(cls, v):
        if v == UserType.ADMIN:
            raise ValueError('Admin type cannot be used for registration')
        return v

class ResetPasswordRequest(BaseModel):
    email: EmailStr

class VerifyPasswordResetRequest(BaseModel):
    email: EmailStr
    code: str

class SetNewPasswordRequest(BaseModel):
    password: str = Field(..., min_length=8, max_length=100)

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=100)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
