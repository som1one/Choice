#!/usr/bin/env python3
"""Скрипт для проверки логов и диагностики ошибок"""
import os
import glob
from pathlib import Path

def find_logs():
    """Находит все log файлы"""
    print("=== Searching for log files ===")
    
    # Ищем в разных местах
    search_paths = [
        "logs",
        ".",
        "..",
        "/var/log",
        "/opt/Choice/backend_fastapi/logs"
    ]
    
    log_files = []
    for path in search_paths:
        if os.path.exists(path):
            for ext in ["*.log", "*.log.*"]:
                files = glob.glob(os.path.join(path, ext))
                log_files.extend(files)
    
    if log_files:
        print(f"Found {len(log_files)} log files:")
        for f in log_files:
            print(f"  - {f}")
    else:
        print("No log files found")
    
    return log_files

def check_recent_errors():
    """Проверяет последние ошибки в логах"""
    print("\n=== Checking for recent errors ===")
    
    log_files = find_logs()
    
    for log_file in log_files[:5]:  # Проверяем первые 5 файлов
        try:
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                # Берем последние 50 строк
                recent_lines = lines[-50:] if len(lines) > 50 else lines
                
                # Ищем ошибки
                errors = [line for line in recent_lines if 'error' in line.lower() or 'exception' in line.lower() or 'traceback' in line.lower()]
                
                if errors:
                    print(f"\nErrors in {log_file}:")
                    for error in errors[-10:]:  # Последние 10 ошибок
                        print(f"  {error.strip()}")
        except Exception as e:
            print(f"  Could not read {log_file}: {e}")

def test_geocode():
    """Тестирует geocode функцию"""
    print("\n=== Testing geocode function ===")
    try:
        from common.address_service import geocode
        import asyncio
        
        async def test():
            result = await geocode("Test City", "Test Street")
            print(f"Geocode result: {result}")
            return result
        
        result = asyncio.run(test())
        print(f"✓ Geocode works: {result}")
    except Exception as e:
        print(f"✗ Geocode error: {e}")
        import traceback
        traceback.print_exc()

def test_company_model():
    """Тестирует создание Company модели"""
    print("\n=== Testing Company model ===")
    try:
        from services.company_service.models import Company
        from common.database import SessionLocal
        
        db = SessionLocal()
        
        # Пробуем создать тестовую компанию
        test_company = Company(
            guid="test-guid-123",
            title="Test Company",
            phone_number="1234567890",
            email="test@test.com",
            city="Test City",
            street="Test Street",
            coordinates="55.7558,37.6173"
        )
        
        print(f"✓ Company model created: {test_company.title}")
        print(f"  Fields: guid={test_company.guid}, email={test_company.email}")
        
        db.close()
    except Exception as e:
        print(f"✗ Company model error: {e}")
        import traceback
        traceback.print_exc()

def check_uvicorn_logs():
    """Проверяет логи uvicorn (если они в stdout/stderr)"""
    print("\n=== Checking uvicorn process output ===")
    print("Note: Check the terminal where uvicorn is running for error messages")
    print("Or check system logs: journalctl -u your-service-name")

if __name__ == "__main__":
    check_recent_errors()
    test_geocode()
    test_company_model()
    check_uvicorn_logs()
