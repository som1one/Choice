"""Настройка БД для Company Service."""

from sqlalchemy import inspect, text

from common.database import Base, engine

from .models import Company
from .models_rating import CompanyProduct, CompanyService, RatingCriterion


def _migrate_rating_criteria_table():
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()
    if "rating_criteria" not in existing_tables:
        return

    columns = {column["name"] for column in inspector.get_columns("rating_criteria")}
    required_columns = {"grade", "text", "sort_order", "is_active"}
    if required_columns.issubset(columns):
        return

    with engine.begin() as connection:
        if engine.url.drivername.startswith("sqlite"):
            connection.execute(text("ALTER TABLE rating_criteria RENAME TO rating_criteria_legacy"))
            connection.execute(
                text(
                    """
                    CREATE TABLE rating_criteria (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        grade INTEGER NOT NULL,
                        text VARCHAR NOT NULL,
                        sort_order INTEGER NOT NULL DEFAULT 0,
                        is_active BOOLEAN NOT NULL DEFAULT 1
                    )
                    """
                )
            )
            if "name" in columns:
                connection.execute(
                    text(
                        """
                        INSERT INTO rating_criteria (id, grade, text, sort_order, is_active)
                        SELECT
                            id,
                            5,
                            CASE
                                WHEN name IS NULL OR TRIM(name) = '' THEN 'Без текста'
                                ELSE TRIM(name)
                            END,
                            0,
                            1
                        FROM rating_criteria_legacy
                        """
                    )
                )
            connection.execute(text("DROP TABLE rating_criteria_legacy"))
            connection.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_rating_criteria_grade ON rating_criteria (grade)"
                )
            )
            connection.execute(
                text(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS uq_rating_criteria_grade_text
                    ON rating_criteria (grade, text)
                    """
                )
            )
            return

        if "grade" not in columns:
            connection.execute(
                text("ALTER TABLE rating_criteria ADD COLUMN grade INTEGER NOT NULL DEFAULT 5")
            )
        if "text" not in columns:
            connection.execute(text("ALTER TABLE rating_criteria ADD COLUMN text VARCHAR"))
            if "name" in columns:
                connection.execute(text("UPDATE rating_criteria SET text = name WHERE text IS NULL"))
        if "sort_order" not in columns:
            connection.execute(
                text("ALTER TABLE rating_criteria ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0")
            )
        if "is_active" not in columns:
            connection.execute(
                text("ALTER TABLE rating_criteria ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE")
            )


def init_db():
    """Создаёт отсутствующие таблицы и мигрирует таблицу фраз отзывов."""
    try:
        _migrate_rating_criteria_table()
        inspector = inspect(engine)
        existing_tables = inspector.get_table_names()
        required_tables = list(Base.metadata.tables.keys())
        if not all(table in existing_tables for table in required_tables):
            Base.metadata.create_all(bind=engine)
    except Exception as e:
        print(f"Warning: Could not initialize database: {e}")
