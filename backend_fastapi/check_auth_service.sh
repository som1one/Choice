#!/bin/bash

# Скрипт для диагностики сервиса аутентификации
# Использование: ./check_auth_service.sh

cd /opt/Choice/backend_fastapi || exit 1

echo "=== Диагностика Authentication Service ==="
echo ""

# 1. Проверка процессов
echo "1. Проверка процессов uvicorn на порту 8001:"
PROCESSES=$(ps aux | grep "uvicorn.*8001" | grep -v grep)
if [ -n "$PROCESSES" ]; then
    echo "$PROCESSES"
    PID=$(echo "$PROCESSES" | awk '{print $2}' | head -1)
    echo "   PID: $PID"
else
    echo "   ✗ Процесс не найден!"
    exit 1
fi

# 2. Проверка порта
echo ""
echo "2. Проверка порта 8001:"
if lsof -ti:8001 >/dev/null 2>&1 || fuser 8001/tcp >/dev/null 2>&1; then
    echo "   ✓ Порт 8001 занят"
else
    echo "   ✗ Порт 8001 свободен!"
fi

# 3. Проверка health endpoint
echo ""
echo "3. Проверка health endpoint:"
HEALTH=$(curl -s http://localhost:8001/health 2>/dev/null)
if [ -n "$HEALTH" ]; then
    echo "   Ответ: $HEALTH"
    if echo "$HEALTH" | grep -q "healthy"; then
        echo "   ✓ Health check OK"
    else
        echo "   ⚠ Health check вернул неожиданный ответ"
    fi
else
    echo "   ✗ Health endpoint не отвечает!"
fi

# 4. Проверка root endpoint
echo ""
echo "4. Проверка root endpoint:"
ROOT=$(curl -s http://localhost:8001/ 2>/dev/null)
if [ -n "$ROOT" ]; then
    echo "   Ответ: $ROOT"
    echo "   ✓ Root endpoint работает"
else
    echo "   ✗ Root endpoint не отвечает!"
fi

# 5. Проверка Swagger docs
echo ""
echo "5. Проверка Swagger docs:"
DOCS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/docs 2>/dev/null)
if [ "$DOCS_CODE" = "200" ]; then
    echo "   ✓ Swagger UI доступен (код: $DOCS_CODE)"
else
    echo "   ⚠ Swagger UI недоступен (код: $DOCS_CODE)"
fi

# 6. Проверка маршрута /api/auth/login (OPTIONS для проверки существования)
echo ""
echo "6. Проверка маршрута /api/auth/login:"
LOGIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS http://localhost:8001/api/auth/login 2>/dev/null)
if [ "$LOGIN_CODE" = "200" ] || [ "$LOGIN_CODE" = "405" ] || [ "$LOGIN_CODE" = "404" ]; then
    echo "   Маршрут существует (код: $LOGIN_CODE)"
    if [ "$LOGIN_CODE" = "404" ]; then
        echo "   ⚠ ВНИМАНИЕ: Маршрут возвращает 404!"
    fi
else
    echo "   ✗ Маршрут не отвечает (код: $LOGIN_CODE)"
fi

# 7. Проверка базы данных
echo ""
echo "7. Проверка базы данных:"
if [ -f "choice.db" ]; then
    echo "   ✓ Файл БД существует: choice.db"
    DB_SIZE=$(du -h choice.db | cut -f1)
    echo "   Размер: $DB_SIZE"
    
    # Попытка проверить подключение через Python
    echo ""
    echo "   Проверка подключения к БД..."
    source .venv/bin/activate
    PYTHON_CHECK=$(python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/Choice/backend_fastapi')
try:
    from common.database import engine
    with engine.connect() as conn:
        result = conn.execute("SELECT 1")
        print("OK")
except Exception as e:
    print(f"ERROR: {e}")
EOF
)
    if [ "$PYTHON_CHECK" = "OK" ]; then
        echo "   ✓ Подключение к БД работает"
    else
        echo "   ✗ Ошибка подключения: $PYTHON_CHECK"
    fi
    
    # Проверка наличия таблицы Users
    echo ""
    echo "   Проверка таблицы Users..."
    TABLE_CHECK=$(python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/Choice/backend_fastapi')
try:
    from common.database import engine
    from sqlalchemy import inspect
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    if "Users" in tables:
        print("OK")
    else:
        print(f"NOT_FOUND. Доступные таблицы: {', '.join(tables)}")
except Exception as e:
    print(f"ERROR: {e}")
EOF
)
    if [ "$TABLE_CHECK" = "OK" ]; then
        echo "   ✓ Таблица Users существует"
        
        # Проверка наличия пользователя cp@gmail.com
        echo ""
        echo "   Проверка пользователя cp@gmail.com..."
        USER_CHECK=$(python3 << 'EOF'
import sys
sys.path.insert(0, '/opt/Choice/backend_fastapi')
try:
    from common.database import SessionLocal
    from services.authentication.models import User
    db = SessionLocal()
    user = db.query(User).filter(User.email == "cp@gmail.com").first()
    if user:
        print(f"OK: ID={user.id}, email={user.email}, user_type={user.user_type}")
    else:
        print("NOT_FOUND")
    db.close()
except Exception as e:
    print(f"ERROR: {e}")
EOF
)
        if echo "$USER_CHECK" | grep -q "OK"; then
            echo "   ✓ Пользователь найден: $USER_CHECK"
        else
            echo "   ✗ Пользователь cp@gmail.com не найден в БД"
            echo "   $USER_CHECK"
        fi
    else
        echo "   ✗ Таблица Users не найдена"
        echo "   $TABLE_CHECK"
    fi
else
    echo "   ✗ Файл БД не найден!"
    echo "   Проверьте настройки DATABASE_URL в .env или переменных окружения"
fi

# 8. Проверка логов на ошибки
echo ""
echo "8. Последние ошибки в логах:"
if [ -f "logs/authentication.log" ]; then
    ERRORS=$(tail -50 logs/authentication.log | grep -i "error\|exception\|traceback\|failed" | tail -5)
    if [ -n "$ERRORS" ]; then
        echo "   Найдены ошибки:"
        echo "$ERRORS" | sed 's/^/   /'
    else
        echo "   ✓ Ошибок в последних 50 строках не найдено"
    fi
    echo ""
    echo "   Последние 10 строк лога:"
    tail -10 logs/authentication.log | sed 's/^/   /'
else
    echo "   ⚠ Файл логов не найден"
fi

# 9. Тестовый запрос на login
echo ""
echo "9. Тестовый запрос на /api/auth/login:"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cp@gmail.com","password":"qwerty123"}' 2>/dev/null)
LOGIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cp@gmail.com","password":"qwerty123"}' 2>/dev/null)

echo "   HTTP код: $LOGIN_CODE"
echo "   Ответ: $LOGIN_RESPONSE"

if [ "$LOGIN_CODE" = "200" ]; then
    echo "   ✓ Логин успешен!"
elif [ "$LOGIN_CODE" = "404" ]; then
    echo "   ✗ 404 Not Found - проверьте маршрутизацию"
elif [ "$LOGIN_CODE" = "401" ]; then
    echo "   ⚠ 401 Unauthorized - неверный пароль или пользователь заблокирован"
else
    echo "   ⚠ Неожиданный код ответа"
fi

echo ""
echo "=== Диагностика завершена ==="
