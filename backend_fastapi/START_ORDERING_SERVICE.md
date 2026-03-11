# Запуск Ordering Service

## Проблема
При запросе заказов (`/api/order/get?order_request_id=2`) возникает ошибка "Failed to fetch", потому что сервис ordering не запущен на порту 8005.

## Решение

### Вариант 1: Запуск только Ordering Service

```bash
cd /opt/Choice/backend_fastapi
chmod +x start_ordering_service.sh
./start_ordering_service.sh
```

### Вариант 2: Запуск через run_service.py

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
export PYTHONPATH="$(pwd)"
python run_service.py ordering 8005
```

### Вариант 3: Запуск через uvicorn напрямую

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
export PYTHONPATH="$(pwd)"

# Инициализация БД
python -c "from services.ordering.database import init_db; init_db()"

# Запуск сервиса
nohup python -m uvicorn services.ordering.main:app --host 0.0.0.0 --port 8005 > logs/ordering.log 2>&1 &
```

### Вариант 4: Перезапуск всех сервисов (включая Ordering)

```bash
cd /opt/Choice/backend_fastapi
chmod +x restart_services.sh
./restart_services.sh
```

## Проверка работы

### Проверка процесса
```bash
ps aux | grep "uvicorn.*8005" | grep -v grep
```

### Проверка порта
```bash
lsof -i:8005
# или
netstat -tulpn | grep 8005
```

### Проверка health endpoint
```bash
curl http://localhost:8005/health
# Должен вернуть: {"status":"healthy"}
```

### Проверка с внешнего IP
```bash
curl http://77.95.203.148:8005/health
```

## Просмотр логов

```bash
# Последние 50 строк
tail -50 logs/ordering.log

# В реальном времени
tail -f logs/ordering.log
```

## Остановка сервиса

```bash
# Найти и убить процесс
pkill -9 -f "uvicorn.*8005"
# или
lsof -ti:8005 | xargs kill -9
```

## Исправления в коде

1. **Улучшена обработка ошибок в `getOrders`**:
   - Теперь возвращается пустой список `[]` вместо `null` при ошибках сети
   - Добавлено логирование для диагностики

2. **Добавлен Ordering Service в `restart_services.sh`**:
   - Теперь все три сервиса (auth, company, ordering) запускаются вместе

3. **Создан отдельный скрипт `start_ordering_service.sh`**:
   - Для удобного запуска только ordering service

## После запуска

После успешного запуска ordering service, запросы к `/api/order/get?order_request_id=2` должны работать корректно.

Если заказов нет, будет возвращен пустой список `[]`, что безопасно обрабатывается в UI и показывает сообщение "Нет ответов от компаний".
