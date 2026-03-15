#!/bin/bash
# Скрипт для правильного перезапуска сервисов

cd /opt/Choice/backend_fastapi
source .venv/bin/activate
export PYTHONPATH="$(pwd)"

echo "=== Stopping all services ==="

# Убиваем ВСЕ процессы uvicorn на нужных портах
pkill -9 -f "uvicorn.*8001" 2>/dev/null || true
pkill -9 -f "uvicorn.*8003" 2>/dev/null || true
pkill -9 -f "uvicorn.*8005" 2>/dev/null || true
lsof -ti:8001 | xargs kill -9 2>/dev/null || true
lsof -ti:8003 | xargs kill -9 2>/dev/null || true
lsof -ti:8005 | xargs kill -9 2>/dev/null || true

# Ждем освобождения портов
sleep 3

# Проверяем, что порты свободны
if lsof -i:8001 >/dev/null 2>&1; then
    echo "WARNING: Port 8001 still in use!"
    lsof -i:8001
fi

if lsof -i:8003 >/dev/null 2>&1; then
    echo "WARNING: Port 8003 still in use!"
    lsof -i:8003
fi

if lsof -i:8005 >/dev/null 2>&1; then
    echo "WARNING: Port 8005 still in use!"
    lsof -i:8005
fi

echo "=== Initializing database ==="

# Инициализация БД через init_db (игнорируем предупреждения)
python -c "from services.authentication.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true
python -c "from services.company_service.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true
python -c "from services.ordering.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true

echo "=== Starting services ==="

# Создаем директорию для логов
mkdir -p logs

# Запуск Authentication Service
echo "Starting Authentication Service on port 8001..."
nohup python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 > logs/authentication.log 2>&1 &
AUTH_PID=$!
echo "Authentication Service PID: $AUTH_PID"

# Ждем немного перед запуском следующего сервиса
sleep 2

# Запуск Company Service
echo "Starting Company Service on port 8003..."
nohup python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 > logs/company_service.log 2>&1 &
COMPANY_PID=$!
echo "Company Service PID: $COMPANY_PID"

# Ждем немного перед запуском следующего сервиса
sleep 2

# Запуск Ordering Service
echo "Starting Ordering Service on port 8005..."
nohup python -m uvicorn services.ordering.main:app --host 0.0.0.0 --port 8005 > logs/ordering.log 2>&1 &
ORDERING_PID=$!
echo "Ordering Service PID: $ORDERING_PID"

# Ждем запуска сервисов
sleep 5

echo "=== Checking services ==="

# Проверка процессов
ps aux | grep "uvicorn.*800" | grep -v grep

echo ""
echo "=== Health checks ==="

# Проверка health endpoints
AUTH_HEALTH=$(curl -s http://localhost:8001/health 2>/dev/null)
if [ -n "$AUTH_HEALTH" ]; then
    echo "✓ Authentication Service: $AUTH_HEALTH"
else
    echo "✗ Authentication Service: FAILED"
    echo "Last 20 lines of log:"
    tail -20 logs/authentication.log
fi

COMPANY_HEALTH=$(curl -s http://localhost:8003/health 2>/dev/null)
if [ -n "$COMPANY_HEALTH" ]; then
    echo "✓ Company Service: $COMPANY_HEALTH"
else
    echo "✗ Company Service: FAILED"
    echo "Last 20 lines of log:"
    tail -20 logs/company_service.log
fi

ORDERING_HEALTH=$(curl -s http://localhost:8005/health 2>/dev/null)
if [ -n "$ORDERING_HEALTH" ]; then
    echo "✓ Ordering Service: $ORDERING_HEALTH"
else
    echo "✗ Ordering Service: FAILED"
    echo "Last 20 lines of log:"
    tail -20 logs/ordering.log
fi

echo ""
echo "=== Service PIDs ==="
echo "Authentication Service: $AUTH_PID"
echo "Company Service: $COMPANY_PID"
echo "Ordering Service: $ORDERING_PID"
echo ""
echo "To view logs:"
echo "  tail -f logs/authentication.log"
echo "  tail -f logs/company_service.log"
echo "  tail -f logs/ordering.log"