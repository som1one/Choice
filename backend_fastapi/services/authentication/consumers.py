"""Consumers для обработки событий RabbitMQ в Authentication Service"""
import sys
from pathlib import Path
import logging
import uuid
from sqlalchemy.orm import Session

# Добавить корневую директорию в путь для импортов
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

try:
    from common.rabbitmq_service import consume_event
    from services.authentication.models import User
except ImportError:
    from common.rabbitmq_service import consume_event
    from .models import User

logger = logging.getLogger(__name__)

async def handle_user_data_changed(event_data: dict):
    """Обработчик события UserDataChangedEvent"""
    user_id = event_data.get("user_id")
    if not user_id:
        logger.warning("UserDataChangedEvent: missing user_id")
        return
    
    # Получаем сессию БД
    from common.database import SessionLocal
    db = SessionLocal()
    try:
        # Преобразуем user_id из строки в UUID
        try:
            user_uuid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
        except (ValueError, TypeError) as e:
            logger.error(f"UserDataChangedEvent: invalid user_id format {user_id}: {e}")
            return
        
        user = db.query(User).filter(User.id == user_uuid).first()
        if not user:
            logger.warning(f"UserDataChangedEvent: user {user_id} not found")
            return
        
        # Обновляем данные пользователя
        if "email" in event_data:
            user.email = event_data["email"]
        
        # Обработка имени: для Client приходит name и surname, для Company - title
        if "name" in event_data and "surname" in event_data:
            # Для Client: объединяем name и surname
            name = event_data.get("name", "")
            surname = event_data.get("surname", "")
            if name and surname:
                user.user_name = f"{name}_{surname}"
            elif name:
                user.user_name = name
        elif "name" in event_data:
            # Только name (без surname)
            user.user_name = event_data.get("name", user.user_name)
        elif "title" in event_data:
            # Для Company: используем title как user_name
            user.user_name = event_data.get("title", user.user_name)
        
        if "phone_number" in event_data:
            user.phone_number = event_data["phone_number"]
        if "city" in event_data:
            user.city = event_data["city"]
        if "street" in event_data:
            user.street = event_data["street"]
        
        db.commit()
        logger.info(f"UserDataChangedEvent: updated user {user_id}")
    except Exception as e:
        db.rollback()
        logger.error(f"Error handling UserDataChangedEvent: {e}")
    finally:
        db.close()

async def handle_user_icon_uri_changed(event_data: dict):
    """Обработчик события UserIconUriChangedEvent"""
    user_id = event_data.get("user_id")
    if not user_id:
        logger.warning("UserIconUriChangedEvent: missing user_id")
        return
    
    icon_uri = event_data.get("icon_uri")
    if not icon_uri:
        logger.warning("UserIconUriChangedEvent: missing icon_uri")
        return
    
    # Получаем сессию БД
    from common.database import SessionLocal
    db = SessionLocal()
    try:
        # Преобразуем user_id из строки в UUID
        try:
            user_uuid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
        except (ValueError, TypeError) as e:
            logger.error(f"UserIconUriChangedEvent: invalid user_id format {user_id}: {e}")
            return
        
        user = db.query(User).filter(User.id == user_uuid).first()
        if not user:
            logger.warning(f"UserIconUriChangedEvent: user {user_id} not found")
            return
        
        user.icon_uri = icon_uri
        db.commit()
        logger.info(f"UserIconUriChangedEvent: updated icon_uri for user {user_id}")
    except Exception as e:
        db.rollback()
        logger.error(f"Error handling UserIconUriChangedEvent: {e}")
    finally:
        db.close()

async def handle_user_deleted(event_data: dict):
    """Обработчик события UserDeletedEvent"""
    user_id = event_data.get("user_id")
    if not user_id:
        logger.warning("UserDeletedEvent: missing user_id")
        return
    
    # Получаем сессию БД
    from common.database import SessionLocal
    db = SessionLocal()
    try:
        # Преобразуем user_id из строки в UUID
        try:
            user_uuid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
        except (ValueError, TypeError) as e:
            logger.error(f"UserDeletedEvent: invalid user_id format {user_id}: {e}")
            return
        
        user = db.query(User).filter(User.id == user_uuid).first()
        if not user:
            logger.warning(f"UserDeletedEvent: user {user_id} not found")
            return
        
        db.delete(user)
        db.commit()
        logger.info(f"UserDeletedEvent: deleted user {user_id}")
    except Exception as e:
        db.rollback()
        logger.error(f"Error handling UserDeletedEvent: {e}")
    finally:
        db.close()

async def start_consumers():
    """Запустить все consumers для Authentication Service"""
    try:
        await consume_event(
            "UserDataChangedEvent",
            "auth_user_data_changed_queue",
            handle_user_data_changed
        )
        await consume_event(
            "UserIconUriChangedEvent",
            "auth_user_icon_uri_changed_queue",
            handle_user_icon_uri_changed
        )
        await consume_event(
            "UserDeletedEvent",
            "auth_user_deleted_queue",
            handle_user_deleted
        )
        logger.info("Authentication Service consumers started")
    except Exception as e:
        logger.error(f"Failed to start Authentication Service consumers: {e}")
