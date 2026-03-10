#!/bin/bash

# Скрипт для перезапуска сервиса аутентификации
# Использование: ./restart_auth_service.sh

cd /opt/Choice/backend_fastapi || exit 1

echo "=== Перезапуск Authentication Service ==="
echo ""

# 1. Найти и убить ВСЕ процессы uvicorn на порту 8001
echo "1. Поиск процессов на порту 8001..."
PIDS=$(lsof -ti:8001 2>/dev/null || fuser 8001/tcp 2>/dev/null | awk '{print $1}' || ps aux | grep "uvicorn.*8001" | grep -v grep | awk '{print $2}')

if [ -n "$PIDS" ]; then
    echo "   Найдены процессы: $PIDS"
    echo "   Остановка процессов..."
    for PID in $PIDS; do
        if kill -0 "$PID" 2>/dev/null; then
            echo "   Убиваем процесс $PID"
            kill -9 "$PID" 2>/dev/null || true
        fi
    done
    sleep 2
else
    echo "   Процессы на порту 8001 не найдены"
fi

# 2. Проверить, что порт освободился
echo ""
echo "2. Проверка освобождения порта 8001..."
for i in {1..5}; do
    if ! lsof -ti:8001 >/dev/null 2>&1 && ! fuser 8001/tcp >/dev/null 2>&1; then
        echo "   Порт 8001 свободен"
        break
    fi
    echo "   Ожидание освобождения порта... ($i/5)"
    sleep 1
done

# 3. Проверить наличие .venv
if [ ! -d ".venv" ]; then
    echo "ERROR: .venv не найден!"
    exit 1
fi

# 4. Создать директорию для логов
mkdir -p logs

# 5. Запустить сервис из .venv
echo ""
echo "3. Запуск сервиса из .venv..."
source .venv/bin/activate
PYTHONPATH="$(pwd)" .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
NEW_PID=$!
echo "   Запущен процесс с PID: $NEW_PID"

# 6. Подождать запуска
echo ""
echo "4. Ожидание запуска сервиса..."
sleep 3

# 7. Проверить статус
echo ""
echo "5. Проверка статуса..."
if ps -p $NEW_PID > /dev/null 2>&1; then
    echo "   ✓ Процесс работает (PID: $NEW_PID)"
else
    echo "   ✗ Процесс не запустился!"
    echo "   Проверьте логи: tail -50 logs/authentication.log"
    exit 1
fi

# 8. Проверить доступность
echo ""
echo "6. Проверка доступности сервиса..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/health 2>/dev/null || echo "000")
if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "   ✓ Сервис доступен (health check: $HEALTH_RESPONSE)"
else
    echo "   ⚠ Сервис не отвечает на health check (код: $HEALTH_RESPONSE)"
    echo "   Проверьте логи: tail -50 logs/authentication.log"
fi

# 9. Показать последние строки лога
echo ""
echo "7. Последние строки лога:"
tail -10 logs/authentication.log

echo ""
echo "=== Готово ==="
echo "Логи: tail -f logs/authentication.log"
echo "Swagger UI: http://$(hostname -I | awk '{print $1}'):8001/docs"
