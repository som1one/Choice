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

@app.get("/")
async def root():
    return {"message": "Client Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
