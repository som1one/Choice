#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""HTTP тест для регистрации компании (работает с любой БД)"""
import requests
import json
import sys
import os
from pathlib import Path

# Устанавливаем UTF-8 для Windows
if sys.platform == 'win32':
    os.system('chcp 65001 >nul')
    sys.stdout.reconfigure(encoding='utf-8')

# Добавляем корневую директорию в путь
project_root = Path(__file__).parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

BASE_URL = "http://localhost:8001"

def test_company_registration():
    """Тест регистрации компании через HTTP"""
    print("=" * 60)
    print("Тестирование регистрации компании")
    print("=" * 60)
    
    # Тест 1: Успешная регистрация
    print("\n[1] Тест успешной регистрации компании")
    registration_data = {
        "email": "testcompany@example.com",
        "name": "Тестовая Компания",
        "password": "Test1234!",
        "street": "Ленина",
        "city": "Москва",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/register", json=registration_data, timeout=10)
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            if "access_token" in data:
                print("   [OK] Регистрация успешна, токен получен")
                print(f"   Токен: {data['access_token'][:50]}...")
            else:
                print("   [FAIL] Токен не найден в ответе")
                print(f"   Ответ: {response.text}")
        else:
            print(f"   [FAIL] Ошибка регистрации: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except requests.exceptions.ConnectionError:
        print("   [WARN] Сервер недоступен. Убедитесь, что сервис запущен на порту 8001")
        return False
    except Exception as e:
        print(f"   [ERROR] Ошибка: {e}")
        return False
    
    # Тест 2: Регистрация с пустым телефоном
    print("\n[2] Тест регистрации с пустым телефоном")
    registration_data2 = {
        "email": "testcompany2@example.com",
        "name": "Тестовая Компания 2",
        "password": "Test1234!",
        "street": "Пушкина",
        "city": "Санкт-Петербург",
        "phone_number": None,
        "type": "Company"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/register", json=registration_data2, timeout=10)
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 200:
            print("   [OK] Регистрация с пустым телефоном успешна")
        else:
            print(f"   [FAIL] Ошибка: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"   [ERROR] Ошибка: {e}")
    
    # Тест 3: Дублирующийся email
    print("\n[3] Тест регистрации с дублирующимся email")
    registration_data3 = {
        "email": "testcompany@example.com",  # Тот же email, что в первом тесте
        "name": "Другая Компания",
        "password": "Test1234!",
        "street": "Ленина",
        "city": "Москва",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/register", json=registration_data3, timeout=10)
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 400:
            print("   [OK] Правильно отклонена регистрация с дублирующимся email")
        else:
            print(f"   [WARN] Ожидался статус 400, получен {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"   [ERROR] Ошибка: {e}")
    
    # Тест 4: Пустые город и улица
    print("\n[4] Тест регистрации с пустыми городом и улицей")
    registration_data4 = {
        "email": "testcompany3@example.com",
        "name": "Тестовая Компания 3",
        "password": "Test1234!",
        "street": "",
        "city": "",
        "phone_number": "1234567890",
        "type": "Company"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/register", json=registration_data4, timeout=10)
        print(f"   Статус: {response.status_code}")
        
        if response.status_code == 200:
            print("   [OK] Регистрация с пустыми городом и улицей успешна")
        else:
            print(f"   [FAIL] Ошибка: {response.status_code}")
            print(f"   Ответ: {response.text}")
    except Exception as e:
        print(f"   [ERROR] Ошибка: {e}")
    
    print("\n" + "=" * 60)
    print("[OK] Тестирование завершено")
    print("=" * 60)
    return True

if __name__ == "__main__":
    test_company_registration()
