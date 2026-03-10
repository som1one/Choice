# Исправление ошибки "Target database is not up to date"

## Проблема

```
ERROR [alembic.util.messaging] Target database is not up to date.
FAILED: Target database is not up to date.
```

Это означает, что версия миграции в базе данных не совпадает с файлами миграций.

## Решение

### Вариант 1: Сбросить версию и применить заново

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Сбросить версию в БД
python fix_alembic_version.py reset

# Или вручную для SQLite:
sqlite3 choice.db "DELETE FROM alembic_version;"

# Применить миграции заново
alembic upgrade head
```

### Вариант 2: Исправить версию автоматически

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Автоматически обновить версию на последнюю из файлов
python fix_alembic_version.py

# Применить миграции
alembic upgrade head
```

### Вариант 3: Пометить текущее состояние как актуальное

```bash
# Пометить текущее состояние БД как head (последняя версия)
alembic stamp head
```

### Вариант 4: Полный сброс и пересоздание миграций

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Удалить все миграции
rm -rf alembic/versions/*.py

# Очистить версию в БД
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true

# Создать новую миграцию
alembic revision --autogenerate -m "Initial migration"

# Исправить миграцию для SQLite
python fix_migration_sqlite.py

# Применить
alembic upgrade head
```

## Полная команда исправления

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
python fix_alembic_version.py reset && \
alembic upgrade head
```

## Проверка текущей версии

```bash
# Текущая версия в БД
alembic current

# История миграций
alembic history

# Версия в БД напрямую (SQLite)
sqlite3 choice.db "SELECT * FROM alembic_version;"
```

## Если ничего не помогает

```bash
# Полный сброс
rm -rf alembic/versions/*.py
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true
alembic revision --autogenerate -m "Initial migration"
python fix_migration_sqlite.py
alembic upgrade head
```
