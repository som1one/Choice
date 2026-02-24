#!/bin/bash

echo "Starting all FastAPI services..."
echo ""

# Определить внешний IPv4 адрес сервера (для вывода ссылок)
get_server_ip() {
    local ip_addr
    ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -n "$ip_addr" ]]; then
        echo "$ip_addr"
        return 0
    fi

    ip_addr=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
    if [[ -n "$ip_addr" ]]; then
        echo "$ip_addr"
        return 0
    fi

    echo "127.0.0.1"
}

SERVER_IP="$(get_server_ip)"

# Функция для запуска сервиса
start_service() {
    local name=$1
    local port=$2
    local path=$3
    
    echo "Starting $name on port $port..."
    cd "$path" || exit
    uvicorn main:app --host 0.0.0.0 --port "$port" --reload > "../../logs/${name,,}.log" 2>&1 &
    cd - || exit
    sleep 1
}

# Создать директорию для логов (в backend_fastapi/logs)
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
echo "- Authentication: http://${SERVER_IP}:8001/docs"
echo "- Client: http://${SERVER_IP}:8002/docs"
echo "- Company: http://${SERVER_IP}:8003/docs"
echo "- Category: http://${SERVER_IP}:8004/docs"
echo "- Ordering: http://${SERVER_IP}:8005/docs"
echo "- Chat: http://${SERVER_IP}:8006/docs"
echo "- Review: http://${SERVER_IP}:8007/docs"
echo "- File: http://${SERVER_IP}:8008/docs"
echo ""
echo "Logs are in logs/ directory"
echo ""
echo "Press Ctrl+C to stop all services"

# Ждать завершения
wait
