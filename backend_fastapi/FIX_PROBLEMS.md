# Решение проблем Authentication Service

## Текущие проблемы:

1. **Два процесса конфликтуют** - один из `.venv` и один из старого `venv`
2. **Порт показывает как свободный**, но процессы есть
3. **Health endpoint не отвечает**
4. **404 Not Found на login** - из-за конфликта процессов
5. **Пользователь не найден в БД**

## Решение:

### Шаг 1: Полная остановка всех процессов

```bash
cd /opt/Choice/backend_fastapi
chmod +x kill_all_auth_processes.sh
./kill_all_auth_processes.sh
```

Или вручную:

```bash
# Найти все процессы
ps aux | grep -E "uvicorn.*8001|uvicorn.*authentication" | grep -v grep

# Убить все найденные процессы
ps aux | grep -E "uvicorn.*8001|uvicorn.*authentication" | grep -v grep | awk '{print $2}' | xargs kill -9

# Принудительно освободить порт
fuser -k 8001/tcp 2>/dev/null || lsof -ti:8001 | xargs kill -9 2>/dev/null

# Проверить
sleep 2
ps aux | grep uvicorn | grep -v grep
lsof -ti:8001 || echo "Порт свободен"
```

### Шаг 2: Создать пользователя в БД

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
python3 check_and_create_user.py
```

При запросе введите `y` для создания пользователя `cp@gmail.com` с паролем `qwerty123`.

### Шаг 3: Запустить сервис из .venv

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
sleep 3
```

### Шаг 4: Проверить

```bash
# Проверка процессов (должен быть только один из .venv)
ps aux | grep "uvicorn.*8001" | grep -v grep

# Проверка порта
lsof -i:8001

# Health check
curl http://localhost:8001/health

# Тестовый login
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cp@gmail.com","password":"qwerty123"}'
```

## Быстрое решение (одной командой):

```bash
cd /opt/Choice/backend_fastapi && \
ps aux | grep -E "uvicorn.*8001|uvicorn.*authentication" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null && \
fuser -k 8001/tcp 2>/dev/null && \
sleep 3 && \
source .venv/bin/activate && \
python3 check_and_create_user.py <<< "y" && \
PYTHONPATH="$(pwd)" nohup .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 & \
sleep 3 && \
curl http://localhost:8001/health && \
echo "" && \
curl -X POST http://localhost:8001/api/auth/login -H "Content-Type: application/json" -d '{"email":"cp@gmail.com","password":"qwerty123"}'
```

## Важно:

1. **Убедитесь, что используете `.venv`, а не старый `venv`**
2. **Остановите ВСЕ процессы перед запуском нового**
3. **Создайте пользователя в БД перед тестированием login**

## Проверка после исправления:

```bash
# Должен быть только один процесс из .venv
ps aux | grep uvicorn | grep -v grep

# Health должен вернуть {"status":"healthy"}
curl http://localhost:8001/health

# Login должен вернуть токен (не 404)
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cp@gmail.com","password":"qwerty123"}'
```
