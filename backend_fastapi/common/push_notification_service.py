"""Сервис для отправки push-уведомлений через Firebase Cloud Messaging"""
import os
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

# Опциональный импорт Firebase (если библиотека не установлена, push notifications будут отключены)
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    firebase_admin = None
    credentials = None
    messaging = None
    FIREBASE_AVAILABLE = False
    logger.warning("firebase_admin not installed. Push notifications will be disabled.")

# Инициализация Firebase Admin SDK
_firebase_initialized = False

def initialize_firebase():
    """Инициализация Firebase Admin SDK"""
    global _firebase_initialized
    
    if _firebase_initialized:
        return
    
    if not FIREBASE_AVAILABLE:
        logger.warning("Firebase Admin SDK not available. Push notifications will be disabled.")
        return
    
    try:
        # Путь к JSON файлу с credentials Firebase
        # Можно задать через переменную окружения FIREBASE_CREDENTIALS_PATH
        credentials_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
        
        if credentials_path and os.path.exists(credentials_path):
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin SDK initialized successfully")
        else:
            # Если нет файла, можно использовать Application Default Credentials
            # (для Google Cloud Platform)
            try:
                firebase_admin.initialize_app()
                _firebase_initialized = True
                logger.info("Firebase Admin SDK initialized with default credentials")
            except Exception as e:
                logger.warning(f"Firebase Admin SDK not initialized: {e}. Push notifications will be disabled.")
    except Exception as e:
        logger.error(f"Error initializing Firebase Admin SDK: {e}")

def send_push_notification(
    device_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None
) -> bool:
    """Отправить push-уведомление одному устройству"""
    if not FIREBASE_AVAILABLE or not _firebase_initialized:
        logger.warning("Firebase not available or not initialized, skipping push notification")
        return False
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=device_token,
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent push notification: {response}")
        return True
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        return False

def send_push_notifications(
    device_tokens: List[str],
    title: str,
    body: str,
    data: Optional[dict] = None
) -> int:
    """Отправить push-уведомление нескольким устройствам"""
    if not FIREBASE_AVAILABLE or not _firebase_initialized:
        logger.warning("Firebase not available or not initialized, skipping push notifications")
        return 0
    
    if not device_tokens:
        return 0
    
    success_count = 0
    
    for token in device_tokens:
        if send_push_notification(token, title, body, data):
            success_count += 1
    
    return success_count

def send_multicast_notification(
    device_tokens: List[str],
    title: str,
    body: str,
    data: Optional[dict] = None
):
    """Отправить push-уведомление нескольким устройствам через multicast"""
    if not FIREBASE_AVAILABLE or not _firebase_initialized:
        logger.warning("Firebase not available or not initialized, skipping multicast notification")
        return None
    
    if not device_tokens:
        return None
    
    try:
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=device_tokens,
        )
        
        response = messaging.send_multicast(message)
        logger.info(f"Successfully sent {response.success_count} out of {len(device_tokens)} push notifications")
        return response
    except Exception as e:
        logger.error(f"Error sending multicast notification: {e}")
        return None

# Инициализация при импорте модуля
initialize_firebase()
