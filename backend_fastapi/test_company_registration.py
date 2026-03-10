#!/usr/bin/env python3
"""Тест для регистрации компании"""
import pytest
import sys
import os
from pathlib import Path

# Добавляем корневую директорию в путь
project_root = Path(__file__).parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

# Принудительно используем SQLite для тестов
os.environ["DATABASE_URL"] = "sqlite:///./test_choice.db"

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from common.database import get_db, Base, engine
from services.authentication.models import User, UserType
from services.company_service.models import Company
from services.authentication.main import app

# Инициализируем БД для тестов
@pytest.fixture(scope="module", autouse=True)
def setup_database():
    """Создает таблицы перед тестами и удаляет после"""
    # Создаем все таблицы
    Base.metadata.create_all(bind=engine)
    yield
    # Очищаем после тестов
    Base.metadata.drop_all(bind=engine)
    # Удаляем тестовый файл БД
    test_db_path = Path("test_choice.db")
    if test_db_path.exists():
        test_db_path.unlink()

@pytest.fixture
def client():
    """Создает тестовый клиент"""
    return TestClient(app)

def test_company_registration_success(client: TestClient):
    """Тест успешной регистрации компании"""
    # Данные для регистрации
    registration_data = {
        "email": "testcompany@example.com",
        "name": "Тестовая Компания",
        "password": "Test1234!",
        "street": "Ленина",
        "city": "Москва",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    # Регистрация
    response = client.post("/api/auth/register", json=registration_data)
    
    # Проверяем успешность регистрации
    assert response.status_code == 200, f"Ожидался статус 200, получен {response.status_code}. Ответ: {response.text}"
    
    # Проверяем, что вернулся токен
    data = response.json()
    assert "access_token" in data, "Токен не найден в ответе"
    assert data["access_token"] is not None, "Токен пустой"
    
    # Проверяем, что пользователь создан в БД
    db = next(get_db())
    try:
        user = db.query(User).filter(User.email == registration_data["email"]).first()
        assert user is not None, "Пользователь не создан в БД"
        assert user.user_type == UserType.COMPANY, "Тип пользователя неверный"
        assert user.user_name == registration_data["name"], "Имя пользователя неверное"
        
        # Проверяем, что компания создана в БД
        company = db.query(Company).filter(Company.guid == str(user.id)).first()
        assert company is not None, "Компания не создана в БД"
        assert company.title == registration_data["name"], "Название компании неверное"
        assert company.email == registration_data["email"], "Email компании неверный"
        assert company.phone_number == registration_data["phone_number"], "Телефон компании неверный"
        assert company.city == registration_data["city"], "Город компании неверный"
        assert company.street == registration_data["street"], "Улица компании неверная"
        assert company.coordinates is not None and company.coordinates != "", "Координаты компании не установлены"
    finally:
        db.close()
    
    print("✅ Тест успешной регистрации компании пройден")

def test_company_registration_with_empty_phone(client: TestClient):
    """Тест регистрации компании с пустым телефоном"""
    registration_data = {
        "email": "testcompany2@example.com",
        "name": "Тестовая Компания 2",
        "password": "Test1234!",
        "street": "Пушкина",
        "city": "Санкт-Петербург",
        "phone_number": None,
        "type": "Company"
    }
    
    response = client.post("/api/auth/register", json=registration_data)
    
    assert response.status_code == 200, f"Ожидался статус 200, получен {response.status_code}. Ответ: {response.text}"
    
    # Проверяем, что компания создана с дефолтным телефоном
    db = next(get_db())
    try:
        user = db.query(User).filter(User.email == registration_data["email"]).first()
        assert user is not None, "Пользователь не создан в БД"
        
        company = db.query(Company).filter(Company.guid == str(user.id)).first()
        assert company is not None, "Компания не создана в БД"
        assert company.phone_number == "0000000000", "Телефон компании должен быть дефолтным"
    finally:
        db.close()
    
    print("✅ Тест регистрации компании с пустым телефоном пройден")

def test_company_registration_duplicate_email(client: TestClient):
    """Тест регистрации компании с дублирующимся email"""
    registration_data = {
        "email": "duplicate@example.com",
        "name": "Первая Компания",
        "password": "Test1234!",
        "street": "Ленина",
        "city": "Москва",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    # Первая регистрация
    response1 = client.post("/api/auth/register", json=registration_data)
    assert response1.status_code == 200, "Первая регистрация должна быть успешной"
    
    # Вторая регистрация с тем же email
    response2 = client.post("/api/auth/register", json=registration_data)
    assert response2.status_code == 400, "Вторая регистрация должна вернуть ошибку 400"
    
    print("✅ Тест регистрации компании с дублирующимся email пройден")

def test_company_registration_empty_city_street(client: TestClient):
    """Тест регистрации компании с пустыми городом и улицей"""
    registration_data = {
        "email": "testcompany3@example.com",
        "name": "Тестовая Компания 3",
        "password": "Test1234!",
        "street": "",
        "city": "",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    response = client.post("/api/auth/register", json=registration_data)
    
    assert response.status_code == 200, f"Ожидался статус 200, получен {response.status_code}. Ответ: {response.text}"
    
    # Проверяем, что компания создана с дефолтными значениями
    db = next(get_db())
    try:
        user = db.query(User).filter(User.email == registration_data["email"]).first()
        assert user is not None, "Пользователь не создан в БД"
        
        company = db.query(Company).filter(Company.guid == str(user.id)).first()
        assert company is not None, "Компания не создана в БД"
        assert company.city == "-", "Город компании должен быть дефолтным"
        assert company.street == "-", "Улица компании должна быть дефолтной"
        assert company.coordinates is not None and company.coordinates != "", "Координаты компании не установлены"
    finally:
        db.close()
    
    print("✅ Тест регистрации компании с пустыми городом и улицей пройден")

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
