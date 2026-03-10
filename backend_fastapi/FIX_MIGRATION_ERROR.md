# Исправление ошибки миграции Alembic

## Проблема

```
NameError: name 'String' is not defined
```

Миграция не содержит необходимых импортов из SQLAlchemy.

## Решение

### Вариант 1: Использовать скрипт исправления

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
python fix_migration.py
alembic upgrade head
```

### Вариант 2: Исправить вручную

Откройте файл миграции (последний в `alembic/versions/`):

```bash
# Найти последний файл миграции
ls -lt alembic/versions/*.py | head -1
```

Добавьте в начало файла (после `from alembic import op`):

```python
from sqlalchemy import String, Integer, Boolean, Float, Text, DateTime
from sqlalchemy.dialects import postgresql
```

### Вариант 3: Удалить проблемную миграцию и создать новую

```bash
# Удалить последнюю миграцию
rm alembic/versions/1491430c2493_initial_migration.py

# Удалить запись из alembic_version (если была применена)
# Для SQLite:
sqlite3 choice.db "DELETE FROM alembic_version;"

# Создать новую миграцию
alembic revision --autogenerate -m "Initial migration"

# Исправить импорты в новой миграции
python fix_migration.py

# Применить миграцию
alembic upgrade head
```

## Полная команда исправления

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
python fix_migration.py && \
alembic upgrade head
```

## Если миграция уже применена частично

```bash
# Откатить миграцию (если возможно)
alembic downgrade -1

# Исправить файл миграции
python fix_migration.py

# Применить снова
alembic upgrade head
```

## Предотвращение проблемы в будущем

Обновите `alembic/env.py` чтобы автоматически добавлять импорты в миграции. Но проще использовать скрипт `fix_migration.py` после каждой генерации миграции.
