"""Настройка БД для Client Service"""
from common.database import Base, engine

def init_db():
    """Инициализация БД"""
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        print(f"Warning: Could not initialize database: {e}")
