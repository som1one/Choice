"""Настройка БД для Authentication Service"""
from common.database import Base, engine, get_db
from sqlalchemy import inspect, text

def init_db():
    """Инициализация БД - создает таблицы только если их еще нет, и добавляет недостающие колонки"""
    try:
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        
        # Получаем список таблиц, которые должны быть созданы
        required_tables = list(Base.metadata.tables.keys())
        
        # Создаем только те таблицы, которых еще нет
        if not all(table in existing_tables for table in required_tables):
            Base.metadata.create_all(bind=engine)
        
        # Проверяем и добавляем недостающие колонки в таблицу Users
        if "Users" in existing_tables:
            with engine.connect() as conn:
                # Получаем список существующих колонок
                existing_columns = [col['name'] for col in inspector.get_columns("Users")]
                
                # Проверяем наличие device_token
                if "device_token" not in existing_columns:
                    try:
                        # Для SQLite используем ALTER TABLE
                        if engine.url.drivername == "sqlite":
                            conn.execute(text("ALTER TABLE Users ADD COLUMN device_token VARCHAR"))
                        # Для PostgreSQL
                        elif engine.url.drivername.startswith("postgresql"):
                            conn.execute(text("ALTER TABLE \"Users\" ADD COLUMN device_token VARCHAR"))
                        conn.commit()
                        print("Added device_token column to Users table")
                    except Exception as e:
                        print(f"Warning: Could not add device_token column: {e}")
                        conn.rollback()
                
                # Проверяем наличие is_blocked
                if "is_blocked" not in existing_columns:
                    try:
                        if engine.url.drivername == "sqlite":
                            conn.execute(text("ALTER TABLE Users ADD COLUMN is_blocked BOOLEAN DEFAULT 0"))
                        elif engine.url.drivername.startswith("postgresql"):
                            conn.execute(text("ALTER TABLE \"Users\" ADD COLUMN is_blocked BOOLEAN DEFAULT FALSE"))
                        conn.commit()
                        print("Added is_blocked column to Users table")
                    except Exception as e:
                        print(f"Warning: Could not add is_blocked column: {e}")
                        conn.rollback()
    except Exception as e:
        # Если БД недоступна, просто логируем ошибку
        # Таблицы создадутся при первом подключении
        print(f"Warning: Could not initialize database: {e}")
