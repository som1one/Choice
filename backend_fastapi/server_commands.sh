#!/bin/bash
# Команды для управления Authentication Service на сервере
# Использование: source server_commands.sh или ./server_commands.sh

cd /opt/Choice/backend_fastapi || exit 1

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Остановка всех процессов на порту 8001
stop_auth_service() {
    info "Остановка Authentication Service..."
    PIDS=$(lsof -ti:8001 2>/dev/null || fuser 8001/tcp 2>/dev/null | awk '{print $1}' || ps aux | grep "uvicorn.*8001" | grep -v grep | awk '{print $2}')
    
    if [ -n "$PIDS" ]; then
        for PID in $PIDS; do
            if kill -0 "$PID" 2>/dev/null; then
                info "Останавливаем процесс $PID"
                kill -9 "$PID" 2>/dev/null || true
            fi
        done
        sleep 2
        info "Процессы остановлены"
    else
        warn "Процессы на порту 8001 не найдены"
    fi
}

# 2. Запуск сервиса из .venv
start_auth_service() {
    info "Запуск Authentication Service из .venv..."
    
    # Проверка .venv
    if [ ! -d ".venv" ]; then
        error ".venv не найден!"
        return 1
    fi
    
    # Создание директории для логов
    mkdir -p logs
    
    # Запуск
    source .venv/bin/activate
    PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
    NEW_PID=$!
    
    sleep 3
    
    if ps -p $NEW_PID > /dev/null 2>&1; then
        info "Сервис запущен (PID: $NEW_PID)"
        echo $NEW_PID > /tmp/auth_service.pid
        return 0
    else
        error "Не удалось запустить сервис!"
        error "Проверьте логи: tail -50 logs/authentication.log"
        return 1
    fi
}

# 3. Перезапуск сервиса
restart_auth_service() {
    info "Перезапуск Authentication Service..."
    stop_auth_service
    sleep 2
    start_auth_service
}

# 4. Проверка статуса
status_auth_service() {
    info "Статус Authentication Service:"
    echo ""
    
    # Проверка процессов
    PROCESSES=$(ps aux | grep "uvicorn.*8001" | grep -v grep)
    if [ -n "$PROCESSES" ]; then
        echo "$PROCESSES"
        PID=$(echo "$PROCESSES" | awk '{print $2}' | head -1)
        echo ""
        info "PID: $PID"
    else
        warn "Процесс не найден"
    fi
    
    # Проверка порта
    echo ""
    if lsof -ti:8001 >/dev/null 2>&1; then
        info "Порт 8001 занят"
    else
        warn "Порт 8001 свободен"
    fi
    
    # Проверка health endpoint
    echo ""
    HEALTH=$(curl -s http://localhost:8001/health 2>/dev/null)
    if [ -n "$HEALTH" ]; then
        info "Health check: $HEALTH"
    else
        error "Health endpoint не отвечает"
    fi
}

# 5. Просмотр логов
logs_auth_service() {
    if [ -f "logs/authentication.log" ]; then
        if [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
            tail -f logs/authentication.log
        else
            tail -${1:-50} logs/authentication.log
        fi
    else
        error "Файл логов не найден"
    fi
}

# 6. Проверка пользователя в БД
check_user() {
    info "Проверка пользователя в БД..."
    source .venv/bin/activate
    python3 check_and_create_user.py
}

# 7. Тестовый запрос на login
test_login() {
    EMAIL=${1:-"cp@gmail.com"}
    PASSWORD=${2:-"qwerty123"}
    
    info "Тестовый запрос на login для $EMAIL..."
    echo ""
    
    RESPONSE=$(curl -s -X POST http://localhost:8001/api/auth/login \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" 2>/dev/null)
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/api/auth/login \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" 2>/dev/null)
    
    echo "HTTP код: $CODE"
    echo "Ответ: $RESPONSE"
    echo ""
    
    if [ "$CODE" = "200" ]; then
        info "✓ Логин успешен!"
    elif [ "$CODE" = "404" ]; then
        error "✗ 404 Not Found - проверьте маршрутизацию"
    elif [ "$CODE" = "401" ]; then
        warn "⚠ 401 Unauthorized - неверный пароль"
    else
        warn "⚠ Неожиданный код ответа: $CODE"
    fi
}

# 8. Полная диагностика
diagnose() {
    info "=== Полная диагностика Authentication Service ==="
    echo ""
    status_auth_service
    echo ""
    check_user
    echo ""
    test_login
}

# 9. Показать помощь
show_help() {
    echo "Доступные команды:"
    echo ""
    echo "  stop_auth_service      - Остановить сервис"
    echo "  start_auth_service     - Запустить сервис"
    echo "  restart_auth_service   - Перезапустить сервис"
    echo "  status_auth_service    - Показать статус"
    echo "  logs_auth_service      - Показать логи (по умолчанию 50 строк)"
    echo "  logs_auth_service -f   - Показать логи в реальном времени"
    echo "  check_user             - Проверить/создать пользователя"
    echo "  test_login [email] [pass] - Тестовый запрос на login"
    echo "  diagnose               - Полная диагностика"
    echo ""
    echo "Примеры:"
    echo "  source server_commands.sh"
    echo "  restart_auth_service"
    echo "  logs_auth_service -f"
    echo "  test_login cp@gmail.com qwerty123"
}

# Если скрипт запущен напрямую (не через source)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-help}" in
        start)
            start_auth_service
            ;;
        stop)
            stop_auth_service
            ;;
        restart)
            restart_auth_service
            ;;
        status)
            status_auth_service
            ;;
        logs)
            logs_auth_service "${@:2}"
            ;;
        check-user)
            check_user
            ;;
        test-login)
            test_login "${2}" "${3}"
            ;;
        diagnose)
            diagnose
            ;;
        *)
            show_help
            ;;
    esac
fi
