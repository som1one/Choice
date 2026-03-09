# Настройка RabbitMQ

## Описание

RabbitMQ интегрирован во все сервисы для публикации событий в событийно-ориентированной архитектуре.

## Переменные окружения

Добавьте в `.env` файл следующие переменные:

```env
# RabbitMQ настройки
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/
RABBITMQ_EXCHANGE=choice_events
RABBITMQ_ENABLED=true
```

### Описание переменных:

- `RABBITMQ_HOST` - адрес сервера RabbitMQ (по умолчанию: localhost)
- `RABBITMQ_PORT` - порт RabbitMQ (по умолчанию: 5672)
- `RABBITMQ_USER` - имя пользователя (по умолчанию: guest)
- `RABBITMQ_PASSWORD` - пароль (по умолчанию: guest)
- `RABBITMQ_VHOST` - виртуальный хост (по умолчанию: /)
- `RABBITMQ_EXCHANGE` - имя exchange для событий (по умолчанию: choice_events)
- `RABBITMQ_ENABLED` - включить/выключить RabbitMQ (по умолчанию: true)

## Установка RabbitMQ

### Linux (Ubuntu/Debian):

```bash
sudo apt-get update
sudo apt-get install -y rabbitmq-server
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
```

### Docker:

```bash
docker run -d --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  rabbitmq:3-management
```

### Windows:

1. Скачайте установщик с [официального сайта](https://www.rabbitmq.com/download.html)
2. Установите Erlang/OTP (требуется для RabbitMQ)
3. Установите RabbitMQ
4. Запустите службу RabbitMQ

## Управление RabbitMQ

### Запуск/остановка:

```bash
# Linux
sudo systemctl start rabbitmq-server
sudo systemctl stop rabbitmq-server

# Windows (через службы)
net start RabbitMQ
net stop RabbitMQ
```

### Веб-интерфейс управления:

Откройте в браузере: http://localhost:15672

Логин по умолчанию: `guest` / `guest`

## События, публикуемые в RabbitMQ

### Authentication Service:

1. **UserAuthenticatedEvent** - при входе пользователя
   - `user_id`, `email`, `user_type`, `device_token`

2. **UserCreatedEvent** - при регистрации пользователя
   - `user_id`, `user_name`, `email`, `city`, `street`, `phone_number`, `user_type`, `device_token`

### Client Service:

3. **UserDataChangedEvent** - при изменении данных клиента
   - `user_id`, `user_type`, `email`, `name`, `surname`, `phone_number`, `city`, `street`

4. **UserIconUriChangedEvent** - при изменении иконки клиента
   - `user_id`, `user_type`, `icon_uri`

5. **UserDeletedEvent** - при удалении клиента
   - `user_id`, `user_type`, `email`

6. **OrderRequestSentEvent** - при отправке заявки клиентом
   - `order_request_id`, `client_id`, `category_id`, `description`, `search_radius`

### Company Service:

7. **UserDataChangedEvent** - при изменении данных компании
   - `user_id`, `user_type`, `email`, `title`, `phone_number`, `city`, `street`

8. **UserIconUriChangedEvent** - при изменении иконки компании
   - `user_id`, `user_type`, `icon_uri`

9. **UserDeletedEvent** - при удалении компании
   - `user_id`, `user_type`, `email`

10. **CompanyDataFilledEvent** - при заполнении данных компании
    - `company_id`, `email`, `title`, `is_data_filled`, `categories_id`

### Ordering Service:

11. **OrderCreatedEvent** - при создании заказа
    - `order_id`, `order_request_id`, `client_id`, `company_id`, `price`, `deadline`

12. **UserEnrolledEvent** - при записи клиента на услугу
    - `order_id`, `client_id`, `company_id`, `enrollment_date`

13. **OrderEnrollmentDateConfirmedEvent** - при подтверждении даты записи
    - `order_id`, `client_id`, `company_id`, `enrollment_date`

14. **OrderEnrollmentDateChangedEvent** - при изменении даты записи
    - `order_id`, `client_id`, `company_id`, `enrollment_date`

15. **OrderStatusChangedEvent** - при изменении статуса заказа
    - `order_id`, `client_id`, `company_id`, `status`, `old_status`

### Review Service:

16. **ReviewLeftEvent** - при оставлении отзыва
    - `review_id`, `reviewer_id`, `reviewed_id`, `grade`, `review_type`

## Формат сообщений

Все события публикуются в формате JSON:

```json
{
  "event_type": "UserCreatedEvent",
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    ...
  },
  "timestamp": 1234567890.123
}
```

## Отключение RabbitMQ

Если RabbitMQ не нужен, установите в `.env`:

```env
RABBITMQ_ENABLED=false
```

В этом случае все события будут игнорироваться, но приложение продолжит работать нормально.

## Обработка ошибок

Сервис RabbitMQ обрабатывает все ошибки gracefully:
- Если RabbitMQ недоступен, события просто не публикуются (логируется предупреждение)
- Приложение продолжает работать нормально
- Ошибки не прерывают выполнение основного кода

## Consumers (обработчики событий)

В FastAPI backend реализованы consumers для синхронизации данных между сервисами:

### Authentication Service:
- **UserDataChangedEvent** - обновляет данные пользователя (email, name, phone, city, street)
- **UserIconUriChangedEvent** - обновляет icon_uri пользователя
- **UserDeletedEvent** - удаляет пользователя

### Client Service:
- **UserCreatedEvent** - создает клиента при регистрации пользователя типа Client
- **UserDataChangedEvent** - обновляет данные клиента
- **UserIconUriChangedEvent** - обновляет icon_uri клиента
- **UserDeletedEvent** - удаляет клиента

### Company Service:
- **UserCreatedEvent** - создает компанию при регистрации пользователя типа Company
- **UserDataChangedEvent** - обновляет данные компании
- **UserIconUriChangedEvent** - обновляет icon_uri компании
- **UserDeletedEvent** - удаляет компанию
- **ReviewLeftEvent** - обновляет средний рейтинг компании

Consumers автоматически запускаются при старте каждого сервиса и подписываются на соответствующие очереди в RabbitMQ.

## Мониторинг

Для мониторинга событий можно:
1. Использовать веб-интерфейс RabbitMQ (http://localhost:15672)
2. Просматривать логи приложения для отслеживания обработки событий
3. Проверять очереди в веб-интерфейсе RabbitMQ

## Тестирование

Для тестирования можно использовать RabbitMQ Management Plugin:

```bash
# Включить плагин управления
sudo rabbitmq-plugins enable rabbitmq_management

# Открыть веб-интерфейс
# http://localhost:15672
```

В веб-интерфейсе можно:
- Просматривать очереди
- Просматривать сообщения
- Мониторить производительность
- Управлять пользователями и правами
