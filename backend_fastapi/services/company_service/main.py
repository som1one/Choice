"""Главный файл Company Service"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import company
from .database import init_db

app = FastAPI(
    title="Company Service",
    description="Сервис управления компаниями",
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
app.include_router(company.router)

@app.get("/")
async def root():
    return {"message": "Company Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
