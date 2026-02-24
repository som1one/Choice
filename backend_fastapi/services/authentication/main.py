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

@app.get("/")
async def root():
    return {"message": "Authentication Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
