# 🚀 Гайд по развертыванию сервера на reg.ru

## 📋 Содержание
1. [Требования хостинга](#требования-хостинга)
2. [Подготовка к развертыванию](#подготовка-к-развертыванию)
3. [Варианты развертывания](#варианты-развертывания)
4. [Развертывание на VPS/VDS](#развертывание-на-vpsvds)
5. [Настройка домена](#настройка-домена)
6. [Настройка базы данных](#настройка-базы-данных)
7. [Настройка RabbitMQ](#настройка-rabbitmq)
8. [Обновление конфигурации](#обновление-конфигурации)

---

## 📦 Требования хостинга

### Варианты хостинга на reg.ru:

1. **VPS/VDS сервер** (рекомендуется) ✅
   - Полный контроль над сервером
   - Возможность установки .NET 8.0
   - Поддержка Docker (опционально)
   - Минимум: 2 CPU, 4 GB RAM, 20 GB SSD

2. **Windows хостинг** (если доступен)
   - Поддержка .NET Framework / .NET Core
   - Ограниченные возможности

3. **Облачный сервер** (Cloud)
   - Полный контроль
   - Масштабируемость

> ⚠️ **Важно:** Обычный виртуальный хостинг (Linux/PHP) **НЕ подходит** для .NET 8.0 приложений.

---

## 🔧 Подготовка к развертыванию

### Шаг 1: Подключение домена

1. В панели reg.ru подключите домен `choice-api.ru` (как вы уже начали)
2. Дождитесь обновления DNS (до 24 часов)
3. Проверьте доступность: `ping choice-api.ru`

### Шаг 2: Выбор типа сервера

**Рекомендация:** Закажите **VPS/VDS** на reg.ru с:
- **ОС:** Ubuntu 22.04 LTS или Windows Server 2022
- **RAM:** минимум 4 GB (лучше 8 GB для всех микросервисов)
- **CPU:** минимум 2 ядра
- **Диск:** минимум 50 GB SSD
- **IP:** статический IP адрес

---

## 🎯 Варианты развертывания

### Вариант 1: Прямое развертывание .NET (рекомендуется)

Развертывание скомпилированных .NET приложений напрямую на сервере.

### Вариант 2: Docker контейнеры

Использование Docker для изоляции сервисов (требует Docker на сервере).

### Вариант 3: Reverse Proxy (Nginx/IIS)

Использование Nginx или IIS как reverse proxy перед .NET приложениями.

---

## 🖥️ Развертывание на VPS/VDS

### Шаг 1: Подключение к серверу

**Для Linux (Ubuntu):**
```bash
ssh root@ваш_ip_адрес
```

**Для Windows:**
- Подключитесь через RDP (Remote Desktop)

### Шаг 2: Установка .NET 8.0 Runtime

**На Linux (Ubuntu):**
```bash
# Добавьте репозиторий Microsoft
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Установите .NET 8.0 Runtime
sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-8.0

# Проверьте установку
dotnet --version
```

**На Windows Server:**
1. Скачайте [.NET 8.0 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)
2. Установите через установщик

### Шаг 3: Установка зависимостей

**SQL Server:**
```bash
# На Linux - установите SQL Server или используйте внешний хостинг БД
# Или используйте PostgreSQL для некоторых сервисов
```

**RabbitMQ (для Event Bus):**
```bash
# На Ubuntu
sudo apt-get update
sudo apt-get install -y rabbitmq-server
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

# Создайте пользователя
sudo rabbitmqctl add_user admin ваш_пароль
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

### Шаг 4: Сборка приложения на локальной машине

**На вашем ПК (Windows):**

```bash
# Перейдите в папку с сервисом
cd services/services/authentication

# Соберите Release версию
dotnet publish -c Release -o ./publish

# Повторите для всех сервисов:
# - authentication
# - client-service/src/ClientService.Api
# - company-service
# - category-service
# - chat
# - ordering/src/Ordering.Api
# - review-service
# - file-service
```

### Шаг 5: Загрузка файлов на сервер

**Вариант A - через SCP (Linux):**
```bash
# С вашего ПК
scp -r services/services/authentication/publish/* root@ваш_ip:/var/www/authentication/
scp -r services/services/client-service/src/ClientService.Api/publish/* root@ваш_ip:/var/www/client-service/
# ... и так далее для всех сервисов
```

**Вариант B - через FTP/SFTP:**
1. Используйте FileZilla или WinSCP
2. Подключитесь к серверу
3. Загрузите папки с опубликованными приложениями

**Вариант C - через Git:**
```bash
# На сервере
git clone ваш_репозиторий
cd androidapp/services/services/authentication
dotnet publish -c Release -o /var/www/authentication
```

### Шаг 6: Создание systemd сервисов (Linux)

Создайте файлы сервисов для автозапуска:

**`/etc/systemd/system/authentication.service`:**
```ini
[Unit]
Description=Authentication API Service
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/dotnet /var/www/authentication/Authentication.Api.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=authentication-api
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:5001

[Install]
WantedBy=multi-user.target
```

**Активируйте сервис:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable authentication.service
sudo systemctl start authentication.service
sudo systemctl status authentication.service
```

**Повторите для всех сервисов** (с разными портами):
- Authentication: 5001
- Client Service: 5002
- Company Service: 5003
- Category Service: 5004
- Chat Service: 5005
- Ordering API: 5006
- Review Service: 5007
- File Service: 5008

---

## 🌐 Настройка домена

### Шаг 1: Настройка Nginx Reverse Proxy (Linux)

**Установите Nginx:**
```bash
sudo apt-get install -y nginx
```

**Создайте конфигурацию `/etc/nginx/sites-available/choice-api.ru`:**
```nginx
server {
    listen 80;
    server_name choice-api.ru www.choice-api.ru;

    # Authentication Service
    location /api/auth/ {
        proxy_pass http://localhost:5001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Client Service
    location /api/client/ {
        proxy_pass http://localhost:5002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Company Service
    location /api/company/ {
        proxy_pass http://localhost:5003/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Category Service
    location /api/category/ {
        proxy_pass http://localhost:5004/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Chat Service (SignalR)
    location /api/chat/ {
        proxy_pass http://localhost:5005/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Ordering Service
    location /api/ordering/ {
        proxy_pass http://localhost:5006/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Review Service
    location /api/review/ {
        proxy_pass http://localhost:5007/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # File Service
    location /api/file/ {
        proxy_pass http://localhost:5008/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Активируйте конфигурацию:**
```bash
sudo ln -s /etc/nginx/sites-available/choice-api.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Шаг 2: Настройка SSL (HTTPS)

**Установите Certbot:**
```bash
sudo apt-get install -y certbot python3-certbot-nginx
```

**Получите SSL сертификат:**
```bash
sudo certbot --nginx -d choice-api.ru -d www.choice-api.ru
```

Certbot автоматически обновит конфигурацию Nginx для HTTPS.

---

## 🗄️ Настройка базы данных

### Вариант 1: SQL Server на reg.ru

Если reg.ru предоставляет SQL Server:
1. Создайте базу данных в панели управления
2. Получите строку подключения
3. Обновите `appsettings.json`

### Вариант 2: Внешний хостинг БД

Используйте облачные БД:
- **Azure SQL Database**
- **AWS RDS**
- **DigitalOcean Managed Databases**

### Вариант 3: SQL Server на том же VPS

**Установка SQL Server на Linux:**
```bash
# Добавьте репозиторий Microsoft
curl -o /tmp/mssql-server-2022.deb https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022/pool/main/m/mssql-server/mssql-server_16.0.1000.1-1_amd64.deb
sudo dpkg -i /tmp/mssql-server-2022.deb

# Настройте SQL Server
sudo /opt/mssql/bin/mssql-conf setup

# Запустите SQL Server
sudo systemctl start mssql-server
sudo systemctl enable mssql-server
```

---

## 🐰 Настройка RabbitMQ

**Проверьте статус RabbitMQ:**
```bash
sudo systemctl status rabbitmq-server
```

**Включите веб-интерфейс управления:**
```bash
sudo rabbitmq-plugins enable rabbitmq_management
```

**Доступ к веб-интерфейсу:**
- URL: `http://ваш_ip:15672`
- Логин: `guest`
- Пароль: `guest` (измените!)

---

## ⚙️ Обновление конфигурации

### Шаг 1: Обновите appsettings.json для каждого сервиса

**Пример для Authentication Service:**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "JwtSettings": {
    "Issuer": "https://choice-api.ru",
    "Audience": "https://choice-api.ru",
    "Key": "AuthenticationKeyForApiWithLengthof40sym"
  },
  "SqlServerSettings": {
    "ConnectionString": "Server=localhost;Database=AuthenticationDb;User Id=sa;Password=ВашПароль;TrustServerCertificate=True;"
  },
  "EventBusSettings": {
    "HostAddress": "amqp://guest:guest@localhost:5672"
  },
  "VonageSettings": {
    "ApiKey": "ваш_api_key",
    "ApiSecret": "ваш_api_secret"
  }
}
```

### Шаг 2: Обновите мобильное приложение

**В `ClientApp/env.js`:**
```javascript
export default {
    api_url: 'https://choice-api.ru',
    auth_url: 'https://choice-api.ru'
}
```

### Шаг 3: Примените миграции базы данных

```bash
# Для каждого сервиса с БД
cd /var/www/authentication
dotnet ef database update --project /path/to/project
```

---

## 🔍 Проверка работы

### Тест API endpoints:

```bash
# Проверка Authentication Service
curl https://choice-api.ru/api/auth/health

# Проверка Swagger
https://choice-api.ru/api/auth/swagger
```

### Проверка логов:

```bash
# Логи сервиса
sudo journalctl -u authentication.service -f

# Логи Nginx
sudo tail -f /var/log/nginx/error.log
```

---

## 🛠️ Полезные команды

### Управление сервисами:

```bash
# Запуск
sudo systemctl start authentication.service

# Остановка
sudo systemctl stop authentication.service

# Перезапуск
sudo systemctl restart authentication.service

# Статус
sudo systemctl status authentication.service

# Логи
sudo journalctl -u authentication.service -n 50
```

### Обновление приложения:

```bash
# 1. Остановите сервис
sudo systemctl stop authentication.service

# 2. Загрузите новые файлы
# (через SCP, FTP или Git pull)

# 3. Запустите сервис
sudo systemctl start authentication.service
```

---

## ⚠️ Важные замечания

1. **Безопасность:**
   - Измените все пароли по умолчанию
   - Настройте файрвол (откройте только нужные порты)
   - Используйте HTTPS
   - Регулярно обновляйте систему

2. **Мониторинг:**
   - Настройте логирование
   - Используйте мониторинг ресурсов (CPU, RAM, Disk)

3. **Резервное копирование:**
   - Настройте автоматические бэкапы БД
   - Сохраняйте конфигурационные файлы

4. **Масштабирование:**
   - При росте нагрузки рассмотрите горизонтальное масштабирование
   - Используйте балансировщик нагрузки

---

## 📝 Чеклист развертывания

- [ ] Заказан VPS/VDS на reg.ru
- [ ] Подключен домен choice-api.ru
- [ ] Установлен .NET 8.0 Runtime на сервере
- [ ] Настроена база данных (SQL Server)
- [ ] Установлен и настроен RabbitMQ
- [ ] Собраны все сервисы в Release режиме
- [ ] Загружены файлы на сервер
- [ ] Созданы systemd сервисы
- [ ] Настроен Nginx reverse proxy
- [ ] Настроен SSL (HTTPS)
- [ ] Обновлены appsettings.json для всех сервисов
- [ ] Применены миграции БД
- [ ] Обновлен env.js в мобильном приложении
- [ ] Протестированы все API endpoints
- [ ] Настроен мониторинг и логирование

---

**Удачи с развертыванием! 🚀**

Если возникнут проблемы, проверьте логи сервисов и Nginx.
