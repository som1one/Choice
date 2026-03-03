#!/bin/bash
# Исправленные systemd сервисы - запуск из корня backend_fastapi

# Client Service
cat > /etc/systemd/system/choice-client.service << 'EOF'
[Unit]
Description=Choice Client Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.client_service.main:app --host 0.0.0.0 --port 8002
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Company Service
cat > /etc/systemd/system/choice-company.service << 'EOF'
[Unit]
Description=Choice Company Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Category Service
cat > /etc/systemd/system/choice-category.service << 'EOF'
[Unit]
Description=Choice Category Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.category_service.main:app --host 0.0.0.0 --port 8004
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Ordering Service
cat > /etc/systemd/system/choice-ordering.service << 'EOF'
[Unit]
Description=Choice Ordering Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.ordering.main:app --host 0.0.0.0 --port 8005
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Chat Service
cat > /etc/systemd/system/choice-chat.service << 'EOF'
[Unit]
Description=Choice Chat Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.chat.main:app --host 0.0.0.0 --port 8006
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Review Service
cat > /etc/systemd/system/choice-review.service << 'EOF'
[Unit]
Description=Choice Review Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.review_service.main:app --host 0.0.0.0 --port 8007
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# File Service
cat > /etc/systemd/system/choice-file.service << 'EOF'
[Unit]
Description=Choice File Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.file_service.main:app --host 0.0.0.0 --port 8008
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Authentication Service (тоже исправим для единообразия)
cat > /etc/systemd/system/choice-auth.service << 'EOF'
[Unit]
Description=Choice Authentication Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
Environment="PYTHONPATH=/opt/Choice/backend_fastapi"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "All service files updated!"
echo "Now run: systemctl daemon-reload"
