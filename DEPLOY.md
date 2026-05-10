# Развёртывание Choice App на Ubuntu Server

Полное руководство по развёртыванию backend-части на чистом Ubuntu сервере через GitHub.

## 📋 Содержание

- [Архитектура](#архитектура)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Пошаговая инструкция](#пошаговая-инструкция)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [SSL сертификаты](#ssl-сертификаты)
- [Резервное копирование](#резервное-копирование)
- [Устранение неполадок](#устранение-неполадок)

---

## Архитектура

Backend-only сервер поднимает PostgreSQL и FastAPI-сервисы. Flutter на сервере не нужен.

Клиенты ходят прямо в backend-сервисы по портам:

- `8001` - auth
- `8002` - client
- `8003` - company
- `8004` - category
- `8005` - ordering
- `8006` - chat / websocket
- `8007` - review
- `8008` - file

---

## 📦 Требования

### Минимальные (для тестирования)
- **CPU:** 2 ядра
- **RAM:** 4 GB
- **Disk:** 20 GB SSD
- **OS:** Ubuntu 22.04 LTS

### Рекомендуемые (для production)
- **CPU:** 4 ядра
- **RAM:** 8 GB
- **Disk:** 50 GB SSD
- **OS:** Ubuntu 22.04/24.04 LTS

### Необходимые порты
- `22` - SSH
- `8001-8008` - API и WebSocket сервисы
- `5432` - PostgreSQL, если нужен внешний доступ к БД

---

## Быстрый старт

Если у вас уже есть настроенный сервер с Docker:

```bash
# 1. Клонируйте репозиторий
git clone <your-repo-url> /opt/choice-app
cd /opt/choice-app

# 2. Настройте переменные окружения
cp .env.example .env
nano .env

# 3. Запустите деплой
./scripts/deploy.sh
```

---

## 📖 Пошаговая инструкция

### Шаг 1: Подготовка сервера

#### 1.1 Создайте VPS сервер

Рекомендуемые провайдеры:
- **DigitalOcean** - от $24/месяц (4GB RAM)
- **Hetzner** - от €7.51/месяц (4GB RAM) ⭐ лучшее соотношение цена/качество
- **AWS Lightsail** - от $10/месяц (2GB RAM)
- **Yandex Cloud** - для РФ

#### 1.2 Подключитесь к серверу

```bash
ssh root@YOUR_SERVER_IP
```

#### 1.3 Запустите инициализацию

```bash
# Скачайте и запустите скрипт инициализации
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/init-server.sh -o init.sh
chmod +x init.sh
./init.sh
```

Или вручную:

```bash
# Обновите систему
apt update && apt upgrade -y

# Установите Docker
curl -fsSL https://get.docker.com | sh

# Установите Docker Compose
apt install -y docker-compose-plugin

# Добавьте пользователя в группу docker
usermod -aG docker ubuntu

# Перезагрузите (для применения всех изменений)
reboot
```

---

### Шаг 2: Клонирование репозитория

```bash
# Подключитесь как ubuntu (не root!)
ssh ubuntu@YOUR_SERVER_IP

# Клонируйте репозиторий
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git /opt/choice-app
cd /opt/choice-app
```

---

### Шаг 3: Настройка переменных окружения

```bash
# Создайте .env файл
cp .env.example .env
nano .env
```

**Обязательно измените:**
```env
# Безопасность
JWT_SECRET_KEY=your-super-secret-random-key-here  # Генерируйте: openssl rand -hex 32
DB_PASSWORD=your-strong-database-password

# Хост для подсказок в deploy.sh
API_HOST=your-server-ip-or-domain.com
```

**Полный пример .env:**
```env
# Database
DB_USER=choice_user
DB_PASSWORD=super_secure_password_123
DB_NAME=choice_db

# Security
JWT_SECRET_KEY=abc123def456...  # 64 символа, сгенерированные openssl

# RabbitMQ (опционально)
RABBITMQ_ENABLED=false

# File storage
FILE_UPLOAD_PATH=/app/uploads

# Host label for deploy output
API_HOST=your-domain.com
```

---

### Шаг 4: Первый деплой

```bash
cd /opt/choice-app
./scripts/deploy.sh
```

Скрипт автоматически:
1. Подтянет свежий код
2. Соберёт Docker-образы backend
3. Поднимет PostgreSQL и backend на портах `8001..8008`
4. Проверит health endpoints

---

### Шаг 5: Настройка домена и SSL

#### 5.1 Настройте DNS

У вашего регистратора домена создайте A-запись:
```
Type: A
Name: app (или @ для корня)
Value: YOUR_SERVER_IP
TTL: 3600
```

#### 5.2 HTTPS и домен

В текущей backend-only схеме API публикуется напрямую на `8001..8008`.  
Если нужен HTTPS, его нужно ставить отдельным reverse proxy перед сервисами или переводить архитектуру на единый gateway.

---

## GitHub Actions CI/CD

### Настройка автоматического деплоя

#### 1. Добавьте Secrets в GitHub

В репозитории: **Settings → Secrets and variables → Actions**

| Secret | Описание |
|--------|----------|
| `SERVER_IP` | IP вашего сервера |
| `SERVER_USER` | Имя пользователя (обычно `ubuntu`) |
| `SSH_PRIVATE_KEY` | Приватный SSH ключ |
| `DB_USER` | Пользователь БД |
| `DB_NAME` | Имя базы данных |
| `SECRET_KEY` | Секретный ключ приложения |
| `API_HOST` | IP или домен сервера |

#### 2. Сгенерируйте SSH ключ

На вашем локальном компьютере:
```bash
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions
```

#### 3. Добавьте публичный ключ на сервер

```bash
ssh-copy-id -i ~/.ssh/github_actions.pub ubuntu@YOUR_SERVER_IP
```

#### 3. Приватный ключ добавьте в GitHub Secrets

```bash
cat ~/.ssh/github_actions
# Скопируйте вывод в GitHub Secret под именем SSH_PRIVATE_KEY
```

#### 4. Готово!

Теперь при каждом push в `main` или `master` ветку workflow:
1. подключается к серверу
2. запускает `./scripts/deploy.sh`
3. проверяет health у backend-сервисов

---

## 💾 Резервное копирование

### Автоматический бэкап базы

Добавьте в crontab:
```bash
# Откройте crontab
sudo crontab -e

# Добавьте строку (бэкап каждый день в 3:00)
0 3 * * * /opt/choice-app/scripts/backup.sh
```

Создайте скрипт backup.sh:
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Бэкап базы
docker exec choice_postgres pg_dump -U choice_user choice_db > $BACKUP_DIR/choice_db_$DATE.sql

# Удаление старых бэкапов (старше 7 дней)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

# Бэкап загруженных файлов
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /opt/choice-app/backend_fastapi/etc/files/
```

---

## 🔧 Устранение неполадок

### Проверка логов

```bash
# Все логи
docker compose logs

# Логи конкретного сервиса
docker compose logs auth_service
docker compose logs -f postgres  # в реальном времени
```

### Перезапуск сервисов

```bash
# Перезапуск всего
docker compose restart

# Перезапуск одного сервиса
docker compose restart auth_service

# Полная пересборка
docker compose down
docker compose up -d --build
```

### Проверка статуса

```bash
# Список контейнеров
docker ps

# Использование ресурсов
docker stats

# Проверка API
curl http://localhost:8001/health
curl http://localhost:8001/docs
```

### Очистка Docker

```bash
# Остановить всё
docker compose down

# Удалить неиспользуемые образы
docker system prune -a

# Удалить volumes (внимание - удалит данные!)
docker volume prune
```

### Частые проблемы

#### Порт занят
```bash
# Найдите процесс
sudo lsof -i :80
sudo lsof -i :8001

# Убейте процесс
sudo kill -9 <PID>
```

#### Permission denied
```bash
# Проверьте права
ls -la /opt/choice-app

# Исправьте
sudo chown -R ubuntu:ubuntu /opt/choice-app
```

#### База данных не подключается
```bash
# Проверьте переменные окружения
docker exec choice_postgres env

# Проверьте подключение
docker exec -it choice_postgres psql -U choice_user -d choice_db
```

---

## 📊 Мониторинг

### Установка базового мониторинга

```bash
# Установите netdata (веб-дашборд на порту 19999)
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Или используйте базовые команды
htop                    # процессы
iotop                   # диск
iftop                   # сеть
```

### Health checks

Все backend-сервисы проверяются напрямую:
- `http://server:8001/health`
- `http://server:8002/health`
- `http://server:8003/health`
- `http://server:8004/health`
- `http://server:8005/health`
- `http://server:8006/health`
- `http://server:8007/health`
- `http://server:8008/health`

Swagger:
- `http://server:8001/docs`

---

## 📝 Обновление приложения

### Через GitHub Actions (рекомендуется)

Просто сделайте push в main:
```bash
git add .
git commit -m "Update feature"
git push origin main
```

### Вручную на сервере

```bash
cd /opt/choice-app
git pull origin main
./scripts/deploy.sh
```

## Smoke-проверка после деплоя

Локально или на сервере после запуска backend можно проверить жизненный цикл:

```bash
python backend_fastapi/check_services.py
python backend_fastapi/seed_local_demo_data.py --host 127.0.0.1 --scheme http
cd backend_fastapi
python smoke_test_backend.py --host 127.0.0.1 --scheme http --client-email local_client@example.com --client-password Test1234! --company-email local_company_main@example.com --company-password Test1234!
```

---

## 🗑 Удаление приложения

```bash
cd /opt/choice-app

# Остановить и удалить контейнеры
docker compose down -v

# Удалить образы
docker rmi $(docker images -q)

# Удалить данные (внимание!)
sudo rm -rf /opt/choice-app
sudo rm -rf /opt/backups
```

---

## 📞 Поддержка

Если возникли проблемы:

1. Проверьте логи: `docker compose logs -f`
2. Проверьте статус: `docker ps`
3. Проверьте ресурсы: `htop`, `free -h`, `df -h`

---

**Готово!** Ваше приложение развёрнуто и работает 🎉
