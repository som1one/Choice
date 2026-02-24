# 🧪 Руководство по тестированию

## 🚀 Быстрая проверка

### 1. Проверка всех сервисов
```bash
python check_services.py
```

### 2. Тестирование API
```bash
python test_api.py
```

---

## 📝 Пошаговое тестирование

### Шаг 1: Регистрация пользователя

**Через Swagger UI:**
1. Откройте http://localhost:8001/docs
2. Найдите `POST /api/auth/register`
3. Нажмите "Try it out"
4. Введите данные:
```json
{
  "email": "test@example.com",
  "name": "Иван",
  "password": "Test1234!",
  "street": "Ленина",
  "city": "Москва",
  "phone_number": "1234567890",
  "type": "Client"
}
```
5. Нажмите "Execute"
6. Должен вернуться статус 200 с данными пользователя

**Через curl:**
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

### Шаг 2: Вход

**Через Swagger UI:**
1. `POST /api/auth/login`
2. Введите:
```json
{
  "email": "test@example.com",
  "password": "Test1234!"
}
```
3. Скопируйте `access_token` из ответа

**Через curl:**
```bash
curl -X POST "http://localhost:8001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!"
  }'
```

### Шаг 3: Получение категорий

**Через Swagger UI:**
1. Откройте http://localhost:8004/docs
2. Нажмите "Authorize"
3. Введите: `Bearer ваш-токен-здесь`
4. `GET /api/category/get`
5. Должен вернуться список категорий

**Через curl:**
```bash
TOKEN="ваш-токен-здесь"
curl -X GET "http://localhost:8004/api/category/get" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Проверка каждого сервиса

### Authentication Service (8001)
```bash
# Health check
curl http://localhost:8001/health

# Регистрация
curl -X POST "http://localhost:8001/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","name":"Test","password":"Test1234!","street":"Test","city":"Test","phone_number":"1234567890","type":"Client"}'
```

### Category Service (8004)
```bash
# Health check
curl http://localhost:8004/health

# Получение категорий (требует токен)
TOKEN="ваш-токен"
curl -H "Authorization: Bearer $TOKEN" http://localhost:8004/api/category/get
```

### Company Service (8003)
```bash
# Health check
curl http://localhost:8003/health
```

### Client Service (8002)
```bash
# Health check
curl http://localhost:8002/health
```

### Ordering Service (8005)
```bash
# Health check
curl http://localhost:8005/health
```

### Chat Service (8006)
```bash
# Health check
curl http://localhost:8006/health
```

### Review Service (8007)
```bash
# Health check
curl http://localhost:8007/health
```

### File Service (8008)
```bash
# Health check
curl http://localhost:8008/health
```

---

## 🐛 Типичные проблемы

### Проблема: "422 Unprocessable Entity"
- Проверьте формат данных
- Проверьте обязательные поля
- Проверьте типы данных

### Проблема: "401 Unauthorized"
- Проверьте токен
- Убедитесь, что токен не истек
- Проверьте формат: `Bearer токен`

### Проблема: "404 Not Found"
- Проверьте URL
- Убедитесь, что сервис запущен
- Проверьте порт

### Проблема: "500 Internal Server Error"
- Проверьте логи сервиса
- Проверьте подключение к БД
- Проверьте настройки в `.env`

---

## ✅ Успешное тестирование

Если все работает:
- ✅ Все health checks возвращают 200
- ✅ Регистрация создает пользователя
- ✅ Вход возвращает токен
- ✅ Запросы с токеном работают
- ✅ Swagger UI открывается

**Готово к использованию!** 🎉
