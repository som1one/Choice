# Тестирование регистрации компании

## Шаг 1: Проверка запущенных сервисов

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Проверка процессов
ps aux | grep "uvicorn.*800" | grep -v grep

# Проверка health endpoints
curl http://localhost:8001/health
curl http://localhost:8003/health
```

## Шаг 2: Проверка таблиц в базе данных

```bash
# Проверка существования таблиц
sqlite3 choice.db ".tables"

# Проверка структуры таблицы Companies
sqlite3 choice.db ".schema Companies"

# Проверка структуры таблицы Users
sqlite3 choice.db ".schema Users"
```

## Шаг 3: Выполнение регистрации

```bash
# Регистрация компании
curl -v -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testcompany@example.com",
    "name": "Тестовая Компания",
    "password": "Test1234!",
    "street": "Ленина",
    "city": "Москва",
    "phone_number": "1234567890",
    "type": "Company"
  }'
```

## Шаг 4: Проверка логов

```bash
# Логи authentication сервиса
tail -50 logs/authentication.log

# Логи company_service
tail -50 logs/company_service.log

# Если логов нет, проверьте, что сервисы запущены с логированием
```

## Шаг 5: Проверка в базе данных

```bash
# Проверка пользователя
python -c "
from common.database import SessionLocal
from services.authentication.models import User
db = SessionLocal()
users = db.query(User).all()
print(f'Total users: {len(users)}')
for u in users:
    print(f'  - {u.email} ({u.user_type})')
db.close()
"

# Проверка компаний
python -c "
from common.database import SessionLocal
from services.company_service.models import Company
db = SessionLocal()
companies = db.query(Company).all()
print(f'Total companies: {len(companies)}')
for c in companies:
    print(f'  - {c.title} ({c.email})')
db.close()
"
```

## Шаг 6: Если сервисы не запущены

```bash
# Запуск authentication сервиса
python run_service.py authentication 8001

# В другом терминале - запуск company_service
python run_service.py company_service 8003
```

## Шаг 7: Полная диагностика

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
echo "=== Checking services ===" && \
ps aux | grep "uvicorn.*800" | grep -v grep && \
echo "" && \
echo "=== Checking tables ===" && \
sqlite3 choice.db ".tables" && \
echo "" && \
echo "=== Testing registration ===" && \
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test","password":"Test1234!","street":"Test","city":"Test","phone_number":"123","type":"Company"}' && \
echo "" && \
echo "=== Checking database ===" && \
python -c "from common.database import SessionLocal; from services.authentication.models import User; from services.company_service.models import Company; db = SessionLocal(); print('Users:', len(db.query(User).all())); print('Companies:', len(db.query(Company).all())); db.close()"
```
