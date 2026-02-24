"""Роутеры для File Service"""
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.responses import FileResponse
from pydantic_settings import BaseSettings
import os
import uuid
from pathlib import Path

class FileSettings(BaseSettings):
    file_upload_path: str = "etc/files"
    max_file_size: int = 2 * 1024 * 1024  # 2MB
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

settings = FileSettings()
upload_path = Path(settings.file_upload_path)
upload_path.mkdir(parents=True, exist_ok=True)

router = APIRouter(prefix="/api/objects", tags=["file"])

@router.get("/{fileName}")
async def download_file(fileName: str):
    """Скачивание файла"""
    file_path = upload_path / fileName
    
    if not file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found"
        )
    
    # Определение типа файла
    extension = fileName.split('.')[-1] if '.' in fileName else 'png'
    media_type = f"image/{extension}"
    
    return FileResponse(
        path=str(file_path),
        media_type=media_type,
        filename=fileName
    )

@router.post("/{fileName}")
async def upload_file(
    fileName: str,
    file: UploadFile = File(...)
):
    """Загрузка файла"""
    # Проверка размера
    if file.size and file.size > settings.max_file_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large"
        )
    
    file_path = upload_path / fileName
    
    # Проверка, что файл не существует
    if file_path.exists():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File already exists"
        )
    
    # Сохранение файла
    try:
        content = await file.read()
        file_path.write_bytes(content)
        return {"message": "File uploaded successfully", "filename": fileName}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload file: {str(e)}"
        )

@router.post("/upload")
async def upload_file_auto(
    file: UploadFile = File(...)
):
    """Загрузка файла с автоматическим именем"""
    # Генерация уникального имени
    extension = file.filename.split('.')[-1] if '.' in file.filename else 'png'
    file_name = f"{uuid.uuid4()}.{extension}"
    
    file_path = upload_path / file_name
    
    # Проверка размера
    if file.size and file.size > settings.max_file_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large"
        )
    
    # Сохранение файла
    try:
        content = await file.read()
        file_path.write_bytes(content)
        return {"message": "File uploaded successfully", "filename": file_name}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload file: {str(e)}"
        )
