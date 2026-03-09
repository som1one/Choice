"""Главный файл Authentication Service"""
import sys
from pathlib import Path

# Добавить корневую директорию в путь для импортов
current_file = Path(__file__).resolve()
project_root = current_file.parent.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Импорты с fallback на относительные
try:
    from services.authentication.routers import auth
    from services.authentication.database import init_db
except ImportError:
    from .routers import auth
    from .database import init_db

app = FastAPI(
    title="Authentication Service",
    description="Сервис аутентификации и авторизации",
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
app.include_router(auth.router)

# Инициализация RabbitMQ consumers
@app.on_event("startup")
async def startup_event():
    """Запуск consumers при старте приложения"""
    try:
        from services.authentication.consumers import start_consumers
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
    return {"message": "Authentication Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
