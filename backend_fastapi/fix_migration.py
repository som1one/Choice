#!/usr/bin/env python3
"""Скрипт для исправления сгенерированных миграций Alembic"""
import sys
from pathlib import Path
import re

def fix_migration_file(file_path: Path):
    """Исправляет миграцию, добавляя недостающие импорты"""
    content = file_path.read_text()
    
    # Проверяем, нужны ли исправления
    needs_fix = False
    fixes = []
    
    # Проверяем наличие String, Integer, Boolean и т.д. без импорта
    if "sa.Column" in content and "from sqlalchemy import" not in content:
        if "String()" in content or "Integer()" in content or "Boolean()" in content:
            needs_fix = True
    
    # Проверяем наличие postgresql.ARRAY
    if "postgresql.ARRAY" in content and "from sqlalchemy.dialects import postgresql" not in content:
        needs_fix = True
        fixes.append("postgresql")
    
    if not needs_fix:
        print(f"✓ {file_path.name} - no fixes needed")
        return
    
    # Находим место для вставки импортов (после импорта alembic)
    lines = content.split('\n')
    import_index = 0
    
    for i, line in enumerate(lines):
        if line.startswith("from alembic import"):
            import_index = i + 1
            break
    
    # Формируем импорты
    imports = ["from sqlalchemy import String, Integer, Boolean, Float, Text, DateTime"]
    if "postgresql" in fixes:
        imports.append("from sqlalchemy.dialects import postgresql")
    
    # Вставляем импорты
    for imp in reversed(imports):
        lines.insert(import_index, imp)
    
    # Записываем исправленный файл
    fixed_content = '\n'.join(lines)
    file_path.write_text(fixed_content)
    print(f"✓ Fixed {file_path.name} - added imports")

def fix_latest_migration():
    """Исправляет последнюю миграцию"""
    versions_dir = Path("alembic/versions")
    
    if not versions_dir.exists():
        print("ERROR: alembic/versions directory not found")
        return
    
    # Находим последний файл миграции
    migration_files = sorted(versions_dir.glob("*.py"), key=lambda p: p.stat().st_mtime, reverse=True)
    
    if not migration_files:
        print("No migration files found")
        return
    
    latest = migration_files[0]
    print(f"Fixing latest migration: {latest.name}")
    fix_migration_file(latest)

if __name__ == "__main__":
    fix_latest_migration()
