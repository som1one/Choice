#!/usr/bin/env python3
"""Скрипт для исправления alembic/env.py"""
import sys
from pathlib import Path

# Путь к env.py
env_py_path = Path("alembic/env.py")

if not env_py_path.exists():
    print("ERROR: alembic/env.py not found!")
    print("Run 'alembic init alembic' first")
    sys.exit(1)

# Читаем текущий файл
content = env_py_path.read_text()

# Проверяем, нужно ли обновление
if "from common.database import Base" in content and "target_metadata = Base.metadata" in content:
    print("alembic/env.py already configured correctly")
    sys.exit(0)

# Находим место для вставки импортов (после стандартных импортов)
import_section = """import sys
from pathlib import Path

# Добавить путь к проекту
sys.path.insert(0, str(Path(__file__).parent.parent))

# Импортировать все модели для Alembic
from services.authentication.models import User
from services.company_service.models import Company
from services.client_service.models import Client
from services.ordering.models import Order
from services.chat.models import Message
from services.review_service.models import Review
from services.category_service.models import Category

# Импортировать Base для metadata
from common.database import Base
"""

# Находим место после импортов alembic
if "from alembic import context" in content:
    # Вставляем после импортов alembic
    lines = content.split('\n')
    insert_index = 0
    for i, line in enumerate(lines):
        if line.startswith("from alembic import context"):
            insert_index = i + 1
            break
    
    # Вставляем наши импорты
    lines.insert(insert_index, import_section)
    content = '\n'.join(lines)

# Обновляем target_metadata
if "target_metadata = None" in content:
    content = content.replace("target_metadata = None", "target_metadata = Base.metadata")
elif "target_metadata = " not in content:
    # Ищем функцию run_migrations_offline или run_migrations_online
    if "def run_migrations_offline():" in content:
        # Добавляем перед функцией
        content = content.replace(
            "def run_migrations_offline():",
            "target_metadata = Base.metadata\n\ndef run_migrations_offline():"
        )

# Записываем обновленный файл
env_py_path.write_text(content)
print("✓ Updated alembic/env.py")
print("  - Added model imports")
print("  - Set target_metadata = Base.metadata")
