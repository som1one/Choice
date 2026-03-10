# Исправление ошибки Alembic

## Проблема

```
ERROR [alembic.util.messaging] Can't proceed with --autogenerate option; 
environment script /opt/Choice/backend_fastapi/alembic/env.py does not 
provide a MetaData object or sequence of objects to the context.
```

## Решение

### Вариант 1: Использовать скрипт исправления

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
python fix_alembic_env.py
```

### Вариант 2: Исправить вручную

Откройте `alembic/env.py` и найдите функцию `run_migrations_offline()` или `run_migrations_online()`.

**Добавьте в начало файла (после импортов alembic):**

```python
import sys
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
```

**Найдите строку:**
```python
target_metadata = None
```

**Замените на:**
```python
target_metadata = Base.metadata
```

### Вариант 3: Полная замена env.py

Если ничего не помогает, создайте новый `alembic/env.py`:

```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool
from alembic import context
import sys
from pathlib import Path

# Добавить путь к проекту
sys.path.insert(0, str(Path(__file__).parent.parent))

# Импортировать все модели
from services.authentication.models import User
from services.company_service.models import Company
from services.client_service.models import Client
from services.ordering.models import Order
from services.chat.models import Message
from services.review_service.models import Review
from services.category_service.models import Category

# Импортировать Base
from common.database import Base

# this is the Alembic Config object
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# set the target metadata
target_metadata = Base.metadata

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

## После исправления

```bash
# Создать миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграцию
alembic upgrade head

# Проверить статус
alembic current
```

## Полная команда исправления

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
python fix_alembic_env.py && \
alembic revision --autogenerate -m "Initial migration" && \
alembic upgrade head
```
