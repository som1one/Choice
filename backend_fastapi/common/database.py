"""Настройка подключения к базе данных"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings

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
