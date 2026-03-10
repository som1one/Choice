# Команды для развертки на сервере

## 1. Подключение к серверу и переход в директорию проекта

```bash
ssh user@your-server
cd /opt/Choice/backend_fastapi
```

## 2. Получение последних изменений из репозитория

```bash
git pull origin main
```

## 3. Активация виртуального окружения

```bash
source .venv/bin/activate
```

## 4. Установка/обновление зависимостей (если нужно)

```bash
pip install -r requirements.txt
```

## 5. Инициализация/обновление базы данных

```bash
# Инициализация БД для Authentication Service
python -c "from services.authentication.database import init_db; init_db()"

# Инициализация БД для Company Service
python -c "from services.company_service.database import init_db; init_db()"
```

## 6. Остановка текущих сервисов

```bash
# Остановка Authentication Service (порт 8001)
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001"

# Остановка Company Service (порт 8003)
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003"

# Подождать 2 секунды
sleep 2
```

## 7. Запуск сервисов

```bash
# Создать директорию для логов (если не существует)
mkdir -p logs

# Запуск Authentication Service
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &

# Запуск Company Service
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 --reload > logs/company_service.log 2>&1 &

# Подождать запуска
sleep 3
```

## 8. Проверка статуса сервисов

```bash
# Проверка процессов
ps aux | grep "uvicorn.*8001" | grep -v grep
ps aux | grep "uvicorn.*8003" | grep -v grep

# Проверка портов
lsof -i:8001
lsof -i:8003

# Проверка health endpoints
curl http://localhost:8001/health
curl http://localhost:8003/health
```

## 9. Просмотр логов (если нужно)

```bash
# Логи Authentication Service
tail -50 logs/authentication.log

# Логи Company Service
tail -50 logs/company_service.log

# Логи в реальном времени
tail -f logs/authentication.log
tail -f logs/company_service.log
```

## 10. Тестирование регистрации компании

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

## Быстрая команда для перезапуска (все в одной строке)

```bash
cd /opt/Choice/backend_fastapi && \
git pull origin main && \
source .venv/bin/activate && \
lsof -ti:8001 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8001" && \
lsof -ti:8003 | xargs kill -9 2>/dev/null || pkill -f "uvicorn.*8003" && \
sleep 2 && \
mkdir -p logs && \
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 & \
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.company_service.main:app --host 0.0.0.0 --port 8003 --reload > logs/company_service.log 2>&1 & \
sleep 3 && \
echo "Services restarted" && \
curl http://localhost:8001/health && \
curl http://localhost:8003/health
```

## Важные изменения в этом обновлении

1. **Исправлена регистрация компании:**
   - Добавлены дефолтные значения для обязательных полей (phone_number, city, street)
   - Добавлена проверка на пустые координаты
   - Улучшена обработка ошибок в consumer

2. **Добавлены тесты:**
   - `test_company_registration.py` - pytest тесты
   - `test_company_registration_http.py` - HTTP тесты

3. **Улучшена обработка ошибок:**
   - Более детальное логирование ошибок
   - Правильная очистка транзакций при ошибках

## Проверка после развертки

После развертки рекомендуется проверить:

1. ✅ Сервисы запущены и отвечают на health checks
2. ✅ Регистрация компании работает без ошибок
3. ✅ Компания создается в базе данных
4. ✅ RabbitMQ события отправляются корректно
