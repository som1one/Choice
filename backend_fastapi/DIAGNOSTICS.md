# Диагностика Authentication Service

## Проблемы, которые были обнаружены:

1. **Порт 8001 занят** - старый процесс из `venv` не был остановлен
2. **404 Not Found** - возможно, старый процесс использует устаревшую версию кода
3. **"User not found"** - пользователь может отсутствовать в БД

## Решение:

### Шаг 1: Перезапуск сервиса

```bash
cd /opt/Choice/backend_fastapi
chmod +x restart_auth_service.sh
./restart_auth_service.sh
```

Или вручную:

```bash
# Убить все процессы на порту 8001
lsof -ti:8001 | xargs kill -9 2>/dev/null || fuser -k 8001/tcp 2>/dev/null || pkill -f "uvicorn.*8001"

# Подождать
sleep 3

# Запустить из .venv
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
PYTHONPATH="$(pwd)" .venv/bin/python -m uvicorn services.authentication.main:app --host 0.0.0.0 --port 8001 --reload > logs/authentication.log 2>&1 &
```

### Шаг 2: Диагностика

```bash
cd /opt/Choice/backend_fastapi
chmod +x check_auth_service.sh
./check_auth_service.sh
```

Этот скрипт проверит:
- ✓ Процессы и порты
- ✓ Health endpoint
- ✓ Маршруты
- ✓ Подключение к БД
- ✓ Наличие пользователя в БД
- ✓ Логи на ошибки

### Шаг 3: Проверка/создание пользователя

```bash
cd /opt/Choice/backend_fastapi
source .venv/bin/activate
python3 check_and_create_user.py
```

Этот скрипт:
- Проверит подключение к БД
- Проверит наличие пользователя `cp@gmail.com`
- Предложит создать пользователя, если его нет

### Шаг 4: Тестирование

```bash
# Health check
curl http://localhost:8001/health

# Проверка маршрутов
curl http://localhost:8001/docs

# Тестовый логин
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cp@gmail.com","password":"qwerty123"}'
```

## Возможные проблемы и решения:

### Проблема: "User not found"
**Решение:** Пользователь отсутствует в БД. Запустите `check_and_create_user.py` для создания.

### Проблема: 404 Not Found
**Решение:** 
1. Убедитесь, что сервис перезапущен из `.venv`
2. Проверьте логи: `tail -50 logs/authentication.log`
3. Проверьте, что маршрут доступен: `curl http://localhost:8001/docs`

### Проблема: Порт занят
**Решение:** Используйте скрипт `restart_auth_service.sh` - он автоматически найдет и убьет все процессы на порту 8001.

### Проблема: Ошибки подключения к БД
**Решение:**
1. Проверьте файл БД: `ls -lh choice.db`
2. Проверьте переменные окружения: `env | grep DATABASE`
3. Проверьте .env файл (если используется)

## Полезные команды:

```bash
# Просмотр логов в реальном времени
tail -f logs/authentication.log

# Проверка процессов
ps aux | grep uvicorn

# Проверка портов
lsof -i:8001
netstat -tulpn | grep 8001

# Проверка маршрутов через Swagger
# Откройте в браузере: http://77.95.203.148:8001/docs
```
