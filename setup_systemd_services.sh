#!/bin/bash

# Скрипт для создания systemd сервисов для всех Choice сервисов
# Запускать от root: sudo bash setup_systemd_services.sh

PROJECT_DIR="/opt/Choice/backend_fastapi"
VENV_PATH="$PROJECT_DIR/venv"
USER="root"

# Функция для создания сервиса
create_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    
    cat > /etc/systemd/system/choice-${service_name}.service << EOF
[Unit]
Description=Choice ${service_name^} Service
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${PROJECT_DIR}/services/${service_dir}
Environment="PATH=${VENV_PATH}/bin"
ExecStart=${VENV_PATH}/bin/uvicorn main:app --host 0.0.0.0 --port ${port}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    echo "Created service: choice-${service_name}.service"
}

# Создаем все сервисы
create_service "auth" "authentication" "8001"
create_service "client" "client_service" "8002"
create_service "company" "company_service" "8003"
create_service "category" "category_service" "8004"
create_service "ordering" "ordering" "8005"
create_service "chat" "chat" "8006"
create_service "review" "review_service" "8007"
create_service "file" "file_service" "8008"

# Перезагружаем systemd
systemctl daemon-reload

echo ""
echo "All services created! Now you can:"
echo "  systemctl enable choice-auth"
echo "  systemctl start choice-auth"
echo "  # and so on for other services"
