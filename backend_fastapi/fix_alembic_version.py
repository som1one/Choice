#!/usr/bin/env python3
"""Скрипт для исправления версии Alembic в базе данных"""
import sys
from pathlib import Path

# Добавляем путь к проекту
project_root = Path(__file__).parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from common.database import engine
from sqlalchemy import text

def fix_alembic_version():
    """Исправляет версию Alembic в базе данных"""
    try:
        with engine.connect() as conn:
            # Проверяем, существует ли таблица alembic_version
            inspector = __import__('sqlalchemy').inspect(engine)
            tables = inspector.get_table_names()
            
            if "alembic_version" not in tables:
                print("Table alembic_version does not exist. Creating...")
                conn.execute(text("CREATE TABLE alembic_version (version_num VARCHAR(32) NOT NULL)"))
                conn.commit()
                print("✓ Created alembic_version table")
            
            # Получаем текущую версию
            result = conn.execute(text("SELECT version_num FROM alembic_version"))
            current_version = result.fetchone()
            
            if current_version:
                print(f"Current version in DB: {current_version[0]}")
            
            # Получаем последнюю версию из файлов миграций
            versions_dir = Path("alembic/versions")
            if versions_dir.exists():
                migration_files = sorted(versions_dir.glob("*.py"), key=lambda p: p.stat().st_mtime, reverse=True)
                if migration_files:
                    # Извлекаем revision из имени файла (формат: revision_description.py)
                    latest_file = migration_files[0]
                    revision = latest_file.stem.split('_')[0]
                    print(f"Latest migration file: {latest_file.name}")
                    print(f"Revision: {revision}")
                    
                    # Обновляем версию
                    conn.execute(text("DELETE FROM alembic_version"))
                    conn.execute(text(f"INSERT INTO alembic_version (version_num) VALUES ('{revision}')"))
                    conn.commit()
                    print(f"✓ Updated alembic_version to {revision}")
                    return True
            
            print("No migration files found")
            return False
            
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

def reset_alembic_version():
    """Сбрасывает версию Alembic (удаляет запись)"""
    try:
        with engine.connect() as conn:
            conn.execute(text("DELETE FROM alembic_version"))
            conn.commit()
            print("✓ Cleared alembic_version table")
            return True
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "reset":
        reset_alembic_version()
    else:
        fix_alembic_version()
