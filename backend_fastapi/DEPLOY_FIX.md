# Решение проблем при развертке

## Проблема 1: Конфликт локальных изменений

Если при `git pull` возникает ошибка о локальных изменениях:

```bash
# Вариант 1: Сохранить локальные изменения и применить их после pull
git stash
git pull origin main
git stash pop

# Вариант 2: Отменить локальные изменения (если они не нужны)
git checkout -- backend_fastapi/check_auth_service.sh
git checkout -- backend_fastapi/restart_auth_service.sh
git pull origin main

# Вариант 3: Принудительно обновить (перезаписать локальные изменения)
git fetch origin
git reset --hard origin/main
```

## Проблема 2: SQLite не поддерживает ARRAY типы

Модель Company использует PostgreSQL ARRAY, который не поддерживается в SQLite.

### Решение: Использовать PostgreSQL или исправить модель

**Вариант A: Использовать PostgreSQL (рекомендуется)**

Убедитесь, что в `.env` файле указан PostgreSQL:

```bash
DATABASE_URL=postgresql://user:password@localhost:5432/choice_db
```

Затем инициализируйте БД:

```bash
python -c "from services.company_service.database import init_db; init_db()"
```

**Вариант B: Исправить модель для SQLite (временное решение)**

Если нужно использовать SQLite, нужно изменить модель Company, заменив ARRAY на JSON или String.

## Полная команда развертки с исправлениями

```bash
cd /opt/Choice/backend_fastapi

# Решение конфликта локальных изменений
git stash
git pull origin main
git stash pop

# Активация окружения
source .venv/bin/activate

# Проверка DATABASE_URL в .env
cat .env | grep DATABASE_URL

# Если используется SQLite, переключитесь на PostgreSQL или исправьте модель
# Если используется PostgreSQL, инициализируйте БД:
python -c "from services.company_service.database import init_db; init_db()" 2>&1 | grep -v "Warning" || echo "DB initialized"

# Остановка старых процессов
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001"
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003"
sleep 2

# Запуск сервисов
mkdir -p logs
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 --reload > logs/company_service.log 2>&1 &

# Ожидание запуска
sleep 5

# Проверка статуса
echo "Checking services..."
ps aux | grep "uvicorn.*800" | grep -v grep
curl -s http://localhost:8001/health || echo "Auth service not responding"
curl -s http://localhost:8003/health || echo "Company service not responding"

# Просмотр логов при ошибках
echo "=== Authentication Service Logs ==="
tail -20 logs/authentication.log
echo "=== Company Service Logs ==="
tail -20 logs/company_service.log
```
