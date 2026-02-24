"""JWT аутентификация и безопасность"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic_settings import BaseSettings

class JWTSettings(BaseSettings):
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_issuer: str
    jwt_audience: str
    jwt_access_token_expire_minutes: int = 1440
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

jwt_settings = JWTSettings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Проверка пароля"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Хеширование пароля"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Создание JWT токена"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=jwt_settings.jwt_access_token_expire_minutes)
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.utcnow(),
        "iss": jwt_settings.jwt_issuer,
        "aud": jwt_settings.jwt_audience
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        jwt_settings.jwt_secret_key,
        algorithm=jwt_settings.jwt_algorithm
    )
    return encoded_jwt

def decode_token(token: str) -> dict:
    """Декодирование JWT токена"""
    try:
        payload = jwt.decode(
            token,
            jwt_settings.jwt_secret_key,
            algorithms=[jwt_settings.jwt_algorithm],
            audience=jwt_settings.jwt_audience,
            issuer=jwt_settings.jwt_issuer
        )
        return payload
    except JWTError:
        return {}
