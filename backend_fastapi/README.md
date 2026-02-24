# 🚀 Backend FastAPI

Миграция бэкенда с .NET 8.0 на FastAPI.

## ⚡ Быстрый старт

```bash
# 1. Установка
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt

# 2. Настройка .env (см. START_GUIDE.md)

# 3. Запуск всех сервисов
start_all.bat  # Windows
# или
./start_all.sh  # Linux/Mac
```

**Подробнее:** См. `QUICK_START.md` или `START_GUIDE.md`

## 📦 Установка

```bash
# Создать виртуальное окружение
python -m venv venv

# Активировать (Windows)
venv\Scripts\activate

# Активировать (Linux/Mac)
source venv/bin/activate

# Установить зависимости
pip install -r requirements.txt
```

## ⚙️ Настройка

1. Создать `.env` файл (см. `START_GUIDE.md`)
2. Настроить подключение к БД
3. Настроить JWT секреты

## 🏃 Запуск

### Вариант 1: Все сервисы сразу
**Windows (PowerShell):**
```powershell
.\start_all.bat
```

**Windows (CMD):**
```cmd
start_all.bat
```

**Linux/Mac:**
```bash
./start_all.sh
```

### Вариант 2: По отдельности
```bash
# Authentication Service
cd services/authentication
uvicorn main:app --port 8001 --reload

# Category Service
cd services/category_service
uvicorn main:app --port 8004 --reload

# И т.д.
```

## ✅ Проверка

### Health Check
```bash
python check_services.py
```

### Тестирование API
```bash
python test_api.py
```

### Swagger UI
- Authentication: http://localhost:8001/docs
- Client: http://localhost:8002/docs
- Company: http://localhost:8003/docs
- Category: http://localhost:8004/docs
- Ordering: http://localhost:8005/docs
- Chat: http://localhost:8006/docs
- Review: http://localhost:8007/docs
- File: http://localhost:8008/docs

## 📚 Документация

- `START_GUIDE.md` - Подробное руководство по запуску
- `QUICK_START.md` - Быстрый старт
- `MIGRATION_COMPLETE_REPORT.md` - Отчет о миграции
- Swagger UI - Интерактивная документация API

## 🏗️ Структура

```
backend_fastapi/
├── services/          # Микросервисы
│   ├── authentication/ ✅
│   ├── client_service/ ✅
│   ├── company_service/ ✅
│   ├── category_service/ ✅
│   ├── ordering/ ✅
│   ├── chat/ ✅
│   ├── review_service/ ✅
│   └── file_service/ ✅
├── common/           # Общие модули
│   ├── database.py
│   ├── security.py
│   ├── dependencies.py
│   └── address_service.py
├── start_all.bat     # Запуск всех (Windows)
├── start_all.sh      # Запуск всех (Linux/Mac)
├── check_services.py # Проверка статуса
├── test_api.py       # Тестирование API
└── requirements.txt
```

## 🔄 Статус миграции

- ✅ Authentication Service - готов
- ✅ Client Service - готов
- ✅ Company Service - готов
- ✅ Category Service - готов
- ✅ Ordering Service - готов
- ✅ Chat Service - готов
- ✅ Review Service - готов
- ✅ File Service - готов

**Все 8 сервисов переписаны!**
