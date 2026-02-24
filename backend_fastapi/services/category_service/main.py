"""Главный файл Category Service"""
import sys
from pathlib import Path

# Добавить корневую директорию в путь
root_dir = Path(__file__).parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Импорты с относительными путями
from services.category_service.routers import category
from services.category_service.database import init_db
from services.category_service.seed_data import seed_categories

app = FastAPI(
    title="Category Service",
    description="Сервис управления категориями услуг",
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
seed_categories()

# Роутеры
app.include_router(category.router)

@app.get("/")
async def root():
    return {"message": "Category Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8004)
