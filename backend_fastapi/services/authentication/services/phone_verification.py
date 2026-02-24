"""Сервис верификации телефона через Vonage"""
from vonage import Sms, Client
from pydantic_settings import BaseSettings
import random
from typing import Dict

class VonageSettings(BaseSettings):
    vonage_api_key: str | None = None
    vonage_api_secret: str | None = None
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

settings = VonageSettings()
# Создаем клиент только если ключи заданы
if settings.vonage_api_key and settings.vonage_api_secret:
    client = Client(key=settings.vonage_api_key, secret=settings.vonage_api_secret)
    sms = Sms(client)
else:
    client = None
    sms = None

# Хранилище кодов (в продакшене использовать Redis)
verification_codes: Dict[str, str] = {}

def send_code(phone: str) -> bool:
    """Отправка кода верификации на телефон"""
    code = str(random.randint(1000, 9999))
    verification_codes[phone] = code
    
    if not sms:
        # Если Vonage не настроен, просто сохраняем код (для разработки)
        print(f"DEBUG: Verification code for {phone}: {code}")
        return True
    
    try:
        response = sms.send_message({
            "from": "Choice",
            "to": phone,
            "text": f"Ваш код верификации: {code}"
        })
        return response["messages"][0]["status"] == "0"
    except Exception:
        return False

def verify_code(phone: str, code: str) -> bool:
    """Проверка кода верификации"""
    stored_code = verification_codes.get(phone)
    if stored_code and stored_code == code:
        verification_codes.pop(phone, None)
        return True
    return False
