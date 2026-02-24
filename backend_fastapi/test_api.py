#!/usr/bin/env python3
"""Скрипт для тестирования API"""
import requests
import json
from typing import Optional

BASE_URL = "http://localhost:8001"
TOKEN: Optional[str] = None

def test_register():
    """Тест регистрации"""
    print("📝 Testing registration...")
    url = f"{BASE_URL}/api/auth/register"
    data = {
        "email": "test@example.com",
        "name": "Тестовый",
        "password": "Test1234!",
        "street": "Ленина",
        "city": "Москва",
        "phone_number": "1234567890",
        "type": "Client"
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print("✅ Registration successful")
            return response.json()
        else:
            print(f"❌ Registration failed: {response.status_code}")
            print(response.text)
            return None
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_login():
    """Тест входа"""
    global TOKEN
    print("🔐 Testing login...")
    url = f"{BASE_URL}/api/auth/login"
    data = {
        "email": "test@example.com",
        "password": "Test1234!",
        "device_token": None
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            TOKEN = result.get("access_token")
            print("✅ Login successful")
            print(f"Token: {TOKEN[:50]}...")
            return True
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_get_categories():
    """Тест получения категорий"""
    if not TOKEN:
        print("❌ No token available")
        return False
    
    print("📂 Testing get categories...")
    url = "http://localhost:8004/api/category/get"
    headers = {"Authorization": f"Bearer {TOKEN}"}
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            categories = response.json()
            print(f"✅ Got {len(categories)} categories")
            return True
        else:
            print(f"❌ Failed: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Главная функция"""
    print("🧪 Testing FastAPI Services")
    print("=" * 60)
    
    # Тест регистрации
    user = test_register()
    if not user:
        print("⚠️  Registration failed, trying login...")
    
    # Тест входа
    if test_login():
        # Тест получения категорий
        test_get_categories()
    
    print("=" * 60)
    print("✅ Testing complete!")

if __name__ == "__main__":
    main()
