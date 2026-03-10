# Исправление всех моделей с ARRAY для совместимости с SQLite

## Проблема

SQLite не поддерживает тип ARRAY, который используется в PostgreSQL. Все модели с ARRAY полями нужно исправить для использования JSON в SQLite.

## Исправленные модели

✅ **Company** - `social_medias`, `photo_uris`, `categories_id`
✅ **ChatUser** - `device_tokens`
✅ **Review** - `photo_uris`
✅ **Order** - `reviews`

## Команды для применения исправлений на сервере

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
git pull origin main

# Удалить старую проблемную миграцию
rm alembic/versions/1491430c2493_initial_migration.py

# Удалить запись из alembic_version (если была применена)
# Для SQLite:
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true

# Создать новую миграцию
alembic revision --autogenerate -m "Initial migration with SQLite compatibility"

# Исправить импорты в новой миграции
python fix_migration.py

# Применить миграцию
alembic upgrade head
```

## Полная команда

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
git pull origin main && \
rm -f alembic/versions/1491430c2493_initial_migration.py && \
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true && \
alembic revision --autogenerate -m "Initial migration with SQLite compatibility" && \
python fix_migration.py && \
alembic upgrade head && \
echo "✓ Migration applied successfully"
```

## Проверка после применения

```bash
# Проверка текущей версии
alembic current

# Проверка таблиц в БД
python -c "from common.database import engine; from sqlalchemy import inspect; print(inspect(engine).get_table_names())"
```
