# Финальные команды для развертки на сервере

## Шаг 1: Получение изменений из Git

```bash
cd /opt/Choice/backend_fastapi

# Сохранить локальные изменения (если есть)
git stash

# Получить последние изменения
git pull origin main

# Применить сохраненные изменения (если нужно)
git stash pop
```

## Шаг 2: Активация окружения

```bash
source .venv/bin/activate
export PYTHONPATH="$(pwd)"
```

## Шаг 3: Настройка Alembic (первый раз)

```bash
# Сделать скрипт исполняемым
chmod +x setup_alembic.sh

# Запустить настройку Alembic
./setup_alembic.sh

# Или вручную:
# Инициализация Alembic (если еще не инициализирован)
if [ ! -d "alembic" ]; then
    alembic init alembic
fi

# Обновить alembic/env.py для импорта всех моделей
# Отредактируйте alembic/env.py и добавьте импорты:
# from services.authentication.models import User
# from services.company_service.models import Company
# from services.client_service.models import Client
# и другие модели

# Создать первую миграцию
alembic revision --autogenerate -m "Initial migration"

# Применить миграции
alembic upgrade head
```

## Шаг 4: Перезапуск сервисов

```bash
# Сделать скрипт исполняемым
chmod +x restart_services.sh

# Запустить перезапуск
./restart_services.sh
```

## Шаг 5: Проверка

```bash
# Проверка процессов
ps aux | grep "uvicorn.*800" | grep -v grep

# Проверка health endpoints
curl http://localhost:8001/health
curl http://localhost:8003/health

# Просмотр логов
tail -20 logs/authentication.log
tail -20 logs/company_service.log
```

## Полная команда (все в одной строке)

```bash
cd /opt/Choice/backend_fastapi && \
git stash && \
git pull origin main && \
source .venv/bin/activate && \
export PYTHONPATH="$(pwd)" && \
chmod +x restart_services.sh setup_alembic.sh && \
./restart_services.sh
```

## Настройка Alembic (детально)

### 1. Инициализация (если еще не сделано)

```bash
alembic init alembic
```

### 2. Обновление alembic.ini

Скрипт `setup_alembic.sh` автоматически обновит `alembic.ini` с правильным DATABASE_URL.

Или вручную отредактируйте `alembic.ini`:
```ini
sqlalchemy.url = postgresql://user:password@localhost:5432/choice_db
# или для SQLite:
# sqlalchemy.url = sqlite:///./choice.db
```

### 3. Обновление alembic/env.py

Откройте `alembic/env.py` и добавьте импорты всех моделей:

```python
# В начале файла, после существующих импортов
import sys
from pathlib import Path

# Добавить путь к проекту
sys.path.insert(0, str(Path(__file__).parent.parent))

# Импортировать все модели
from services.authentication.models import User
from services.company_service.models import Company
from services.client_service.models import Client
from services.ordering.models import Order
# ... другие модели

# В функции run_migrations_online() убедитесь, что:
from common.database import Base
target_metadata = Base.metadata
```

### 4. Создание и применение миграций

```bash
# Создать миграцию на основе текущих моделей
alembic revision --autogenerate -m "Initial migration"

# Применить миграцию
alembic upgrade head
```

### 5. Проверка статуса миграций

```bash
# Текущая версия
alembic current

# История миграций
alembic history
```

## Автоматическое применение миграций при развертке

Добавьте в `restart_services.sh` перед запуском сервисов:

```bash
# Применить миграции
if [ -d "alembic" ]; then
    echo "Applying database migrations..."
    alembic upgrade head
fi
```

## Решение проблем

### Проблема: "Target database is not up to date"
```bash
alembic upgrade head
```

### Проблема: "Can't locate revision"
```bash
alembic stamp head
```

### Проблема: Конфликт миграций
```bash
# Просмотр истории
alembic history

# Откат на нужную версию
alembic downgrade <revision_id>
```

## Быстрый перезапуск (без миграций)

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
export PYTHONPATH="$(pwd)" && \
./restart_services.sh
```
