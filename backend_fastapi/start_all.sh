#!/bin/bash

echo "Starting all FastAPI services..."
echo ""

# Функция для запуска сервиса
start_service() {
    local name=$1
    local port=$2
    local path=$3
    
    echo "Starting $name on port $port..."
    cd "$path" || exit
    uvicorn main:app --port "$port" --reload > "../logs/${name,,}.log" 2>&1 &
    cd - || exit
    sleep 1
}

# Создать директорию для логов
mkdir -p logs

# Запуск всех сервисов
start_service "Authentication" 8001 "services/authentication"
start_service "Client" 8002 "services/client_service"
start_service "Company" 8003 "services/company_service"
start_service "Category" 8004 "services/category_service"
start_service "Ordering" 8005 "services/ordering"
start_service "Chat" 8006 "services/chat"
start_service "Review" 8007 "services/review_service"
start_service "File" 8008 "services/file_service"

echo ""
echo "All services started!"
echo ""
echo "Check Swagger UI:"
echo "- Authentication: http://localhost:8001/docs"
echo "- Client: http://localhost:8002/docs"
echo "- Company: http://localhost:8003/docs"
echo "- Category: http://localhost:8004/docs"
echo "- Ordering: http://localhost:8005/docs"
echo "- Chat: http://localhost:8006/docs"
echo "- Review: http://localhost:8007/docs"
echo "- File: http://localhost:8008/docs"
echo ""
echo "Logs are in logs/ directory"
echo ""
echo "Press Ctrl+C to stop all services"

# Ждать завершения
wait
