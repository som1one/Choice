# Исправление ошибки ALTER COLUMN в SQLite

## Проблема

```
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) near "ALTER": syntax error
[SQL: ALTER TABLE "Users" ALTER COLUMN id TYPE UUID]
```

SQLite не поддерживает `ALTER COLUMN TYPE`. Нужно удалить или закомментировать эту операцию в миграции.

## Решение

### Вариант 1: Использовать скрипт исправления

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
python fix_migration_sqlite.py
alembic upgrade head
```

### Вариант 2: Исправить вручную

Откройте файл миграции (последний в `alembic/versions/`) и найдите строки типа:

```python
op.alter_column('Users', 'id', type_=sa.UUID())
```

Закомментируйте или удалите эти строки:

```python
# SQLite doesn't support ALTER COLUMN TYPE
# op.alter_column('Users', 'id', type_=sa.UUID())
```

### Вариант 3: Удалить проблемную миграцию и создать новую

```bash
# Удалить последнюю миграцию
rm alembic/versions/*_initial_migration.py

# Удалить запись из alembic_version
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true

# Создать новую миграцию
alembic revision --autogenerate -m "Initial migration"

# Исправить миграцию
python fix_migration_sqlite.py

# Применить
alembic upgrade head
```

## Полная команда исправления

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
git pull origin main && \
rm -f alembic/versions/*_initial_migration.py && \
sqlite3 choice.db "DELETE FROM alembic_version;" 2>/dev/null || true && \
alembic revision --autogenerate -m "Initial migration" && \
python fix_migration_sqlite.py && \
alembic upgrade head
```

## Примечание

SQLite не поддерживает изменение типа колонки. Если нужно изменить тип колонки в SQLite, нужно:
1. Создать новую таблицу с правильным типом
2. Скопировать данные
3. Удалить старую таблицу
4. Переименовать новую таблицу

Но в данном случае, если колонка уже существует с неправильным типом, лучше оставить её как есть или создать новую миграцию для пересоздания таблицы.
