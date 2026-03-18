"""Настройка БД для Ordering Service"""
from common.database import Base, engine
from sqlalchemy import inspect, text


def _table_name_sql() -> str:
    return '"Orders"' if engine.url.drivername.startswith("postgresql") else "Orders"


def _empty_reviews_sql() -> str:
    if engine.url.drivername.startswith("postgresql"):
        return "ARRAY[]::VARCHAR[]"
    return "'[]'"


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

        if "Orders" in existing_tables:
            existing_columns = [col["name"] for col in inspector.get_columns("Orders")]
            missing_columns = {
                "response_text": "VARCHAR",
                "specialist_name": "VARCHAR",
                "specialist_phone": "VARCHAR",
            }

            table_name = _table_name_sql()
            with engine.connect() as conn:
                for column_name, sql_type in missing_columns.items():
                    if column_name in existing_columns:
                        continue
                    try:
                        conn.execute(
                            text(
                                f"ALTER TABLE {table_name} "
                                f"ADD COLUMN {column_name} {sql_type}"
                            )
                        )
                        conn.commit()
                    except Exception as e:
                        print(
                            f"Warning: Could not add {column_name} column to Orders table: {e}"
                        )
                        conn.rollback()

                # Лечим старые строки, из-за которых response_model мог отдавать 500.
                cleanup_statements = [
                    f"UPDATE {table_name} SET reviews = {_empty_reviews_sql()} WHERE reviews IS NULL",
                    f"UPDATE {table_name} SET is_enrolled = 0 WHERE is_enrolled IS NULL",
                    f"UPDATE {table_name} SET is_date_confirmed = 1 WHERE is_date_confirmed IS NULL",
                    f"UPDATE {table_name} SET status = 1 WHERE status IS NULL",
                    f"UPDATE {table_name} SET prepayment = 0 WHERE prepayment IS NULL",
                    f"UPDATE {table_name} SET deadline = 0 WHERE deadline IS NULL",
                    f"UPDATE {table_name} SET price = 0 WHERE price IS NULL",
                ]
                for statement in cleanup_statements:
                    try:
                        conn.execute(text(statement))
                        conn.commit()
                    except Exception as e:
                        print(f"Warning: Could not normalize Orders table data: {e}")
                        conn.rollback()
    except Exception as e:
        print(f"Warning: Could not initialize database: {e}")
