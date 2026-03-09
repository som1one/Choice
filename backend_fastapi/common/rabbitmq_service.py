"""Сервис для работы с RabbitMQ - публикация и подписка на события"""
import os
import json
import logging
from typing import Optional, Dict, Any, Callable, Awaitable
from aio_pika import connect_robust, Message, DeliveryMode, Connection
from aio_pika.abc import AbstractChannel, AbstractExchange, AbstractQueue, AbstractIncomingMessage
from pydantic_settings import BaseSettings
import asyncio

logger = logging.getLogger(__name__)

class RabbitMQSettings(BaseSettings):
    """Настройки RabbitMQ"""
    rabbitmq_host: str = "localhost"
    rabbitmq_port: int = 5672
    rabbitmq_user: str = "guest"
    rabbitmq_password: str = "guest"
    rabbitmq_vhost: str = "/"
    rabbitmq_exchange: str = "choice_events"  # Имя exchange для событий
    rabbitmq_enabled: bool = True  # Можно отключить через env
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"

settings = RabbitMQSettings()

# Глобальные переменные для подключения
_connection: Optional[Connection] = None
_channel: Optional[AbstractChannel] = None
_exchange: Optional[AbstractExchange] = None
_connection_lock = asyncio.Lock()
_consumers: list[asyncio.Task] = []  # Список задач consumers

async def get_connection() -> Optional[Connection]:
    """Получить подключение к RabbitMQ"""
    global _connection
    
    if not settings.rabbitmq_enabled:
        return None
    
    if _connection is None or _connection.is_closed:
        try:
            connection_url = (
                f"amqp://{settings.rabbitmq_user}:{settings.rabbitmq_password}"
                f"@{settings.rabbitmq_host}:{settings.rabbitmq_port}{settings.rabbitmq_vhost}"
            )
            _connection = await connect_robust(connection_url)
            logger.info(f"Connected to RabbitMQ at {settings.rabbitmq_host}:{settings.rabbitmq_port}")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            return None
    
    return _connection

async def get_channel() -> Optional[AbstractChannel]:
    """Получить канал RabbitMQ"""
    global _channel
    
    if not settings.rabbitmq_enabled:
        return None
    
    connection = await get_connection()
    if connection is None:
        return None
    
    if _channel is None or _channel.is_closed:
        try:
            _channel = await connection.channel()
            logger.debug("RabbitMQ channel created")
        except Exception as e:
            logger.error(f"Failed to create RabbitMQ channel: {e}")
            return None
    
    return _channel

async def get_exchange() -> Optional[AbstractExchange]:
    """Получить exchange для событий"""
    global _exchange
    
    if not settings.rabbitmq_enabled:
        return None
    
    channel = await get_channel()
    if channel is None:
        return None
    
    # Пересоздаем exchange если его нет
    # Если канал был пересоздан, get_channel() уже создал новый канал,
    # поэтому нужно пересоздать exchange на новом канале
    if _exchange is None:
        try:
            # Создаем topic exchange для гибкой маршрутизации
            _exchange = await channel.declare_exchange(
                settings.rabbitmq_exchange,
                type="topic",
                durable=True,  # Exchange сохраняется после перезапуска
            )
            logger.debug(f"RabbitMQ exchange '{settings.rabbitmq_exchange}' declared")
        except Exception as e:
            logger.error(f"Failed to declare RabbitMQ exchange: {e}")
            _exchange = None
            return None
    
    return _exchange

async def publish_event(
    event_type: str,
    event_data: Dict[str, Any],
    routing_key: Optional[str] = None
) -> bool:
    """
    Опубликовать событие в RabbitMQ
    
    Args:
        event_type: Тип события (например, "UserCreatedEvent")
        event_data: Данные события (словарь)
        routing_key: Ключ маршрутизации (по умолчанию = event_type)
    
    Returns:
        True если событие успешно опубликовано, False в противном случае
    """
    if not settings.rabbitmq_enabled:
        logger.debug(f"RabbitMQ disabled, skipping event: {event_type}")
        return False
    
    exchange = await get_exchange()
    if exchange is None:
        logger.warning(f"RabbitMQ exchange not available, skipping event: {event_type}")
        return False
    
    try:
        # Формируем полное сообщение
        import time
        message_body = {
            "event_type": event_type,
            "data": event_data,
            "timestamp": time.time(),
        }
        
        # Используем event_type как routing_key по умолчанию
        if routing_key is None:
            routing_key = event_type
        
        # Создаем сообщение
        message = Message(
            json.dumps(message_body).encode('utf-8'),
            delivery_mode=DeliveryMode.PERSISTENT,  # Сообщение сохраняется на диск
            content_type="application/json",
            headers={
                "event_type": event_type,
                "timestamp": str(message_body.get("timestamp", "")),
            }
        )
        
        # Публикуем сообщение
        await exchange.publish(
            message,
            routing_key=routing_key,
        )
        
        logger.info(f"Published event: {event_type} with routing_key: {routing_key}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to publish event {event_type}: {e}")
        return False

async def close_connection():
    """Закрыть подключение к RabbitMQ"""
    global _connection, _channel, _exchange
    
    try:
        if _channel and not _channel.is_closed:
            await _channel.close()
            _channel = None
        
        if _connection and not _connection.is_closed:
            await _connection.close()
            _connection = None
        
        _exchange = None
        logger.info("RabbitMQ connection closed")
    except Exception as e:
        logger.error(f"Error closing RabbitMQ connection: {e}")

# Функция для синхронной публикации (обертка для использования в синхронном коде)
def publish_event_sync(
    event_type: str,
    event_data: Dict[str, Any],
    routing_key: Optional[str] = None
) -> bool:
    """
    Синхронная обертка для публикации событий
    Используется в синхронных функциях FastAPI
    """
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # Если цикл уже запущен, создаем задачу
            asyncio.create_task(publish_event(event_type, event_data, routing_key))
            return True
        else:
            # Если цикл не запущен, запускаем его
            return loop.run_until_complete(publish_event(event_type, event_data, routing_key))
    except RuntimeError:
        # Если нет event loop, создаем новый
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(publish_event(event_type, event_data, routing_key))
            loop.close()
            return result
        except Exception as e:
            logger.error(f"Failed to publish event synchronously: {e}")
            return False
    except Exception as e:
        logger.error(f"Failed to publish event synchronously: {e}")
        return False

async def consume_event(
    event_type: str,
    queue_name: str,
    handler: Callable[[Dict[str, Any]], Awaitable[None]],
    routing_key: Optional[str] = None
) -> Optional[asyncio.Task]:
    """
    Подписаться на событие из RabbitMQ
    
    Args:
        event_type: Тип события для подписки (например, "UserCreatedEvent")
        queue_name: Имя очереди для подписки
        handler: Асинхронная функция-обработчик события (принимает event_data)
        routing_key: Ключ маршрутизации (по умолчанию = event_type)
    
    Returns:
        Task для consumer или None в случае ошибки
    """
    if not settings.rabbitmq_enabled:
        logger.debug(f"RabbitMQ disabled, skipping consumer for: {event_type}")
        return None
    
    if routing_key is None:
        routing_key = event_type
    
    async def message_handler(message: AbstractIncomingMessage):
        """Обработчик входящих сообщений"""
        async with message.process():
            try:
                # Парсим JSON сообщение
                body = json.loads(message.body.decode('utf-8'))
                event_data = body.get("data", {})
                
                # Проверяем тип события
                if body.get("event_type") == event_type:
                    logger.info(f"Received event: {event_type}")
                    await handler(event_data)
                else:
                    logger.debug(f"Received event type {body.get('event_type')}, expected {event_type}, ignoring")
                    
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse message: {e}")
                # message.process() автоматически обработает ошибку
                raise
            except Exception as e:
                logger.error(f"Error processing message for {event_type}: {e}")
                # message.process() автоматически обработает ошибку и вернет сообщение в очередь
                raise
    
    async def start_consumer():
        """Запуск consumer с автоматическим переподключением"""
        retry_delay = 5  # секунд
        
        while True:
            try:
                # Не сбрасываем глобальные переменные - функции get_channel() и get_exchange()
                # автоматически проверяют состояние соединения и переподключаются при необходимости
                # Это позволяет нескольким consumers безопасно использовать общие ресурсы
                
                channel = await get_channel()
                if channel is None:
                    logger.error(f"Failed to get channel for consumer: {event_type}")
                    await asyncio.sleep(retry_delay)
                    continue
                
                exchange = await get_exchange()
                if exchange is None:
                    logger.error(f"Failed to get exchange for consumer: {event_type}")
                    await asyncio.sleep(retry_delay)
                    continue
                
                # Создаем очередь
                queue = await channel.declare_queue(
                    queue_name,
                    durable=True,  # Очередь сохраняется после перезапуска
                )
                
                # Привязываем очередь к exchange с routing_key
                await queue.bind(exchange, routing_key=routing_key)
                
                logger.info(f"Started consumer for {event_type} on queue {queue_name}")
                
                # Начинаем слушать очередь (блокирующий вызов)
                await queue.consume(message_handler)
                
                # Если дошли сюда, значит соединение разорвано
                logger.warning(f"Consumer for {event_type} disconnected, reconnecting...")
                await asyncio.sleep(retry_delay)
                
            except asyncio.CancelledError:
                logger.info(f"Consumer for {event_type} cancelled")
                break
            except Exception as e:
                logger.error(f"Error in consumer for {event_type}: {e}, reconnecting in {retry_delay}s...")
                await asyncio.sleep(retry_delay)
    
    # Создаем задачу для consumer
    task = asyncio.create_task(start_consumer())
    _consumers.append(task)
    return task

async def stop_all_consumers():
    """Остановить все consumers"""
    global _consumers
    for task in _consumers:
        if not task.done():
            task.cancel()
    _consumers = []
    logger.info("All consumers stopped")
