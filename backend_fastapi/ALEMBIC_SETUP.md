# Настройка Alembic для миграций БД

## Инициализация Alembic

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Инициализация Alembic (если еще не инициализирован)
alembic init alembic
```

## Настройка alembic.ini

После инициализации нужно обновить `alembic.ini`:

1. Откройте `alembic/alembic.ini`
2. Найдите строку `sqlalchemy.url = driver://user:pass@localhost/dbname`
3. Замените на ваш DATABASE_URL из `.env` или используйте переменную окружения

Или используйте скрипт:

```bash
bash setup_alembic.sh
```

## Настройка env.py для импорта моделей

Отредактируйте `alembic/env.py`:

```python
# В начале файла добавьте импорты всех моделей
from services.authentication.models import User
from services.company_service.models import Company
from services.client_service.models import Client
# ... другие модели

# В функции run_migrations_online() обновите target_metadata:
target_metadata = Base.metadata
```

## Создание первой миграции

```bash
# Создание миграции на основе текущих моделей
alembic revision --autogenerate -m "Initial migration"

# Применение миграции
alembic upgrade head
```

## Команды Alembic

```bash
# Просмотр текущей версии
alembic current

# Просмотр истории миграций
alembic history

# Применение всех миграций
alembic upgrade head

# Откат на одну миграцию назад
alembic downgrade -1

# Откат всех миграций
alembic downgrade base

# Создание новой миграции
alembic revision -m "Description of changes"
```

## Интеграция в процесс развертки

Добавьте в скрипт развертки:

```bash
# После git pull и перед запуском сервисов
alembic upgrade head
```

## Автоматическое применение миграций при старте

Можно добавить в `main.py` каждого сервиса:

```python
@app.on_event("startup")
async def startup_event():
    # Применение миграций
    import subprocess
    subprocess.run(["alembic", "upgrade", "head"], check=False)
    
    # Остальной код запуска
    ...
```

## Решение проблем

### Ошибка: "Target database is not up to date"
```bash
# Просмотрите текущую версию
alembic current

# Примените миграции
alembic upgrade head
```

### Ошибка: "Can't locate revision identified by 'xxxx'"
```bash
# Пометьте текущее состояние БД как актуальное
alembic stamp head
```

### Конфликт миграций
```bash
# Просмотрите историю
alembic history

# Откатитесь на нужную версию
alembic downgrade <revision_id>
```
