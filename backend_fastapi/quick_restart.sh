#!/bin/bash
# Быстрый перезапуск Authentication Service
# Использование: ./quick_restart.sh

cd /opt/Choice/backend_fastapi || exit 1

echo "=== Быстрый перезапуск Authentication Service ==="

# Остановка
echo "1. Остановка процессов..."
lsof -ti:8001 | xargs kill -9 2>/dev/null || fuser -k 8001/tcp 2>/dev/null || pkill -f "uvicorn.*8001"
sleep 2

# Запуск
echo "2. Запуск из .venv..."
source .venv/bin/activate
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
sleep 3

# Проверка
echo "3. Проверка..."
if ps aux | grep "uvicorn.*8001" | grep -v grep > /dev/null; then
    echo "✓ Сервис запущен"
    curl -s http://localhost:8001/health && echo ""
else
    echo "✗ Ошибка запуска! Проверьте логи: tail -50 logs/authentication.log"
    exit 1
fi

echo "=== Готово ==="
