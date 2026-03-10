# Команды для развертки на сервере (с исправлениями)

## Шаг 1: Решение конфликта локальных изменений

```bash
cd /opt/Choice/backend_fastapi

# Сохранить локальные изменения (если нужны)
git stash

# Или отменить локальные изменения (если не нужны)
git checkout -- backend_fastapi/check_auth_service.sh
git checkout -- backend_fastapi/restart_auth_service.sh

# Получить последние изменения
git pull origin main
```

## Шаг 2: Активация окружения и проверка БД

```bash
source .venv/bin/activate

# Проверить тип БД
python -c "from common.database import engine; print('DB type:', engine.url.drivername)"
```

## Шаг 3: Инициализация БД

```bash
# Инициализация БД для всех сервисов
python -c "from services.authentication.database import init_db; init_db()"
python -c "from services.company_service.database import init_db; init_db()"
```

Если видите ошибку про ARRAY в SQLite - это нормально, модель теперь автоматически использует JSON для SQLite.

## Шаг 4: Остановка старых сервисов

```bash
# Остановка всех сервисов
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001"
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003"
sleep 2
```

## Шаг 5: Запуск сервисов

```bash
# Создать директорию для логов
mkdir -p logs

# Запуск Authentication Service
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &

# Запуск Company Service
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 --reload > logs/company_service.log 2>&1 &

# Подождать запуска
sleep 5
```

## Шаг 6: Проверка статуса

```bash
# Проверка процессов
ps aux | grep "uvicorn.*800" | grep -v grep

# Проверка портов
lsof -i:8001
lsof -i:8003

# Проверка health endpoints
curl http://localhost:8001/health
curl http://localhost:8003/health
```

## Шаг 7: Просмотр логов (если есть ошибки)

```bash
# Логи Authentication Service
tail -50 logs/authentication.log

# Логи Company Service
tail -50 logs/company_service.log
```

## Шаг 8: Тест регистрации компании

```bash
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testcompany@example.com",
    "name": "Тестовая Компания",
    "password": "Test1234!",
    "street": "Ленина",
    "city": "Москва",
    "phone_number": "1234567890",
    "type": "Company"
  }'
```

## Полная команда (все в одной строке)

```bash
cd /opt/Choice/backend_fastapi && \
git stash && \
git pull origin main && \
source .venv/bin/activate && \
python -c "from services.authentication.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true && \
python -c "from services.company_service.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true && \
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001" && \
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003" && \
sleep 2 && \
mkdir -p logs && \
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 & \
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 --reload > logs/company_service.log 2>&1 & \
sleep 5 && \
echo "=== Services Status ===" && \
ps aux | grep "uvicorn.*800" | grep -v grep && \
echo "=== Health Checks ===" && \
curl -s http://localhost:8001/health && echo && \
curl -s http://localhost:8003/health && echo
```

## Что было исправлено

1. ✅ **Модель Company теперь совместима с SQLite** - использует JSON вместо ARRAY для SQLite
2. ✅ **Исправлена регистрация компании** - добавлены дефолтные значения для обязательных полей
3. ✅ **Улучшена обработка ошибок** - более детальное логирование

## Если что-то пошло не так

1. Проверьте логи: `tail -50 logs/authentication.log` и `tail -50 logs/company_service.log`
2. Проверьте, что БД доступна: `python -c "from common.database import engine; engine.connect()"`
3. Проверьте, что порты свободны: `lsof -i:8001` и `lsof -i:8003`
4. Перезапустите сервисы вручную по шагам выше
