"""Главный файл Chat Service"""
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from common.database import get_db
from .routers import message
from .websocket import websocket_endpoint
from .database import init_db
from sqlalchemy.orm import Session

app = FastAPI(
    title="Chat Service",
    description="Сервис чата и real-time коммуникации",
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
app.include_router(message.router)

# WebSocket endpoint
@app.websocket("/ws/chat")
async def chat_websocket(websocket: WebSocket, token: str):
    from common.database import SessionLocal
    db = SessionLocal()
    try:
        await websocket_endpoint(websocket, token, db)
    finally:
        db.close()

@app.get("/")
async def root():
    return {"message": "Chat Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8006)
