# Быстрое исправление всех проблем с миграциями

## Полная команда для исправления всех проблем

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
git pull origin main && \
rm -f alembic/versions/*_initial_migration.py && \
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true && \
alembic revision --autogenerate -m "Initial migration" && \
python fix_migration.py && \
python fix_migration_sqlite.py && \
python skip_existing_tables.py && \
alembic upgrade head && \
echo "✓ Migration applied successfully"
```

## Пошагово

```bash
# 1. Получить изменения
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
git pull origin main

# 2. Удалить проблемные миграции
rm -f alembic/versions/*_initial_migration.py

# 3. Очистить версию в БД
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true

# 4. Создать новую миграцию
alembic revision --autogenerate -m "Initial migration"

# 5. Исправить все проблемы в миграции
python fix_migration.py          # Добавить импорты
python fix_migration_sqlite.py   # Убрать ALTER COLUMN
python skip_existing_tables.py   # Пропустить существующие таблицы

# 6. Применить миграцию
alembic upgrade head

# 7. Перезапустить сервисы
./restart_services.sh
```

## Альтернатива: Пометить текущее состояние

Если таблицы уже созданы и работают, можно просто пометить текущее состояние:

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Пометить текущее состояние как head
alembic stamp head

# Проверить
alembic current
```

Это пропустит создание таблиц и просто пометит текущее состояние БД как актуальное.
