#!/usr/bin/env python3
"""Скрипт для исправления миграций Alembic для SQLite"""
import sys
from pathlib import Path
import re

def fix_migration_for_sqlite(file_path: Path):
    """Исправляет миграцию для работы с SQLite"""
    content = file_path.read_text()
    original_content = content
    
    # 1. Добавляем недостающие импорты
    if "from sqlalchemy import" not in content or "String" not in content:
        lines = content.split('\n')
        import_index = 0
        
        for i, line in enumerate(lines):
            if line.startswith("from alembic import"):
                import_index = i + 1
                break
        
        imports = ["from sqlalchemy import String, Integer, Boolean, Float, Text, DateTime, UUID"]
        if "postgresql.ARRAY" in content or "postgresql" in content:
            imports.append("from sqlalchemy.dialects import postgresql")
        
        for imp in reversed(imports):
            if imp not in content:
                lines.insert(import_index, imp)
        
        content = '\n'.join(lines)
    
    # 2. Удаляем или комментируем ALTER COLUMN для SQLite (SQLite не поддерживает это)
    # Ищем паттерны типа: ALTER TABLE "Users" ALTER COLUMN id TYPE UUID
    sqlite_unsupported_patterns = [
        r"op\.alter_column\([^)]+TYPE[^)]+\)",
        r'sa\.Column\([^)]+TYPE[^)]+\)',
    ]
    
    # Заменяем ALTER COLUMN TYPE на комментарий для SQLite
    def replace_alter_column(match):
        return f"# SQLite doesn't support ALTER COLUMN TYPE: {match.group(0)}"
    
    for pattern in sqlite_unsupported_patterns:
        content = re.sub(pattern, replace_alter_column, content, flags=re.MULTILINE)
    
    # 3. Удаляем строки с ALTER COLUMN TYPE в upgrade/downgrade функциях
    lines = content.split('\n')
    new_lines = []
    skip_next = False
    
    for i, line in enumerate(lines):
        # Пропускаем строки с ALTER COLUMN TYPE
        if 'ALTER COLUMN' in line and 'TYPE' in line:
            # Комментируем вместо удаления
            new_lines.append(f"        # SQLite: {line.strip()}")
            continue
        # Пропускаем op.alter_column с type_ параметром
        if 'op.alter_column' in line and ('type_' in line or 'TYPE' in line):
            new_lines.append(f"        # SQLite: {line.strip()}")
            continue
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    # 4. Добавляем проверку типа БД в начало upgrade функции
    if 'def upgrade()' in content and 'is_postgresql' not in content:
        # Добавляем проверку после def upgrade():
        content = content.replace(
            'def upgrade():',
            '''def upgrade():
    # Проверка типа БД
    bind = op.get_bind()
    is_postgresql = bind.dialect.name == 'postgresql'
    is_sqlite = bind.dialect.name == 'sqlite'
'''
        )
    
    if content != original_content:
        file_path.write_text(content)
        print(f"✓ Fixed {file_path.name} for SQLite compatibility")
        return True
    else:
        print(f"✓ {file_path.name} - no fixes needed")
        return False

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
    fix_migration_for_sqlite(latest)

if __name__ == "__main__":
    fix_latest_migration()
