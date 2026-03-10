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
    lines = content.split('\n')
    new_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Пропускаем строки с ALTER COLUMN TYPE
        if 'ALTER COLUMN' in line and 'TYPE' in line:
            indent = len(line) - len(line.lstrip())
            new_lines.append(' ' * indent + f"# SQLite doesn't support ALTER COLUMN TYPE")
            i += 1
            continue
        
        # Пропускаем op.alter_column с type_ параметром
        if 'op.alter_column' in line:
            # Проверяем, есть ли type_ в этой строке или следующих (до закрывающей скобки)
            check_lines = [line]
            j = i + 1
            open_parens = line.count('(') - line.count(')')
            
            while j < len(lines) and open_parens > 0:
                check_lines.append(lines[j])
                open_parens += lines[j].count('(') - lines[j].count(')')
                j += 1
            
            full_block = ' '.join(check_lines)
            
            if 'type_' in full_block or 'TYPE' in full_block:
                indent = len(line) - len(line.lstrip())
                new_lines.append(' ' * indent + f"# SQLite: op.alter_column with type_ not supported")
                # Пропускаем все строки этого блока
                i = j
                continue
        
        new_lines.append(line)
        i += 1
    
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
    
    # Для SQLite проверяем существование таблиц перед созданием
    from sqlalchemy import inspect
    inspector = inspect(bind)
    existing_tables = inspector.get_table_names()
'''
        )
    
    # 5. Заменяем op.create_table на условное создание для SQLite
    # Ищем паттерны: op.create_table('TableName', ...
    def replace_create_table(match):
        table_name = match.group(1)
        rest = match.group(2)
        return f'''    # Проверяем существование таблицы для SQLite
    if is_sqlite and '{table_name}' in existing_tables:
        # Таблица уже существует, пропускаем создание
        pass
    else:
        op.create_table('{table_name}'{rest}'''
    
    # Заменяем op.create_table на условное создание
    content = re.sub(
        r"op\.create_table\(['\"]([^'\"]+)['\"]([^)]+)\)",
        replace_create_table,
        content
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
