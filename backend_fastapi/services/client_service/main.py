"""Главный файл Client Service"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import client
from .database import init_db

app = FastAPI(
    title="Client Service",
    description="Сервис управления клиентами и заявками",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Инициализация БД
init_db()

# Роутеры
app.include_router(client.router)

# Инициализация RabbitMQ consumers
@app.on_event("startup")
async def startup_event():
    """Запуск consumers при старте приложения"""
    try:
        from services.client_service.consumers import start_consumers
        await start_consumers()
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Failed to start RabbitMQ consumers: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Остановка consumers при завершении приложения"""
    try:
        from common.rabbitmq_service import stop_all_consumers, close_connection
        await stop_all_consumers()
        await close_connection()
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Error during shutdown: {e}")

@app.get("/")
async def root():
    return {"message": "Client Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
