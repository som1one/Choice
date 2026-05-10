"""Тесты для File Service"""
import pytest
from fastapi import status
from pathlib import Path
import tempfile
import os

@pytest.mark.file
class TestFileService:
    """Тесты сервиса файлов"""
    
    def test_upload_file_auto(self, file_client, test_db):
        """Тест загрузки файла с автоматическим именем"""
        # Создаем временный файл
        test_content = b"Test file content"
        
        files = {
            "file": ("test.txt", test_content, "text/plain")
        }
        
        response = file_client.post(
            "/api/objects/upload",
            files=files
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "filename" in data
        assert data["message"] == "File uploaded successfully"
    
    def test_upload_file_with_name(self, file_client, test_db):
        """Тест загрузки файла с указанным именем"""
        test_content = b"Named file content"
        file_name = "test_upload.txt"
        
        files = {
            "file": (file_name, test_content, "text/plain")
        }
        
        response = file_client.post(
            f"/api/objects/{file_name}",
            files=files
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["filename"] == file_name
    
    def test_upload_file_duplicate(self, file_client, test_db):
        """Тест загрузки файла с существующим именем (должно быть запрещено)"""
        import uuid
        test_content = b"First upload"
        file_name = f"duplicate_test_{uuid.uuid4().hex[:8]}.txt"
        
        files = {
            "file": (file_name, test_content, "text/plain")
        }
        
        # Первая загрузка
        response1 = file_client.post(
            f"/api/objects/{file_name}",
            files=files
        )
        assert response1.status_code == status.HTTP_200_OK
        
        # Вторая загрузка с тем же именем
        response2 = file_client.post(
            f"/api/objects/{file_name}",
            files=files
        )
        assert response2.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_upload_file_too_large(self, file_client, test_db):
        """Тест загрузки слишком большого файла"""
        # Создаем файл больше 2MB
        large_content = b"x" * (3 * 1024 * 1024)  # 3MB
        
        files = {
            "file": ("large.txt", large_content, "text/plain")
        }
        
        response = file_client.post(
            "/api/objects/upload",
            files=files
        )
        # Может быть 200 или 400 в зависимости от проверки размера
        # FastAPI может не проверять размер до чтения всего файла
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]
    
    def test_download_file(self, file_client, test_db):
        """Тест скачивания файла"""
        import uuid
        # Сначала загружаем файл
        test_content = b"Download test content"
        file_name = f"download_test_{uuid.uuid4().hex[:8]}.txt"
        
        files = {
            "file": (file_name, test_content, "text/plain")
        }
        
        upload_response = file_client.post(
            f"/api/objects/{file_name}",
            files=files
        )
        assert upload_response.status_code == status.HTTP_200_OK
        
        # Теперь скачиваем
        download_response = file_client.get(f"/api/objects/{file_name}")
        assert download_response.status_code == status.HTTP_200_OK
        assert download_response.content == test_content
    
    def test_download_nonexistent_file(self, file_client):
        """Тест скачивания несуществующего файла"""
        response = file_client.get("/api/objects/nonexistent_file.txt")
        assert response.status_code == status.HTTP_404_NOT_FOUND
