# Финальные команды после успешной настройки Alembic

## После `alembic stamp head` выполнено успешно

Теперь нужно перезапустить сервисы и проверить регистрацию компании.

## Шаг 1: Перезапуск сервисов

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
./restart_services.sh
```

## Шаг 2: Проверка сервисов

```bash
# Проверка процессов
ps aux | grep "uvicorn.*800" | grep -v grep

# Проверка health endpoints
curl http://localhost:8001/health
curl http://localhost:8003/health
```

## Шаг 3: Тест регистрации компании

```bash
# Тест регистрации компании
curl -X POST http://localhost:8001/api/auth/register \
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

## Шаг 4: Проверка в базе данных

```bash
# Проверка создания пользователя
python -c "
from common.database import SessionLocal
from services.authentication.models import User
db = SessionLocal()
user = db.query(User).filter(User.email == 'testcompany@example.com').first()
if user:
    print(f'✓ User created: {user.email}, type: {user.user_type}')
else:
    print('✗ User not found')
db.close()
"

# Проверка создания компании
python -c "
from common.database import SessionLocal
from services.company_service.models import Company
db = SessionLocal()
company = db.query(Company).filter(Company.email == 'testcompany@example.com').first()
if company:
    print(f'✓ Company created: {company.title}, email: {company.email}')
    print(f'  Phone: {company.phone_number}, City: {company.city}')
else:
    print('✗ Company not found')
db.close()
"
```

## Полная команда проверки

```bash
cd /opt/Choice/backend_fastapi && \
source .venv/bin/activate && \
./restart_services.sh && \
sleep 5 && \
echo "=== Testing company registration ===" && \
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","name":"Test Company","password":"Test1234!","street":"Test St","city":"Test City","phone_number":"1234567890","type":"Company"}' && \
echo "" && \
echo "=== Checking database ===" && \
python -c "from common.database import SessionLocal; from services.authentication.models import User; from services.company_service.models import Company; db = SessionLocal(); u = db.query(User).filter(User.email == 'test@example.com').first(); c = db.query(Company).filter(Company.email == 'test@example.com').first(); print('User:', '✓' if u else '✗'); print('Company:', '✓' if c else '✗'); db.close()"
```

## Если что-то не работает

1. Проверьте логи:
```bash
tail -50 logs/authentication.log
tail -50 logs/company_service.log
```

2. Проверьте, что таблицы созданы:
```bash
sqlite3 choice.db ".tables"
```

3. Проверьте версию миграции:
```bash
alembic current
```

## Готово!

После успешного перезапуска сервисов регистрация компании должна работать корректно.
