#!/usr/bin/env python3
"""Детальная диагностика регистрации"""
import sys
import traceback
import asyncio

def test_company_creation():
    """Тестирует создание Company напрямую"""
    print("=== Testing Company creation ===")
    try:
        from common.database import SessionLocal, engine
        from services.company_service.models import Company
        import uuid
        
        print(f"Database: {engine.url}")
        
        db = SessionLocal()
        
        # Пробуем создать компанию
        test_guid = str(uuid.uuid4())
        print(f"Creating company with guid: {test_guid}")
        
        company = Company(
            guid=test_guid,
            title="Test Company",
            phone_number="1234567890",
            email="test@test.com",
            city="Test City",
            street="Test Street",
            coordinates="55.7558,37.6173",
            social_medias=[],
            photo_uris=[],
            categories_id=[]
        )
        
        print("Company object created")
        db.add(company)
        print("Company added to session")
        db.commit()
        print("✓ Company committed successfully")
        
        # Проверяем
        db.refresh(company)
        print(f"✓ Company ID: {company.id}, Title: {company.title}")
        
        # Удаляем тестовую компанию
        db.delete(company)
        db.commit()
        print("✓ Test company deleted")
        
        db.close()
        return True
    except Exception as e:
        print(f"✗ Error creating Company: {e}")
        traceback.print_exc()
        return False

def test_user_creation():
    """Тестирует создание User"""
    print("\n=== Testing User creation ===")
    try:
        from common.database import SessionLocal
        from services.authentication.models import User, UserType
        import uuid
        from services.authentication.utils import get_password_hash
        
        db = SessionLocal()
        
        test_user = User(
            id=uuid.uuid4(),
            email="testuser@test.com",
            user_name="Test User",
            phone_number="1234567890",
            city="Test City",
            street="Test Street",
            user_type=UserType.COMPANY,
            password_hash=get_password_hash("Test1234!")
        )
        
        db.add(test_user)
        db.commit()
        print("✓ User created successfully")
        
        db.refresh(test_user)
        print(f"✓ User ID: {test_user.id}, Email: {test_user.email}")
        
        # Удаляем тестового пользователя
        db.delete(test_user)
        db.commit()
        print("✓ Test user deleted")
        
        db.close()
        return True
    except Exception as e:
        print(f"✗ Error creating User: {e}")
        traceback.print_exc()
        return False

async def test_geocode():
    """Тестирует geocode"""
    print("\n=== Testing geocode ===")
    try:
        from common.address_service import geocode
        
        result = await geocode("Test City", "Test Street")
        print(f"✓ Geocode result: {result}")
        return True
    except Exception as e:
        print(f"✗ Geocode error: {e}")
        traceback.print_exc()
        return False

def test_full_registration_flow():
    """Тестирует полный процесс регистрации (без HTTP)"""
    print("\n=== Testing full registration flow ===")
    try:
        from common.database import SessionLocal
        from services.authentication.models import User, UserType
        from services.company_service.models import Company
        from services.authentication.utils import get_password_hash
        import uuid
        import asyncio
        from common.address_service import geocode
        
        db = SessionLocal()
        
        # 1. Создаем пользователя
        user_id = uuid.uuid4()
        user = User(
            id=user_id,
            email="testflow@test.com",
            user_name="Test Flow",
            phone_number="1234567890",
            city="Test City",
            street="Test Street",
            user_type=UserType.COMPANY,
            password_hash=get_password_hash("Test1234!")
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        print("✓ Step 1: User created")
        
        # 2. Получаем координаты
        coordinates = asyncio.run(geocode("Test City", "Test Street"))
        if not coordinates or not coordinates.strip():
            coordinates = "55.7558,37.6173"
        print(f"✓ Step 2: Coordinates: {coordinates}")
        
        # 3. Создаем компанию
        company = Company(
            guid=str(user.id),
            title=user.user_name,
            phone_number=user.phone_number or "0000000000",
            email=user.email,
            city=user.city or "-",
            street=user.street or "-",
            coordinates=coordinates,
            social_medias=[],
            photo_uris=[],
            categories_id=[]
        )
        
        db.add(company)
        db.commit()
        db.refresh(company)
        print("✓ Step 3: Company created")
        
        # 4. Проверяем
        print(f"✓ User: {user.email}, Company: {company.title}")
        
        # 5. Удаляем
        db.delete(company)
        db.delete(user)
        db.commit()
        print("✓ Cleanup: Test data deleted")
        
        db.close()
        return True
    except Exception as e:
        print(f"✗ Full flow error: {e}")
        traceback.print_exc()
        return False

def test_http_registration():
    """Тестирует HTTP регистрацию с детальным выводом"""
    print("\n=== Testing HTTP registration ===")
    try:
        import requests
        
        url = "http://localhost:8001/api/auth/register"
        data = {
            "email": "httptest@example.com",
            "name": "HTTP Test Company",
            "password": "Test1234!",
            "street": "Test Street",
            "city": "Test City",
            "phone_number": "1234567890",
            "type": "Company"
        }
        
        print(f"POST {url}")
        print(f"Data: {data}")
        
        response = requests.post(url, json=data, timeout=10)
        
        print(f"Status: {response.status_code}")
        print(f"Response headers: {dict(response.headers)}")
        print(f"Response body: {response.text}")
        
        if response.status_code == 200:
            print("✓ Registration successful!")
            return True
        else:
            print(f"✗ Registration failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ HTTP request error: {e}")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Starting detailed diagnostics...\n")
    
    # Тесты по порядку
    results = []
    
    results.append(("Company creation", test_company_creation()))
    results.append(("User creation", test_user_creation()))
    results.append(("Geocode", asyncio.run(test_geocode())))
    results.append(("Full flow", test_full_registration_flow()))
    results.append(("HTTP registration", test_http_registration()))
    
    # Итоги
    print("\n=== Summary ===")
    for name, result in results:
        status = "✓" if result else "✗"
        print(f"{status} {name}")
