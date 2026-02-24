#!/usr/bin/env python3
"""Скрипт для проверки статуса всех сервисов"""
import requests
import sys
from typing import Dict

SERVICES: Dict[str, str] = {
    "Authentication": "http://localhost:8001/health",
    "Client": "http://localhost:8002/health",
    "Company": "http://localhost:8003/health",
    "Category": "http://localhost:8004/health",
    "Ordering": "http://localhost:8005/health",
    "Chat": "http://localhost:8006/health",
    "Review": "http://localhost:8007/health",
    "File": "http://localhost:8008/health",
}

def check_service(name: str, url: str) -> bool:
    """Проверка статуса сервиса"""
    try:
        response = requests.get(url, timeout=2)
        if response.status_code == 200:
            print(f"✅ {name:15} - OK ({url})")
            return True
        else:
            print(f"❌ {name:15} - Error {response.status_code} ({url})")
            return False
    except requests.exceptions.ConnectionError:
        print(f"❌ {name:15} - Connection refused ({url})")
        return False
    except Exception as e:
        print(f"❌ {name:15} - {e} ({url})")
        return False

def main():
    """Главная функция"""
    print("🔍 Checking FastAPI services...")
    print("=" * 60)
    
    all_ok = True
    for name, url in SERVICES.items():
        if not check_service(name, url):
            all_ok = False
    
    print("=" * 60)
    if all_ok:
        print("✅ All services are running!")
        sys.exit(0)
    else:
        print("❌ Some services are not running")
        sys.exit(1)

if __name__ == "__main__":
    main()
