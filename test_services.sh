#!/bin/bash
# Скрипт для тестирования всех сервисов

BASE_URL="http://localhost"
echo "=== Тестирование всех сервисов ==="
echo ""

# Функция для проверки сервиса
check_service() {
    local name=$1
    local port=$2
    local endpoint=$3
    
    echo -n "Testing $name (port $port)... "
    response=$(curl -s -w "\n%{http_code}" "$BASE_URL:$port$endpoint" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo "✓ OK"
        echo "  Response: $body"
    else
        echo "✗ FAILED (HTTP $http_code)"
        if [ ! -z "$body" ]; then
            echo "  Response: $body"
        fi
    fi
    echo ""
}

# Проверка всех сервисов
check_service "Authentication Service" "8001" "/health"
check_service "Client Service" "8002" "/health"
check_service "Company Service" "8003" "/health"
check_service "Category Service" "8004" "/health"
check_service "Ordering Service" "8005" "/health"
check_service "Chat Service" "8006" "/health"
check_service "Review Service" "8007" "/health"
check_service "File Service" "8008" "/health"

echo "=== Проверка корневых эндпоинтов ==="
echo ""

check_service "Authentication Service" "8001" "/"
check_service "Client Service" "8002" "/"
check_service "Company Service" "8003" "/"
check_service "Category Service" "8004" "/"
check_service "Ordering Service" "8005" "/"
check_service "Chat Service" "8006" "/"
check_service "Review Service" "8007" "/"
check_service "File Service" "8008" "/"

echo "=== Тест завершен ==="
