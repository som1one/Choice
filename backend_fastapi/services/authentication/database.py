"""Настройка БД для Authentication Service"""
from common.database import Base, engine, get_db
from sqlalchemy import inspect

def init_db():
    """Инициализация БД - создает таблицы только если их еще нет"""
    try:
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        
        # Получаем список таблиц, которые должны быть созданы
        required_tables = list(Base.metadata.tables.keys())
        
        # Создаем только те таблицы, которых еще нет
        if not all(table in existing_tables for table in required_tables):
            Base.metadata.create_all(bind=engine)
    except Exception as e:
        # Если БД недоступна, просто логируем ошибку
        # Таблицы создадутся при первом подключении
        print(f"Warning: Could not initialize database: {e}")
