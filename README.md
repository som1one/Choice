# Choice App - Сервисный маркетплейс

Микросервисное приложение для поиска и заказа услуг. Клиенты размещают заявки, компании отвечают предложениями.

## 🏗 Архитектура

- **Backend:** FastAPI (8 микросервисов)
- **Frontend:** Flutter Web/Mobile/Desktop
- **Database:** PostgreSQL (production), SQLite (dev)
- **Message Queue:** RabbitMQ (опционально)
- **Reverse Proxy:** Nginx

## Быстрый старт

### Локальная разработка

```bash
# Backend (PowerShell)
.\backend_fastapi\start_local_services.ps1

# Flutter Web
.\client_app_flutter\start_local_web.ps1
```

### Production развёртывание

См. полный гайд в [DEPLOY.md](./DEPLOY.md)

```bash
# На сервере
git clone <repo> /opt/choice-app
cd /opt/choice-app
cp .env.example .env
# Настройте .env
./scripts/deploy.sh
```

## Production модель

Для сервера разворачивается только backend. Клиенты подключаются к backend напрямую по портам:

- `:8001` - auth
- `:8002` - client
- `:8003` - company
- `:8004` - category
- `:8005` - ordering
- `:8006` - chat / websocket
- `:8007` - review
- `:8008` - file

Flutter не требуется на сервере и не входит в production deploy. Web/mobile клиент собирается и распространяется отдельно.

## Структура проекта

```
androidapp/
├── backend_fastapi/          # FastAPI бэкенд
│   ├── services/            # 8 микросервисов
│   │   ├── authentication/  # Порт 8001 - JWT, регистрация
│   │   ├── client_service/  # Порт 8002 - клиенты, заявки
│   │   ├── company_service/ # Порт 8003 - компании, рейтинги
│   │   ├── category_service/# Порт 8004 - категории услуг
│   │   ├── ordering/        # Порт 8005 - заказы, отклики
│   │   ├── chat/            # Порт 8006 - чат, WebSocket
│   │   ├── review_service/  # Порт 8007 - отзывы
│   │   └── file_service/    # Порт 8008 - файлы
│   ├── common/              # Общие модули
│   ├── tests/               # Тесты
│   └── Dockerfile           # Docker образ
├── client_app_flutter/      # Flutter приложение
├── docker-compose.yml       # Docker Compose конфиг
├── nginx/                   # Nginx конфигурация
├── scripts/                 # Скрипты деплоя
└── .github/workflows/       # CI/CD
```

## 🛠 Технологии

**Backend:**
- FastAPI, SQLAlchemy, Pydantic
- PostgreSQL, Alembic
- JWT, bcrypt
- RabbitMQ (aio-pika)
- Firebase Cloud Messaging

**Frontend:**
- Flutter 3.24+
- HTTP, WebSocket
- Shared Preferences
- Image Picker

**DevOps:**
- Docker, Docker Compose
- Nginx
- GitHub Actions
- Let's Encrypt

## Smoke и проверки

Локальный backend smoke:

```bash
powershell -ExecutionPolicy Bypass -File .\backend_fastapi\start_local_services.ps1
.\backend_fastapi\venv\Scripts\python.exe .\backend_fastapi\check_services.py
.\backend_fastapi\venv\Scripts\python.exe .\backend_fastapi\seed_local_demo_data.py --host 127.0.0.1 --scheme http
cd .\backend_fastapi
venv\Scripts\python.exe smoke_test_backend.py --host 127.0.0.1 --scheme http --client-email local_client@example.com --client-password Test1234! --company-email local_company_main@example.com --company-password Test1234!
```

## Документация

- [DEPLOY.md](./DEPLOY.md) - Полный гайд по развёртыванию
- [LOCAL_TESTING_GUIDE.md](./LOCAL_TESTING_GUIDE.md) - Локальная разработка
- Auth docs: `http://your-server:8001/docs`
- Local testing: [LOCAL_TESTING_GUIDE.md](./LOCAL_TESTING_GUIDE.md)

## CI/CD

Автоматический деплой через GitHub Actions:
- Сборка Flutter Web
- Запуск тестов
- Деплой на сервер

Настройка: см. [DEPLOY.md#github-actions-cicd](./DEPLOY.md#github-actions-cicd)

## 📄 Лицензия

MIT
