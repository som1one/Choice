#!/bin/bash
# Скрипт для запуска Ordering Service

cd /opt/Choice/backend_fastapi
source .venv/bin/activate
export PYTHONPATH="$(pwd)"

echo "=== Stopping Ordering Service ==="

# Убиваем процессы на порту 8005
pkill -9 -f "uvicorn.*8005" 2>/dev/null || true
lsof -ti:8005 | xargs kill -9 2>/dev/null || true

# Ждем освобождения порта
sleep 2

# Проверяем, что порт свободен
if lsof -i:8005 >/dev/null 2>&1; then
    echo "WARNING: Port 8005 still in use!"
    lsof -i:8005
    exit 1
fi

echo "=== Initializing database ==="

# Инициализация БД через init_db (игнорируем предупреждения)
python -c "from services.ordering.database import init_db; init_db()" 2>&1 | grep -v "Warning" || true

echo "=== Starting Ordering Service ==="

# Создаем директорию для логов
mkdir -p logs

# Запуск Ordering Service
echo "Starting Ordering Service on port 8005..."
nohup python -m uvicorn services.ordering.main:app --host 0.0.0.0 --port 8005 > logs/ordering.log 2>&1 &
ORDERING_PID=$!
echo "Ordering Service PID: $ORDERING_PID"

# Ждем запуска сервиса
sleep 3

echo "=== Checking service ==="

# Проверка процесса
if ps -p $ORDERING_PID > /dev/null 2>&1; then
    echo "✓ Process is running (PID: $ORDERING_PID)"
else
    echo "✗ Process failed to start!"
    echo "Last 20 lines of log:"
    tail -20 logs/ordering.log
    exit 1
fi

# Проверка health endpoint
ORDERING_HEALTH=$(curl -s http://localhost:8005/health 2>/dev/null)
if [ -n "$ORDERING_HEALTH" ]; then
    echo "✓ Health check: $ORDERING_HEALTH"
else
    echo "✗ Health endpoint not responding"
    echo "Last 20 lines of log:"
    tail -20 logs/ordering.log
    exit 1
fi

echo ""
echo "=== Ordering Service started successfully ==="
echo "PID: $ORDERING_PID"
echo "Port: 8005"
echo "Health: http://localhost:8005/health"
echo ""
echo "To view logs:"
echo "  tail -f logs/ordering.log"
