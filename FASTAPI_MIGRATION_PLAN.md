# 🚀 План миграции .NET → FastAPI

## 📊 Обзор проекта

**Текущий стек:**
- .NET 8.0 микросервисы
- ASP.NET Core Web API
- Entity Framework Core
- SQL Server / PostgreSQL
- RabbitMQ (MassTransit)
- SignalR
- JWT Bearer Authentication

**Целевой стек:**
- FastAPI (Python 3.11+)
- SQLAlchemy ORM
- PostgreSQL / SQL Server
- RabbitMQ (aio-pika)
- WebSocket (FastAPI)
- JWT Authentication (python-jose)

---

## 🗺️ Структура миграции

### Этап 1: Подготовка и настройка проекта
- [ ] 1.1. Создать структуру проекта FastAPI
- [ ] 1.2. Настроить виртуальное окружение
- [ ] 1.3. Добавить зависимости (requirements.txt)
- [ ] 1.4. Настроить конфигурацию (.env)
- [ ] 1.5. Настроить базу данных (SQLAlchemy)

### Этап 2: Общая инфраструктура
- [ ] 2.1. Настроить JWT аутентификацию
- [ ] 2.2. Настроить подключение к БД
- [ ] 2.3. Настроить RabbitMQ (aio-pika)
- [ ] 2.4. Создать общие модели и схемы
- [ ] 2.5. Создать общие утилиты

### Этап 3: Authentication Service
- [ ] 3.1. Модели пользователей (SQLAlchemy)
- [ ] 3.2. JWT токены (python-jose)
- [ ] 3.3. Верификация телефона (Vonage)
- [ ] 3.4. Верификация email
- [ ] 3.5. API endpoints (FastAPI)
- [ ] 3.6. Интеграция с RabbitMQ

### Этап 4: Client Service
- [ ] 4.1. Модели клиентов
- [ ] 4.2. API endpoints
- [ ] 4.3. Бизнес-логика
- [ ] 4.4. Интеграция с RabbitMQ

### Этап 5: Company Service
- [ ] 5.1. Модели компаний
- [ ] 5.2. API endpoints
- [ ] 5.3. Геокодирование адресов
- [ ] 5.4. Интеграция с RabbitMQ

### Этап 6: Category Service
- [ ] 6.1. Модели категорий
- [ ] 6.2. API endpoints
- [ ] 6.3. Seed данные

### Этап 7: Ordering Service
- [ ] 7.1. Модели заказов
- [ ] 7.2. API endpoints
- [ ] 7.3. Бизнес-логика заказов
- [ ] 7.4. Интеграция с RabbitMQ

### Этап 8: Chat Service
- [ ] 8.1. Модели сообщений
- [ ] 8.2. WebSocket endpoints
- [ ] 8.3. Real-time коммуникация
- [ ] 8.4. Интеграция с RabbitMQ

### Этап 9: Review Service
- [ ] 9.1. Модели отзывов
- [ ] 9.2. API endpoints

### Этап 10: File Service
- [ ] 10.1. Загрузка файлов
- [ ] 10.2. Хранение файлов
- [ ] 10.3. API endpoints

### Этап 11: Интеграция и тестирование
- [ ] 11.1. Интеграция всех сервисов
- [ ] 11.2. Тестирование API
- [ ] 11.3. Тестирование WebSocket
- [ ] 11.4. Тестирование RabbitMQ

### Этап 12: Документация и деплой
- [ ] 12.1. Swagger документация
- [ ] 12.2. Docker контейнеризация
- [ ] 12.3. Настройка деплоя
- [ ] 12.4. Миграции БД

---

## 📦 Зависимости FastAPI

### Основные:
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `sqlalchemy` - ORM
- `alembic` - Миграции БД
- `psycopg2-binary` - PostgreSQL драйвер
- `pymssql` - SQL Server драйвер
- `python-jose[cryptography]` - JWT
- `passlib[bcrypt]` - Хеширование паролей
- `python-multipart` - Загрузка файлов
- `aio-pika` - RabbitMQ
- `pydantic` - Валидация данных
- `pydantic-settings` - Настройки

### Дополнительные:
- `python-dotenv` - .env файлы
- `httpx` - HTTP клиент
- `vonage` - SMS API
- `email-validator` - Валидация email

---

## 🏗️ Структура проекта

```
backend_fastapi/
├── services/
│   ├── authentication/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   ├── routers/
│   │   │   └── auth.py
│   │   ├── services/
│   │   │   ├── token_service.py
│   │   │   ├── phone_verification.py
│   │   │   └── email_verification.py
│   │   └── database.py
│   ├── client_service/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   └── routers/
│   ├── company_service/
│   ├── category_service/
│   ├── ordering/
│   ├── chat/
│   ├── review_service/
│   └── file_service/
├── common/
│   ├── __init__.py
│   ├── database.py
│   ├── security.py
│   ├── models.py
│   └── rabbitmq.py
├── requirements.txt
├── .env.example
└── docker-compose.yml
```

---

## 🔄 Маппинг .NET → FastAPI

### Контроллеры → Роутеры
- `AuthController.cs` → `routers/auth.py`
- `CompanyController.cs` → `routers/company.py`

### Сервисы → Services
- `TokenService.cs` → `services/token_service.py`
- `PhoneVerificationService.cs` → `services/phone_verification.py`

### Модели → SQLAlchemy Models
- `User.cs` → `models.py` (SQLAlchemy)
- `Company.cs` → `models.py` (SQLAlchemy)

### DTO → Pydantic Schemas
- `UserViewModel.cs` → `schemas.py` (Pydantic)

### Entity Framework → SQLAlchemy
- `DbContext` → `SessionLocal`
- `DbSet<T>` → `session.query(Model)`

### MassTransit → aio-pika
- `IPublishEndpoint` → `aio_pika.Channel`
- `IConsumer<T>` → `async def consume(message)`

### SignalR → WebSocket
- `Hub` → `WebSocket` endpoint
- `Clients.All.SendAsync()` → `await websocket.send_json()`

---

## ⚙️ Конфигурация

### .env файл:
```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
SQL_SERVER_CONNECTION=Server=localhost;Database=dbname;...

# JWT
JWT_SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
JWT_ISSUER=your-issuer
JWT_AUDIENCE=your-audience

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# Vonage (SMS)
VONAGE_API_KEY=your-key
VONAGE_API_SECRET=your-secret

# Services URLs
AUTH_SERVICE_URL=http://localhost:8001
CLIENT_SERVICE_URL=http://localhost:8002
COMPANY_SERVICE_URL=http://localhost:8003
```

---

## 🚀 Запуск

```bash
# Установка зависимостей
pip install -r requirements.txt

# Запуск сервиса
uvicorn services.authentication.main:app --port 8001 --reload
```

---

## 📝 Примечания

- Все сервисы будут работать асинхронно (async/await)
- Используется Pydantic для валидации
- SQLAlchemy для работы с БД
- WebSocket для real-time чата
- RabbitMQ для event-driven архитектуры
