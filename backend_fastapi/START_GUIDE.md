# 🚀 Руководство по запуску FastAPI сервисов

## 📋 Предварительные требования

- Python 3.11 или выше
- PostgreSQL или SQL Server
- RabbitMQ (опционально, для полной функциональности)
- Git

---

## 🔧 Шаг 1: Установка зависимостей

```bash
# Перейти в директорию проекта
cd backend_fastapi

# Создать виртуальное окружение
python -m venv venv

# Активировать виртуальное окружение
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Установить зависимости
pip install -r requirements.txt
```

---

## ⚙️ Шаг 2: Настройка окружения

### 2.1. Создать .env файл

Создайте файл `.env` в корне `backend_fastapi/`:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/choice_db
# Или для SQL Server:
# SQL_SERVER_CONNECTION=Server=localhost;Database=choice_db;User Id=sa;Password=YourPassword123!;TrustServerCertificate=True;

# JWT Settings
JWT_SECRET_KEY=your-super-secret-key-change-in-production-min-32-chars
JWT_ALGORITHM=HS256
JWT_ISSUER=choice-api
JWT_AUDIENCE=choice-app
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=1440

# RabbitMQ (опционально)
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# Vonage (SMS) - опционально
VONAGE_API_KEY=your-vonage-api-key
VONAGE_API_SECRET=your-vonage-api-secret

# File Service
FILE_UPLOAD_PATH=etc/files
```

### 2.2. Настроить базу данных

```bash
# Для PostgreSQL
createdb choice_db

# Или создать через psql
psql -U postgres
CREATE DATABASE choice_db;
```

---

## 🏃 Шаг 3: Запуск сервисов

### Вариант 1: Запуск каждого сервиса отдельно

Откройте отдельные терминалы для каждого сервиса:

**Терминал 1 - Authentication Service:**
```bash
cd services/authentication
uvicorn main:app --port 8001 --reload
```

**Терминал 2 - Client Service:**
```bash
cd services/client_service
uvicorn main:app --port 8002 --reload
```

**Терминал 3 - Company Service:**
```bash
cd services/company_service
uvicorn main:app --port 8003 --reload
```

**Терминал 4 - Category Service:**
```bash
cd services/category_service
uvicorn main:app --port 8004 --reload
```

**Терминал 5 - Ordering Service:**
```bash
cd services/ordering
uvicorn main:app --port 8005 --reload
```

**Терминал 6 - Chat Service:**
```bash
cd services/chat
uvicorn main:app --port 8006 --reload
```

**Терминал 7 - Review Service:**
```bash
cd services/review_service
uvicorn main:app --port 8007 --reload
```

**Терминал 8 - File Service:**
```bash
cd services/file_service
uvicorn main:app --port 8008 --reload
```

### Вариант 2: Запуск через скрипт (Windows)

Создайте файл `start_all.bat`:

```batch
@echo off
start "Auth Service" cmd /k "cd services\authentication && uvicorn main:app --port 8001 --reload"
start "Client Service" cmd /k "cd services\client_service && uvicorn main:app --port 8002 --reload"
start "Company Service" cmd /k "cd services\company_service && uvicorn main:app --port 8003 --reload"
start "Category Service" cmd /k "cd services\category_service && uvicorn main:app --port 8004 --reload"
start "Ordering Service" cmd /k "cd services\ordering && uvicorn main:app --port 8005 --reload"
start "Chat Service" cmd /k "cd services\chat && uvicorn main:app --port 8006 --reload"
start "Review Service" cmd /k "cd services\review_service && uvicorn main:app --port 8007 --reload"
start "File Service" cmd /k "cd services\file_service && uvicorn main:app --port 8008 --reload"
```

### Вариант 3: Запуск через скрипт (Linux/Mac)

Создайте файл `start_all.sh`:

```bash
#!/bin/bash
cd services/authentication && uvicorn main:app --port 8001 --reload &
cd ../client_service && uvicorn main:app --port 8002 --reload &
cd ../company_service && uvicorn main:app --port 8003 --reload &
cd ../category_service && uvicorn main:app --port 8004 --reload &
cd ../ordering && uvicorn main:app --port 8005 --reload &
cd ../chat && uvicorn main:app --port 8006 --reload &
cd ../review_service && uvicorn main:app --port 8007 --reload &
cd ../file_service && uvicorn main:app --port 8008 --reload &
wait
```

---

## 🧪 Шаг 4: Проверка работы

### 4.1. Проверка через браузер

Откройте в браузере:

- **Swagger UI:**
  - Authentication: http://localhost:8001/docs
  - Client: http://localhost:8002/docs
  - Company: http://localhost:8003/docs
  - Category: http://localhost:8004/docs
  - Ordering: http://localhost:8005/docs
  - Chat: http://localhost:8006/docs
  - Review: http://localhost:8007/docs
  - File: http://localhost:8008/docs

- **Health Check:**
  - http://localhost:8001/health
  - http://localhost:8002/health
  - и т.д.

### 4.2. Проверка через curl

```bash
# Проверка Authentication Service
curl http://localhost:8001/health

# Проверка Category Service
curl http://localhost:8004/health

# Проверка всех сервисов
for port in 8001 8002 8003 8004 8005 8006 8007 8008; do
  echo "Checking port $port..."
  curl http://localhost:$port/health
done
```

### 4.3. Тестирование API

#### Регистрация пользователя:

```bash
curl -X POST "http://localhost:8001/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Иван",
    "password": "Test1234!",
    "street": "Ленина",
    "city": "Москва",
    "phone_number": "1234567890",
    "type": "Client"
  }'
```

#### Вход:

```bash
curl -X POST "http://localhost:8001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!"
  }'
```

#### Получение категорий (требует авторизации):

```bash
# Сначала получите токен из /api/auth/login
TOKEN="your-jwt-token-here"

curl -X GET "http://localhost:8004/api/category/get" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Шаг 5: Проверка через Swagger UI

1. Откройте http://localhost:8001/docs
2. Нажмите "Authorize" (если требуется)
3. Введите токен: `Bearer your-token-here`
4. Попробуйте выполнить запросы через UI

---

## 🐛 Решение проблем

### Проблема: "Module not found"
```bash
# Убедитесь, что вы в виртуальном окружении
# Переустановите зависимости
pip install -r requirements.txt
```

### Проблема: "Database connection error"
- Проверьте настройки в `.env`
- Убедитесь, что БД запущена
- Проверьте права доступа

### Проблема: "Port already in use"
```bash
# Windows: найти процесс
netstat -ano | findstr :8001
taskkill /PID <PID> /F

# Linux/Mac: найти процесс
lsof -i :8001
kill -9 <PID>
```

### Проблема: "Import errors"
```bash
# Убедитесь, что вы запускаете из правильной директории
# Или установите проект как пакет:
pip install -e .
```

---

## 📊 Мониторинг

### Проверка логов

Все сервисы выводят логи в консоль. Следите за:
- Ошибками подключения к БД
- Ошибками валидации
- Ошибками авторизации

### Проверка статуса всех сервисов

Создайте скрипт `check_services.py`:

```python
import requests
import sys

services = {
    "Authentication": "http://localhost:8001/health",
    "Client": "http://localhost:8002/health",
    "Company": "http://localhost:8003/health",
    "Category": "http://localhost:8004/health",
    "Ordering": "http://localhost:8005/health",
    "Chat": "http://localhost:8006/health",
    "Review": "http://localhost:8007/health",
    "File": "http://localhost:8008/health",
}

all_ok = True
for name, url in services.items():
    try:
        response = requests.get(url, timeout=2)
        if response.status_code == 200:
            print(f"✅ {name}: OK")
        else:
            print(f"❌ {name}: {response.status_code}")
            all_ok = False
    except Exception as e:
        print(f"❌ {name}: {e}")
        all_ok = False

sys.exit(0 if all_ok else 1)
```

Запуск:
```bash
python check_services.py
```

---

## ✅ Чеклист готовности

- [ ] Python 3.11+ установлен
- [ ] Виртуальное окружение создано
- [ ] Зависимости установлены
- [ ] .env файл настроен
- [ ] База данных создана и доступна
- [ ] Все сервисы запущены
- [ ] Health checks проходят
- [ ] Swagger UI доступен
- [ ] Тестовый запрос выполнен успешно

---

## 🎯 Следующие шаги

1. Протестировать все endpoints через Swagger
2. Настроить RabbitMQ (если нужно)
3. Настроить реальные API (геокодирование, email)
4. Настроить миграции БД (Alembic)
5. Настроить Docker (опционально)

---

## 📝 Примечания

- Все сервисы работают независимо
- Можно запускать только нужные сервисы
- Для разработки используйте `--reload` флаг
- Для продакшена используйте `gunicorn` или `uvicorn` с несколькими воркерами
