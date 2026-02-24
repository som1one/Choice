"""Pydantic схемы для Authentication Service"""
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from .models import UserType
import uuid

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
        if v and not v.isdigit() or (v and len(v) != 10):
            raise ValueError('Phone number must be 10 digits')
        return v

class UserResponse(UserBase):
    id: uuid.UUID
    icon_uri: Optional[str] = None
    
    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_token: Optional[str] = None

class LoginByPhoneRequest(BaseModel):
    phone: str = Field(..., pattern=r'^\d{10}$')

class VerifyCodeRequest(BaseModel):
    phone: str = Field(..., pattern=r'^\d{10}$')
    code: str

class RegisterRequest(BaseModel):
    email: EmailStr
    name: str
    password: str = Field(..., min_length=8, max_length=100)
    street: str
    city: str
    phone_number: str = Field(..., pattern=r'^\d{10}$')
    device_token: Optional[str] = None
    type: UserType
    
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
