"""Настройка БД для Company Service"""
from common.database import Base, engine
from sqlalchemy import inspect
from .models import Company  # Импортируем модели для создания таблиц
from .models_rating import RatingCriterion, CompanyService, CompanyProduct

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
        print(f"Warning: Could not initialize database: {e}")
