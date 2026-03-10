#!/bin/bash
# Скрипт для полной остановки ВСЕХ процессов authentication service
# Использование: ./kill_all_auth_processes.sh

cd /opt/Choice/backend_fastapi || exit 1

echo "=== Остановка всех процессов Authentication Service ==="
echo ""

# 1. Найти все процессы uvicorn на порту 8001
echo "1. Поиск процессов на порту 8001..."
PIDS_PORT=$(lsof -ti:8001 2>/dev/null)
if [ -n "$PIDS_PORT" ]; then
    echo "   Найдены процессы по порту: $PIDS_PORT"
fi

# 2. Найти все процессы uvicorn с authentication
echo ""
echo "2. Поиск процессов uvicorn с authentication..."
PIDS_UVICORN=$(ps aux | grep "uvicorn.*authentication" | grep -v grep | awk '{print $2}')
if [ -n "$PIDS_UVICORN" ]; then
    echo "   Найдены процессы: $PIDS_UVICORN"
fi

# 3. Найти все процессы python с authentication
echo ""
echo "3. Поиск процессов python с authentication..."
PIDS_PYTHON=$(ps aux | grep "python.*authentication" | grep -v grep | awk '{print $2}')
if [ -n "$PIDS_PYTHON" ]; then
    echo "   Найдены процессы: $PIDS_PYTHON"
fi

# 4. Объединить все PID
ALL_PIDS=$(echo "$PIDS_PORT $PIDS_UVICORN $PIDS_PYTHON" | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ -z "$ALL_PIDS" ]; then
    echo ""
    echo "✓ Процессы не найдены"
    exit 0
fi

echo ""
echo "4. Остановка процессов: $ALL_PIDS"
for PID in $ALL_PIDS; do
    if kill -0 "$PID" 2>/dev/null; then
        echo "   Убиваем процесс $PID"
        kill -9 "$PID" 2>/dev/null || true
    fi
done

# 5. Подождать
echo ""
echo "5. Ожидание завершения процессов..."
sleep 3

# 6. Проверить, что все остановлено
echo ""
echo "6. Проверка..."
REMAINING=$(ps aux | grep -E "uvicorn.*8001|uvicorn.*authentication" | grep -v grep)
if [ -z "$REMAINING" ]; then
    echo "   ✓ Все процессы остановлены"
else
    echo "   ⚠ Остались процессы:"
    echo "$REMAINING"
fi

# 7. Проверить порт
echo ""
echo "7. Проверка порта 8001..."
if lsof -ti:8001 >/dev/null 2>&1; then
    echo "   ⚠ Порт 8001 все еще занят"
    echo "   Попытка принудительного освобождения..."
    fuser -k 8001/tcp 2>/dev/null || true
    sleep 2
else
    echo "   ✓ Порт 8001 свободен"
fi

echo ""
echo "=== Готово ==="
