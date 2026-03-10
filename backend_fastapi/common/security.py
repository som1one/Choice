"""JWT аутентификация и безопасность"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic_settings import BaseSettings

class JWTSettings(BaseSettings):
    # Дефолты нужны, чтобы сервисы поднимались "из коробки" на пустом сервере.
    # В ПРОДЕ обязательно переопредели через .env/ENV (JWT_SECRET_KEY, JWT_ISSUER, JWT_AUDIENCE).
    jwt_secret_key: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "choice"
    jwt_audience: str = "choice-users"
    jwt_access_token_expire_minutes: int = 1440
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

jwt_settings = JWTSettings()

# Инициализация bcrypt
# Используем отложенную инициализацию, чтобы избежать проблем с detect_wrap_bug
_pwd_context = None

def _get_pwd_context():
    """Ленивая инициализация CryptContext"""
    global _pwd_context
    if _pwd_context is None:
        try:
            _pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        except Exception as e:
            # Если bcrypt не работает, используем plaintext (только для разработки!)
            import warnings
            warnings.warn(f"Bcrypt initialization failed: {e}. Using plaintext (INSECURE!)")
            _pwd_context = CryptContext(schemes=["plaintext"], deprecated="auto")
    return _pwd_context

# Инициализируем сразу для обратной совместимости
try:
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
except Exception:
    # Если не удалось, используем ленивую инициализацию
    pwd_context = None

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Проверка пароля"""
    ctx = pwd_context if pwd_context is not None else _get_pwd_context()
    return ctx.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Хеширование пароля"""
    # Убеждаемся, что пароль - это строка
    if not isinstance(password, str):
        password = str(password)
    
    # Bcrypt имеет ограничение в 72 байта, обрезаем если необходимо
    # Но обычно пароли короче, так что это защита на случай проблем
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        password = password_bytes[:72].decode('utf-8', errors='ignore')
    
    ctx = pwd_context if pwd_context is not None else _get_pwd_context()
    return ctx.hash(password)

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
