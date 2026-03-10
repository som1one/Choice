#!/usr/bin/env python3
"""Скрипт для пропуска существующих таблиц в миграции"""
import sys
from pathlib import Path
import re

def fix_migration_skip_existing(file_path: Path):
    """Исправляет миграцию, чтобы пропускать существующие таблицы"""
    content = file_path.read_text()
    original_content = content
    
    # Добавляем проверку существования таблиц в начало upgrade()
    if 'def upgrade()' in content:
        # Проверяем, есть ли уже проверка существования
        if 'existing_tables' not in content or 'inspector.get_table_names()' not in content:
            # Добавляем импорт inspect
            if 'from sqlalchemy import inspect' not in content:
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if line.startswith('def upgrade():'):
                        # Добавляем после def upgrade():
                        lines.insert(i + 1, '    from sqlalchemy import inspect')
                        lines.insert(i + 2, '    bind = op.get_bind()')
                        lines.insert(i + 3, '    inspector = inspect(bind)')
                        lines.insert(i + 4, '    existing_tables = inspector.get_table_names()')
                        break
                content = '\n'.join(lines)
        
        # Заменяем op.create_table на условное создание
        def replace_create_table(match):
            full_match = match.group(0)
            table_name_match = re.search(r"['\"]([^'\"]+)['\"]", full_match)
            if table_name_match:
                table_name = table_name_match.group(1)
                # Заменяем на условное создание
                return f'''    # Проверяем существование таблицы
    if '{table_name}' not in existing_tables:
{full_match.replace('op.create_table', '        op.create_table').replace('(', '        (')}
    else:
        # Таблица {table_name} уже существует, пропускаем'''
            return full_match
        
        # Ищем все op.create_table и заменяем
        pattern = r"(\s+)op\.create_table\(['\"]([^'\"]+)['\"][^)]+\)"
        def replace_with_check(m):
            indent = m.group(1)
            table_name = m.group(2)
            full_line = m.group(0)
            # Находим полный блок create_table (до следующей строки с тем же или меньшим отступом)
            return f'''{indent}# Проверяем существование таблицы {table_name}
{indent}if '{table_name}' not in existing_tables:
{full_line.replace('op.create_table', indent + '    op.create_table')}
{indent}else:
{indent}    # Таблица {table_name} уже существует, пропускаем'''
        
        content = re.sub(pattern, replace_with_check, content, flags=re.MULTILINE)
    
    if content != original_content:
        file_path.write_text(content)
        print(f"✓ Fixed {file_path.name} to skip existing tables")
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
    fix_migration_skip_existing(latest)

if __name__ == "__main__":
    fix_latest_migration()
