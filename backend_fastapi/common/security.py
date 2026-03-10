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

# Инициализация bcrypt с отложенной загрузкой
# Проблема: bcrypt может падать при инициализации из-за detect_wrap_bug
# Решение: используем ленивую инициализацию
_pwd_context = None

def _get_pwd_context():
    """Ленивая инициализация CryptContext"""
    global _pwd_context
    if _pwd_context is None:
        # Пробуем разные схемы по порядку
        schemes_to_try = [
            ("pbkdf2_sha256", "pbkdf2_sha256"),  # Более надежная альтернатива, не требует bcrypt
            ("bcrypt", "bcrypt"),  # Пробуем bcrypt
            ("plaintext", "plaintext")  # Fallback для разработки
        ]
        
        for scheme_name, scheme in schemes_to_try:
            try:
                ctx = CryptContext(schemes=[scheme], deprecated="auto")
                # Тестируем, что схема работает (это может вызвать ошибку для bcrypt)
                try:
                    test_hash = ctx.hash("test")
                    ctx.verify("test", test_hash)
                    _pwd_context = ctx
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.info(f"Password hashing scheme initialized: {scheme_name}")
                    break
                except (ValueError, AttributeError) as test_error:
                    # Ошибка при тестировании - схема не работает
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f"Scheme {scheme_name} failed test: {test_error}")
                    continue
            except (ValueError, AttributeError, Exception) as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Failed to create {scheme_name} context: {e}")
                continue
        
        # Если ничего не сработало, используем plaintext
        if _pwd_context is None:
            import warnings
            import logging
            logger = logging.getLogger(__name__)
            logger.error("All password hashing schemes failed! Using plaintext (INSECURE - for development only!)")
            warnings.warn("All password hashing schemes failed! Using plaintext (INSECURE!)")
            _pwd_context = CryptContext(schemes=["plaintext"], deprecated="auto")
    return _pwd_context

# Для обратной совместимости создаем переменную, но инициализируем лениво
pwd_context = None  # Будет инициализирован при первом использовании

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Проверка пароля"""
    global pwd_context
    if pwd_context is None:
        pwd_context = _get_pwd_context()
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Хеширование пароля"""
    global pwd_context
    # Убеждаемся, что пароль - это строка
    if not isinstance(password, str):
        password = str(password)
    
    # Bcrypt имеет ограничение в 72 байта, обрезаем если необходимо
    # Но обычно пароли короче, так что это защита на случай проблем
    password_bytes = password.encode('utf-8')
    if len(password_bytes) > 72:
        password = password_bytes[:72].decode('utf-8', errors='ignore')
    
    if pwd_context is None:
        pwd_context = _get_pwd_context()
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
