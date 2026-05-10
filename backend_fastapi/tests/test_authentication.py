"""Тесты для Authentication Service"""
import pytest
from fastapi import status
from services.authentication.models import User, UserType
from common.security import verify_password

@pytest.mark.auth
class TestAuthentication:
    """Тесты аутентификации"""
    
    def test_register_client(self, auth_client, test_db):
        """Тест регистрации клиента"""
        response = auth_client.post(
            "/api/auth/register",
            json={
                "email": "newclient@test.com",
                "password": "password123",
                "type": "Client",
                "name": "New Client",
                "city": "Moscow",
                "street": "Test Street"
            }
        )
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
        data = response.json()
        assert "access_token" in data
        assert data["access_token"] is not None
    
    def test_register_company(self, auth_client, test_db):
        """Тест регистрации компании"""
        response = auth_client.post(
            "/api/auth/register",
            json={
                "email": "newcompany@test.com",
                "password": "password123",
                "type": "Company",
                "name": "New Company",
                "city": "Moscow",
                "street": "Test Street"
            }
        )
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
        data = response.json()
        assert "access_token" in data
        assert data["access_token"] is not None
    
    def test_register_duplicate_email(self, auth_client, test_client_user):
        """Тест регистрации с существующим email"""
        response = auth_client.post(
            "/api/auth/register",
            json={
                "email": test_client_user.email,
                "password": "password123",
                "type": "Client",
                "name": "Duplicate",
                "city": "Moscow",
                "street": "Test Street"
            }
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    def test_login_success(self, auth_client, test_client_user):
        """Тест успешного входа"""
        response = auth_client.post(
            "/api/auth/login",
            json={
                "email": test_client_user.email,
                "password": "client123"
            }
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
    
    def test_login_wrong_password(self, auth_client, test_client_user):
        """Тест входа с неверным паролем"""
        response = auth_client.post(
            "/api/auth/login",
            json={
                "email": test_client_user.email,
                "password": "wrongpassword"
            }
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_login_nonexistent_user(self, auth_client):
        """Тест входа несуществующего пользователя"""
        response = auth_client.post(
            "/api/auth/login",
            json={
                "email": "nonexistent@test.com",
                "password": "password123"
            }
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_get_current_user(self, auth_client, client_token, test_client_user):
        """Тест получения текущего пользователя"""
        response = auth_client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {client_token}"}
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["email"] == test_client_user.email
        assert data["user_type"] == "Client"
    
    def test_get_current_user_invalid_token(self, auth_client):
        """Тест получения пользователя с неверным токеном"""
        response = auth_client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer invalid_token"}
        )
        # Может быть 401 или 404 в зависимости от реализации
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_404_NOT_FOUND]
    
    def test_change_password(self, auth_client, client_token, test_client_user, test_db):
        """Тест смены пароля"""
        response = auth_client.put(
            "/api/auth/changePassword",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "old_password": "client123",
                "new_password": "newpassword123"
            }
        )
        assert response.status_code == status.HTTP_200_OK
        
        # Проверяем, что пароль изменился
        test_db.refresh(test_client_user)
        assert verify_password("newpassword123", test_client_user.password_hash)
    
    def test_change_password_wrong_old(self, auth_client, client_token):
        """Тест смены пароля с неверным старым паролем"""
        response = auth_client.put(
            "/api/auth/changePassword",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "old_password": "wrongpassword",
                "new_password": "newpassword123"
            }
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
