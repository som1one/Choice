"""Настройка подключения к базе данных"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings
from pathlib import Path
import os

class DatabaseSettings(BaseSettings):
    # По умолчанию используем локальную SQLite БД, чтобы сервисы запускались "из коробки".
    # В продакшене переопределяй через переменную окружения DATABASE_URL или через .env.
    database_url: str = "sqlite:///./choice.db"
    sql_server_connection: str | None = None
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

settings = DatabaseSettings()

# Если используется SQLite, преобразуем относительный путь в абсолютный
# чтобы все сервисы использовали один и тот же файл БД
if settings.database_url.lower().startswith("sqlite"):
    db_path = settings.database_url.replace("sqlite:///", "")
    if db_path.startswith("./") or not os.path.isabs(db_path):
        # Получаем абсолютный путь относительно корня проекта backend_fastapi
        # Находим корень проекта (где находится common/database.py)
        current_file = Path(__file__).resolve()
        project_root = current_file.parent.parent  # backend_fastapi
        absolute_db_path = project_root / db_path.lstrip("./")
        # Создаем директорию для БД, если её нет
        absolute_db_path.parent.mkdir(parents=True, exist_ok=True)
        settings.database_url = f"sqlite:///{absolute_db_path}"

# SQLAlchemy setup
engine_kwargs: dict = {
    "pool_pre_ping": True,
    "echo": False,
}

# Для SQLite нужен check_same_thread=False при работе в многопоточном окружении (FastAPI/uvicorn).
if settings.database_url.lower().startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, **engine_kwargs)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency для получения сессии БД"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
