# Решение проблем при запуске сервисов

## Проблема: Сервисы не запускаются (Killed)

Если сервисы были убиты (Killed), проверьте логи и перезапустите:

### Шаг 1: Проверка логов

```bash
# Проверка логов Authentication Service
tail -50 logs/authentication.log

# Проверка логов Company Service
tail -50 logs/company_service.log
```

### Шаг 2: Проверка портов

```bash
# Проверка, заняты ли порты
lsof -i:8001
lsof -i:8003

# Если порты заняты, освободите их
lsof -ti:8001 | xargs kill -9 2>/dev/null
lsof -ti:8003 | xargs kill -9 2>/dev/null
```

### Шаг 3: Проверка БД

```bash
# Проверка подключения к БД
python -c "from common.database import engine; engine.connect(); print('DB OK')"
```

### Шаг 4: Запуск сервисов вручную (для отладки)

```bash
# Запуск Authentication Service в терминале (чтобы видеть ошибки)
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
PYTHONPATH="$(pwd)" python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001

# В другом терминале - Company Service
PYTHONPATH="$(pwd)" python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003
```

### Шаг 5: Запуск в фоне (после проверки)

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Убедитесь, что порты свободны
lsof -ti:8001 | xargs kill -9 2>/dev/null || true
lsof -ti:8003 | xargs kill -9 2>/dev/null || true
sleep 2

# Запуск с перенаправлением ошибок в логи
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 > logs/authentication.log 2>&1 &
sleep 2

PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 > logs/company_service.log 2>&1 &
sleep 3

# Проверка
ps aux | grep "uvicorn.*800" | grep -v grep
curl http://localhost:8001/health
curl http://localhost:8003/health
```

## Типичные ошибки и решения

### Ошибка: "ModuleNotFoundError"
```bash
# Убедитесь, что PYTHONPATH установлен
export PYTHONPATH="/opt/Choice/backend_fastapi"
```

### Ошибка: "Port already in use"
```bash
# Найдите и убейте процесс
lsof -ti:8001 | xargs kill -9
lsof -ti:8003 | xargs kill -9
```

### Ошибка: "Database connection failed"
```bash
# Проверьте .env файл
cat .env | grep DATABASE_URL

# Проверьте подключение
python -c "from common.database import engine; engine.connect()"
```

### Ошибка: "Table does not exist"
```bash
# Инициализируйте БД
python -c "from services.authentication.database import init_db; init_db()"
python -c "from services.company_service.database import init_db; init_db()"
```

## Полная команда для перезапуска

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
export PYTHONPATH="$(pwd)" && \
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001" || true && \
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003" || true && \
sleep 3 && \
mkdir -p logs && \
nohup python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 > logs/authentication.log 2>&1 & \
sleep 2 && \
nohup python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 > logs/company_service.log 2>&1 & \
sleep 5 && \
echo "=== Checking services ===" && \
ps aux | grep "uvicorn.*800" | grep -v grep && \
echo "=== Health checks ===" && \
curl -s http://localhost:8001/health || echo "Auth service failed" && \
curl -s http://localhost:8003/health || echo "Company service failed" && \
echo "=== Recent logs ===" && \
tail -10 logs/authentication.log && \
tail -10 logs/company_service.log
```
