"""Настройка БД для Client Service"""
from common.database import Base, engine
from sqlalchemy import inspect, text

def init_db():
    """Инициализация БД - создает таблицы и добавляет недостающие колонки."""
    try:
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        
        # Получаем список таблиц, которые должны быть созданы
        required_tables = list(Base.metadata.tables.keys())
        
        # Создаем только те таблицы, которых еще нет
        if not all(table in existing_tables for table in required_tables):
            Base.metadata.create_all(bind=engine)

        if "OrderRequests" in existing_tables:
            existing_columns = [
                col["name"] for col in inspector.get_columns("OrderRequests")
            ]
            if "to_know_specialist" not in existing_columns:
                with engine.connect() as conn:
                    try:
                        table_name = "OrderRequests"
                        if engine.url.drivername.startswith("postgresql"):
                            table_name = '"OrderRequests"'
                        conn.execute(
                            text(
                                f"ALTER TABLE {table_name} "
                                "ADD COLUMN to_know_specialist VARCHAR DEFAULT 'false'"
                            )
                        )
                        conn.commit()
                    except Exception as e:
                        print(
                            "Warning: Could not add to_know_specialist column: "
                            f"{e}"
                        )
                        conn.rollback()
            if "creation_date" not in existing_columns:
                with engine.connect() as conn:
                    try:
                        table_name = "OrderRequests"
                        if engine.url.drivername.startswith("postgresql"):
                            table_name = '"OrderRequests"'

                        if engine.url.drivername.startswith("postgresql"):
                            conn.execute(
                                text(
                                    f"ALTER TABLE {table_name} "
                                    "ADD COLUMN creation_date TIMESTAMP DEFAULT NOW()"
                                )
                            )
                            conn.execute(
                                text(
                                    f"UPDATE {table_name} "
                                    "SET creation_date = NOW() "
                                    "WHERE creation_date IS NULL"
                                )
                            )
                            conn.execute(
                                text(
                                    f"ALTER TABLE {table_name} "
                                    "ALTER COLUMN creation_date SET NOT NULL"
                                )
                            )
                        else:
                            conn.execute(
                                text(
                                    f"ALTER TABLE {table_name} "
                                    "ADD COLUMN creation_date DATETIME DEFAULT CURRENT_TIMESTAMP"
                                )
                            )
                            conn.execute(
                                text(
                                    f"UPDATE {table_name} "
                                    "SET creation_date = CURRENT_TIMESTAMP "
                                    "WHERE creation_date IS NULL"
                                )
                            )

                        conn.commit()
                    except Exception as e:
                        print(
                            "Warning: Could not add creation_date column: "
                            f"{e}"
                        )
                        conn.rollback()
    except Exception as e:
        print(f"Warning: Could not initialize database: {e}")
