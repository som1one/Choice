# Команды для создания systemd сервисов на сервере

## Быстрая установка (скопируйте и выполните на сервере):

```bash
# 1. Authentication Service
cat > /etc/systemd/system/choice-auth.service << 'EOF'
[Unit]
Description=Choice Authentication Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Choice/backend_fastapi/services/authentication
Environment="PATH=/opt/Choice/backend_fastapi/venv/bin"
ExecStart=/opt/Choice/backend_fastapi/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 2. Client Service
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

# 3. Company Service
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

# 4. Category Service
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

# 5. Ordering Service
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

# 6. Chat Service
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

# 7. Review Service
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

# 8. File Service
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

# Перезагрузить systemd
systemctl daemon-reload

# Включить автозапуск всех сервисов
systemctl enable choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file

# Запустить все сервисы
systemctl start choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file

# Проверить статус
systemctl status choice-auth
```

## Полезные команды:

```bash
# Проверить статус всех сервисов
systemctl status choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file

# Посмотреть логи конкретного сервиса
journalctl -u choice-auth -f
journalctl -u choice-client -f
journalctl -u choice-company -f

# Перезапустить сервис
systemctl restart choice-auth

# Остановить сервис
systemctl stop choice-auth

# Отключить автозапуск
systemctl disable choice-auth
```
