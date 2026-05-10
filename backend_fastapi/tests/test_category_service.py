"""Тесты для Category Service"""
import pytest
from fastapi import status

@pytest.mark.category
class TestCategoryService:
    """Тесты сервиса категорий"""
    
    def test_get_categories(self, category_client, test_db):
        """Тест получения всех категорий"""
        response = category_client.get("/api/category/get")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), list)
    
    def test_create_category(self, category_client, admin_token):
        """Тест создания категории (админ)"""
        response = category_client.post(
            "/api/category/create",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "title": "Test Category",
                "icon_uri": "https://example.com/icon.png"
            }
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["title"] == "Test Category"
        assert "id" in data
    
    def test_create_category_unauthorized(self, category_client, client_token):
        """Тест создания категории без прав админа"""
        response = category_client.post(
            "/api/category/create",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "title": "Test Category",
                "icon_uri": "https://example.com/icon.png"
            }
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    def test_update_category(self, category_client, admin_token, test_db):
        """Тест обновления категории"""
        # Сначала создаем категорию
        create_response = category_client.post(
            "/api/category/create",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "title": "Original Category",
                "icon_uri": "https://example.com/icon.png"
            }
        )
        category_id = create_response.json()["id"]
        
        # Обновляем категорию
        response = category_client.put(
            "/api/category/update",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "id": category_id,
                "title": "Updated Category",
                "icon_uri": "https://example.com/new_icon.png"
            }
        )
        assert response.status_code == status.HTTP_200_OK
    
    def test_update_system_category(self, category_client, admin_token):
        """Тест обновления системной категории (должно быть запрещено)"""
        response = category_client.put(
            "/api/category/update",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "id": 1,  # Системная категория
                "title": "Hacked Category",
                "icon_uri": "https://example.com/icon.png"
            }
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_delete_category(self, category_client, admin_token, test_db):
        """Тест удаления категории"""
        # Сначала создаем категорию
        create_response = category_client.post(
            "/api/category/create",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "title": "To Delete",
                "icon_uri": "https://example.com/icon.png"
            }
        )
        category_id = create_response.json()["id"]
        
        # Удаляем категорию
        response = category_client.delete(
            f"/api/category/delete?category_id={category_id}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        assert response.status_code == status.HTTP_200_OK
    
    def test_delete_system_category(self, category_client, admin_token):
        """Тест удаления системной категории (должно быть запрещено)"""
        response = category_client.delete(
            "/api/category/delete?category_id=1",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
