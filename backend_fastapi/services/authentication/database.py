"""Настройка БД для Authentication Service"""
from common.database import Base, engine, get_db

def init_db():
    """Инициализация БД"""
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        # Если БД недоступна, просто логируем ошибку
        # Таблицы создадутся при первом подключении
        print(f"Warning: Could not initialize database: {e}")
