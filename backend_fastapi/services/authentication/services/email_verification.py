"""Сервис верификации email"""
import random
from typing import Dict

# Хранилище кодов (в продакшене использовать Redis)
email_verification_codes: Dict[str, str] = {}

def send_code(email: str) -> bool:
    """Отправка кода верификации на email"""
    code = str(random.randint(1000, 9999))
    email_verification_codes[email] = code
    
    # TODO: Интегрировать с email сервисом (SendGrid, AWS SES и т.д.)
    print(f"Verification code for {email}: {code}")
    return True

def verify_code(email: str, code: str) -> bool:
    """Проверка кода верификации"""
    stored_code = email_verification_codes.get(email)
    if stored_code and stored_code == code:
        email_verification_codes.pop(email, None)
        return True
    return False
