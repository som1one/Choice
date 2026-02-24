"""Главный файл File Service"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import file

app = FastAPI(
    title="File Service",
    description="Сервис загрузки и хранения файлов",
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

# Роутеры
app.include_router(file.router)

@app.get("/")
async def root():
    return {"message": "File Service", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8008)
