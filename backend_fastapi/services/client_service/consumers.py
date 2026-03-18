"""Consumers для обработки событий RabbitMQ в Client Service"""
import sys
from pathlib import Path
import logging
import uuid

# Добавить корневую директорию в путь для импортов
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

try:
    from common.rabbitmq_service import consume_event
    from common.database import SessionLocal
    from services.client_service.models import Client
except ImportError:
    from common.rabbitmq_service import consume_event
    from common.database import SessionLocal
    from .models import Client

logger = logging.getLogger(__name__)

async def handle_user_created(event_data: dict):
    """Обработчик события UserCreatedEvent - создание клиента"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Client":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserCreatedEvent: missing user_id")
            return
        
        user_name = event_data.get("user_name", "")
        email = event_data.get("email", "")
        city = event_data.get("city", "")
        street = event_data.get("street", "")
        phone_number = event_data.get("phone_number", "")
        
        # Разделяем имя на name и surname
        name_parts = user_name.split("_", 1)
        name = name_parts[0] if name_parts else ""
        surname = name_parts[1] if len(name_parts) > 1 else ""
        
        # Получаем координаты адреса
        from common.address_service import geocode
        coordinates = await geocode(city, street)
        
        db = SessionLocal()
        try:
            # Проверяем, не существует ли уже клиент
            existing_client = db.query(Client).filter(Client.guid == str(user_id)).first()
            if existing_client:
                logger.info(f"UserCreatedEvent: client {user_id} already exists")
                return
            
            # Создаем нового клиента
            client = Client(
                guid=str(user_id),
                name=name,
                surname=surname,
                email=email,
                phone_number=phone_number,
                city=city,
                street=street,
                coordinates=coordinates,
                icon_uri="defaulturi-png"
            )
            
            db.add(client)
            db.commit()
            logger.info(f"UserCreatedEvent: created client {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserCreatedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserCreatedEvent: {e}")

async def handle_user_data_changed(event_data: dict):
    """Обработчик события UserDataChangedEvent - обновление данных клиента"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Client":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserDataChangedEvent: missing user_id")
            return
        
        db = SessionLocal()
        try:
            client = db.query(Client).filter(Client.guid == str(user_id)).first()
            if not client:
                logger.warning(f"UserDataChangedEvent: client {user_id} not found")
                return
            
            # Обновляем данные клиента
            address_changed = False
            
            if "email" in event_data:
                client.email = event_data["email"]
            if "name" in event_data:
                client.name = event_data["name"]
            if "surname" in event_data:
                client.surname = event_data["surname"]
            if "phone_number" in event_data:
                client.phone_number = event_data["phone_number"]
            if "city" in event_data:
                client.city = event_data["city"]
                address_changed = True
            if "street" in event_data:
                client.street = event_data["street"]
                address_changed = True
            
            # Обновляем координаты только если изменился адрес
            if address_changed:
                from common.address_service import geocode
                coordinates = await geocode(client.city, client.street)
                client.coordinates = coordinates
            
            db.commit()
            logger.info(f"UserDataChangedEvent: updated client {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserDataChangedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserDataChangedEvent: {e}")

async def handle_user_icon_uri_changed(event_data: dict):
    """Обработчик события UserIconUriChangedEvent - обновление иконки клиента"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Client":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserIconUriChangedEvent: missing user_id")
            return
        
        icon_uri = event_data.get("icon_uri")
        if not icon_uri:
            logger.warning("UserIconUriChangedEvent: missing icon_uri")
            return
        
        db = SessionLocal()
        try:
            client = db.query(Client).filter(Client.guid == str(user_id)).first()
            if not client:
                logger.warning(f"UserIconUriChangedEvent: client {user_id} not found")
                return
            
            client.icon_uri = icon_uri
            db.commit()
            logger.info(f"UserIconUriChangedEvent: updated icon_uri for client {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserIconUriChangedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserIconUriChangedEvent: {e}")

async def handle_user_deleted(event_data: dict):
    """Обработчик события UserDeletedEvent - удаление клиента"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Client":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserDeletedEvent: missing user_id")
            return
        
        db = SessionLocal()
        try:
            client = db.query(Client).filter(Client.guid == str(user_id)).first()
            if not client:
                logger.warning(f"UserDeletedEvent: client {user_id} not found")
                return
            
            db.delete(client)
            db.commit()
            logger.info(f"UserDeletedEvent: deleted client {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserDeletedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserDeletedEvent: {e}")

async def handle_review_left(event_data: dict):
    """Обработчик события ReviewLeftEvent - обновление рейтинга клиента"""
    try:
        reviewed_id = event_data.get("reviewed_id")
        if not reviewed_id:
            logger.warning("ReviewLeftEvent: missing reviewed_id")
            return

        grade = event_data.get("grade")
        if grade is None:
            logger.warning("ReviewLeftEvent: missing grade")
            return

        review_type = event_data.get("review_type")
        if review_type != "Client":
            # Это событие не для нас (отзыв не о клиенте)
            return

        db = SessionLocal()
        try:
            client = db.query(Client).filter(Client.guid == str(reviewed_id)).first()
            if not client:
                logger.warning(f"ReviewLeftEvent: client {reviewed_id} not found")
                return

            # Формула: новый_рейтинг = (старый_рейтинг * количество + новая_оценка) / (количество + 1)
            current_grade = client.average_grade or 0.0
            current_count = client.review_count or 0

            if current_count == 0:
                client.average_grade = float(grade)
            else:
                total_grade = current_grade * current_count + float(grade)
                client.average_grade = total_grade / (current_count + 1)

            client.review_count = current_count + 1

            db.commit()
            logger.info(f"ReviewLeftEvent: updated rating for client {reviewed_id} (new grade: {client.average_grade})")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling ReviewLeftEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling ReviewLeftEvent: {e}")

async def start_consumers():
    """Запустить все consumers для Client Service"""
    try:
        await consume_event(
            "UserCreatedEvent",
            "client_user_created_queue",
            handle_user_created
        )
        await consume_event(
            "UserDataChangedEvent",
            "client_user_data_changed_queue",
            handle_user_data_changed
        )
        await consume_event(
            "UserIconUriChangedEvent",
            "client_user_icon_uri_changed_queue",
            handle_user_icon_uri_changed
        )
        await consume_event(
            "UserDeletedEvent",
            "client_user_deleted_queue",
            handle_user_deleted
        )
        await consume_event(
            "ReviewLeftEvent",
            "client_review_left_queue",
            handle_review_left
        )
        logger.info("Client Service consumers started")
    except Exception as e:
        logger.error(f"Failed to start Client Service consumers: {e}")
