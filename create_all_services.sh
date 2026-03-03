#!/bin/bash
# Скрипт для создания всех systemd сервисов

# Client Service
cat > /etc/systemd/system/choice-client.service << 'EOF'
[Unit]
Description=Choice Client Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi/services/client_service
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8002
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/company_service
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8003
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/category_service
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8004
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/ordering
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8005
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/chat
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8006
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/review_service
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8007
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
WorkingDirectory=/opt/Choice/backend_fastapi/services/file_service
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8008
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "All service files created!"
echo "Now run: systemctl daemon-reload"
