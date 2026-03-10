# Исправление ошибки "table already exists"

## Проблема

```
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) table "ChatUsers" already exists
```

Таблица уже существует в базе данных, но миграция пытается создать её заново.

## Решение

### Вариант 1: Использовать скрипт исправления

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
git pull origin main

# Исправить миграцию, чтобы пропускать существующие таблицы
python skip_existing_tables.py

# Применить миграцию
alembic upgrade head
```

### Вариант 2: Удалить существующие таблицы (ОСТОРОЖНО!)

```bash
# Удалить все таблицы (данные будут потеряны!)
sqlite3 choice.db ".tables" | tr -s ' ' '\n' | grep -v "^$" | xargs -I {} sqlite3 choice.db "DROP TABLE IF EXISTS {};"

# Применить миграции заново
alembic upgrade head
```

### Вариант 3: Исправить миграцию вручную

Откройте файл миграции и найдите:
```python
op.create_table('ChatUsers', ...)
```

Замените на:
```python
from sqlalchemy import inspect
bind = op.get_bind()
inspector = inspect(bind)
existing_tables = inspector.get_table_names()

if 'ChatUsers' not in existing_tables:
    op.create_table('ChatUsers', ...)
else:
    # Таблица ChatUsers уже существует, пропускаем
    pass
```

### Вариант 4: Пометить текущее состояние и создать новую миграцию

```bash
# Пометить текущее состояние как head
alembic stamp head

# Создать новую миграцию только для изменений
alembic revision --autogenerate -m "Add new changes"
python fix_migration_sqlite.py
alembic upgrade head
```

## Полная команда исправления

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
git pull origin main && \
python skip_existing_tables.py && \
alembic upgrade head
```

## Безопасный способ (сохранить данные)

```bash
# 1. Пометить текущее состояние
alembic stamp head

# 2. Создать новую миграцию только для новых изменений
alembic revision --autogenerate -m "New changes"

# 3. Исправить миграцию
python fix_migration_sqlite.py
python skip_existing_tables.py

# 4. Применить
alembic upgrade head
```
