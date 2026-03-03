# Команды для тестирования приложения

## Быстрый тест всех сервисов

```bash
# Простая проверка health эндпоинтов
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
curl http://localhost:8006/health
curl http://localhost:8007/health
curl http://localhost:8008/health
```

## Использование скрипта тестирования

```bash
# Скачать скрипт на сервер
cd /opt/Choice
wget https://raw.githubusercontent.com/som1one/Choice/main/test_services.sh
chmod +x test_services.sh

# Запустить тест
./test_services.sh
```

Или скопируйте содержимое `test_services.sh` и выполните на сервере.

## Расширенный тест API

```bash
# Скачать расширенный скрипт
wget https://raw.githubusercontent.com/som1one/Choice/main/test_api.sh
chmod +x test_api.sh

# Запустить
./test_api.sh
```

## Ручное тестирование основных функций

### 1. Тест регистрации клиента

```bash
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testclient@test.com",
    "password": "123456",
    "user_type": "Client",
    "name": "Test Client"
  }'
```

### 2. Тест регистрации компании

```bash
curl -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testcompany@test.com",
    "password": "123456",
    "user_type": "Company",
    "company_name": "Test Company"
  }'
```

### 3. Тест входа

```bash
# Получить токен
TOKEN=$(curl -s -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testclient@test.com",
    "password": "123456"
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

### 4. Тест защищенных эндпоинтов

```bash
# Получить профиль клиента (нужен токен)
curl -X GET http://localhost:8002/api/client/get \
  -H "Authorization: Bearer $TOKEN"

# Получить профиль компании
curl -X GET http://localhost:8003/api/company/get \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Тест создания заявки

```bash
curl -X POST http://localhost:8002/api/client/sendOrderRequest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category_id": 1,
    "description": "Нужен ремонт кухни",
    "search_radius": 20,
    "to_know_price": true,
    "to_know_deadline": true
  }'
```

## Проверка через браузер

Откройте в браузере:
- http://your-server-ip:8001/docs - Swagger UI для Authentication Service
- http://your-server-ip:8002/docs - Swagger UI для Client Service
- http://your-server-ip:8003/docs - Swagger UI для Company Service
- и т.д.

## Проверка логов

```bash
# Посмотреть логи всех сервисов
journalctl -u choice-auth -n 50
journalctl -u choice-client -n 50
journalctl -u choice-company -n 50

# Следить за логами в реальном времени
journalctl -u choice-auth -f
```

## Проверка статуса systemd сервисов

```bash
# Статус всех сервисов
systemctl status choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file

# Проверить, что все запущены
systemctl is-active choice-auth choice-client choice-company choice-category choice-ordering choice-chat choice-review choice-file
```
