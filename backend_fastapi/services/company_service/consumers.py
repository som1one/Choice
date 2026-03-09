"""Consumers для обработки событий RabbitMQ в Company Service"""
import sys
from pathlib import Path
import logging

# Добавить корневую директорию в путь для импортов
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

try:
    from common.rabbitmq_service import consume_event
    from common.database import SessionLocal
    from services.company_service.models import Company
except ImportError:
    from common.rabbitmq_service import consume_event
    from common.database import SessionLocal
    from .models import Company

logger = logging.getLogger(__name__)

async def handle_user_created(event_data: dict):
    """Обработчик события UserCreatedEvent - создание компании"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Company":
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
        
        # Получаем координаты адреса
        from common.address_service import geocode
        coordinates = await geocode(city, street)
        
        db = SessionLocal()
        try:
            # Проверяем, не существует ли уже компания
            existing_company = db.query(Company).filter(Company.guid == str(user_id)).first()
            if existing_company:
                logger.info(f"UserCreatedEvent: company {user_id} already exists")
                return
            
            # Создаем новую компанию
            company = Company(
                guid=str(user_id),
                title=user_name,
                email=email,
                phone_number=phone_number,
                city=city,
                street=street,
                coordinates=coordinates,
                icon_uri="defaulturi-png"
            )
            
            db.add(company)
            db.commit()
            logger.info(f"UserCreatedEvent: created company {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserCreatedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserCreatedEvent: {e}")

async def handle_user_data_changed(event_data: dict):
    """Обработчик события UserDataChangedEvent - обновление данных компании"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Company":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserDataChangedEvent: missing user_id")
            return
        
        db = SessionLocal()
        try:
            company = db.query(Company).filter(Company.guid == str(user_id)).first()
            if not company:
                logger.warning(f"UserDataChangedEvent: company {user_id} not found")
                return
            
            # Обновляем данные компании
            address_changed = False
            
            if "email" in event_data:
                company.email = event_data["email"]
            if "title" in event_data:
                company.title = event_data["title"]
            if "phone_number" in event_data:
                company.phone_number = event_data["phone_number"]
            if "city" in event_data:
                company.city = event_data["city"]
                address_changed = True
            if "street" in event_data:
                company.street = event_data["street"]
                address_changed = True
            
            # Обновляем координаты только если изменился адрес
            if address_changed:
                from common.address_service import geocode
                coordinates = await geocode(company.city, company.street)
                company.coordinates = coordinates
            
            db.commit()
            logger.info(f"UserDataChangedEvent: updated company {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserDataChangedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserDataChangedEvent: {e}")

async def handle_user_icon_uri_changed(event_data: dict):
    """Обработчик события UserIconUriChangedEvent - обновление иконки компании"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Company":
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
            company = db.query(Company).filter(Company.guid == str(user_id)).first()
            if not company:
                logger.warning(f"UserIconUriChangedEvent: company {user_id} not found")
                return
            
            company.icon_uri = icon_uri
            db.commit()
            logger.info(f"UserIconUriChangedEvent: updated icon_uri for company {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserIconUriChangedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserIconUriChangedEvent: {e}")

async def handle_user_deleted(event_data: dict):
    """Обработчик события UserDeletedEvent - удаление компании"""
    try:
        user_type = event_data.get("user_type")
        if user_type != "Company":
            # Это событие не для нас
            return
        
        user_id = event_data.get("user_id")
        if not user_id:
            logger.warning("UserDeletedEvent: missing user_id")
            return
        
        db = SessionLocal()
        try:
            company = db.query(Company).filter(Company.guid == str(user_id)).first()
            if not company:
                logger.warning(f"UserDeletedEvent: company {user_id} not found")
                return
            
            db.delete(company)
            db.commit()
            logger.info(f"UserDeletedEvent: deleted company {user_id}")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling UserDeletedEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling UserDeletedEvent: {e}")

async def handle_review_left(event_data: dict):
    """Обработчик события ReviewLeftEvent - обновление рейтинга компании"""
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
        if review_type != "Company":
            # Это событие не для нас (отзыв не о компании)
            return
        
        db = SessionLocal()
        try:
            company = db.query(Company).filter(Company.guid == str(reviewed_id)).first()
            if not company:
                logger.warning(f"ReviewLeftEvent: company {reviewed_id} not found")
                return
            
            # Обновляем средний рейтинг
            # Формула: новый_рейтинг = (старый_рейтинг * количество + новый_оценка) / (количество + 1)
            current_grade = company.average_grade or 0.0
            current_count = company.reviews_count or 0
            
            if current_count == 0:
                company.average_grade = float(grade)
            else:
                total_grade = current_grade * current_count + float(grade)
                company.average_grade = total_grade / (current_count + 1)
            
            company.reviews_count = current_count + 1
            
            db.commit()
            logger.info(f"ReviewLeftEvent: updated rating for company {reviewed_id} (new grade: {company.average_grade})")
        except Exception as e:
            db.rollback()
            logger.error(f"Error handling ReviewLeftEvent: {e}")
        finally:
            db.close()
    except Exception as e:
        logger.error(f"Error handling ReviewLeftEvent: {e}")

async def start_consumers():
    """Запустить все consumers для Company Service"""
    try:
        await consume_event(
            "UserCreatedEvent",
            "company_user_created_queue",
            handle_user_created
        )
        await consume_event(
            "UserDataChangedEvent",
            "company_user_data_changed_queue",
            handle_user_data_changed
        )
        await consume_event(
            "UserIconUriChangedEvent",
            "company_user_icon_uri_changed_queue",
            handle_user_icon_uri_changed
        )
        await consume_event(
            "UserDeletedEvent",
            "company_user_deleted_queue",
            handle_user_deleted
        )
        await consume_event(
            "ReviewLeftEvent",
            "company_review_left_queue",
            handle_review_left
        )
        logger.info("Company Service consumers started")
    except Exception as e:
        logger.error(f"Failed to start Company Service consumers: {e}")
