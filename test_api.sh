#!/bin/bash
# Расширенный тест API с проверкой основных эндпоинтов

BASE_URL="http://localhost"
echo "=== Расширенное тестирование API ==="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки сервиса
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null)
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$url" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ OK${NC} (HTTP $http_code)"
        if [ ! -z "$body" ] && [ "$body" != "null" ]; then
            echo "  Response: $(echo "$body" | head -c 100)..."
        fi
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "${YELLOW}⚠ Auth Required${NC} (HTTP $http_code) - это нормально для защищенных эндпоинтов"
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $http_code)"
        if [ ! -z "$body" ]; then
            echo "  Error: $(echo "$body" | head -c 200)"
        fi
    fi
    echo ""
}

echo "=== 1. Проверка Health эндпоинтов ==="
test_endpoint "Auth Health" "GET" "$BASE_URL:8001/health"
test_endpoint "Client Health" "GET" "$BASE_URL:8002/health"
test_endpoint "Company Health" "GET" "$BASE_URL:8003/health"
test_endpoint "Category Health" "GET" "$BASE_URL:8004/health"
test_endpoint "Ordering Health" "GET" "$BASE_URL:8005/health"
test_endpoint "Chat Health" "GET" "$BASE_URL:8006/health"
test_endpoint "Review Health" "GET" "$BASE_URL:8007/health"
test_endpoint "File Health" "GET" "$BASE_URL:8008/health"

echo "=== 2. Проверка корневых эндпоинтов ==="
test_endpoint "Auth Root" "GET" "$BASE_URL:8001/"
test_endpoint "Client Root" "GET" "$BASE_URL:8002/"
test_endpoint "Company Root" "GET" "$BASE_URL:8003/"
test_endpoint "Category Root" "GET" "$BASE_URL:8004/"
test_endpoint "Ordering Root" "GET" "$BASE_URL:8005/"
test_endpoint "Chat Root" "GET" "$BASE_URL:8006/"
test_endpoint "Review Root" "GET" "$BASE_URL:8007/"
test_endpoint "File Root" "GET" "$BASE_URL:8008/"

echo "=== 3. Проверка Swagger документации ==="
test_endpoint "Auth Docs" "GET" "$BASE_URL:8001/docs"
test_endpoint "Client Docs" "GET" "$BASE_URL:8002/docs"
test_endpoint "Company Docs" "GET" "$BASE_URL:8003/docs"

echo "=== 4. Тест регистрации (без токена) ==="
test_endpoint "Register Client" "POST" "$BASE_URL:8001/api/auth/register" '{"email":"test@test.com","password":"123456","user_type":"Client","name":"Test User"}'

echo "=== Тест завершен ==="
