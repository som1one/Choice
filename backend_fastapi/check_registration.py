#!/usr/bin/env python3
"""Скрипт для проверки регистрации компании"""
import sys
import requests
import json

def test_registration():
    """Тестирует регистрацию компании"""
    url = "http://localhost:8001/api/auth/register"
    data = {
        "email": "test@example.com",
        "name": "Test Company",
        "password": "Test1234!",
        "street": "Test Street",
        "city": "Test City",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    print("=== Testing registration ===")
    try:
        response = requests.post(url, json=data, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✓ Registration successful!")
            token_data = response.json()
            if "access_token" in token_data:
                print(f"✓ Token received: {token_data['access_token'][:20]}...")
        else:
            print(f"✗ Registration failed: {response.status_code}")
    except Exception as e:
        print(f"✗ Error: {e}")

def check_database():
    """Проверяет базу данных"""
    print("\n=== Database check ===")
    try:
        from common.database import SessionLocal
        from services.authentication.models import User
        from services.company_service.models import Company
        
        db = SessionLocal()
        
        # Проверка пользователей
        users = db.query(User).all()
        print(f"Total users: {len(users)}")
        for u in users:
            print(f"  - {u.email} ({u.user_type.value})")
        
        # Проверка компаний
        companies = db.query(Company).all()
        print(f"Total companies: {len(companies)}")
        for c in companies:
            print(f"  - {c.title} ({c.email})")
        
        # Проверка конкретного пользователя
        test_user = db.query(User).filter(User.email == "test@example.com").first()
        if test_user:
            print(f"\n✓ Test user found: {test_user.email}")
        else:
            print("\n✗ Test user not found")
        
        # Проверка конкретной компании
        test_company = db.query(Company).filter(Company.email == "test@example.com").first()
        if test_company:
            print(f"✓ Test company found: {test_company.title}")
        else:
            print("✗ Test company not found")
        
        db.close()
    except Exception as e:
        print(f"✗ Database check error: {e}")
        import traceback
        traceback.print_exc()

def check_tables():
    """Проверяет существование таблиц"""
    print("\n=== Tables check ===")
    try:
        from common.database import engine
        from sqlalchemy import inspect
        
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        print(f"Total tables: {len(tables)}")
        for table in sorted(tables):
            print(f"  - {table}")
        
        # Проверка конкретных таблиц
        required_tables = ["Users", "Companies"]
        for table in required_tables:
            if table in tables:
                print(f"✓ Table '{table}' exists")
            else:
                print(f"✗ Table '{table}' NOT found")
    except Exception as e:
        print(f"✗ Tables check error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    check_tables()
    test_registration()
    check_database()
