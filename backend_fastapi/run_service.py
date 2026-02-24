#!/usr/bin/env python3
"""Универсальный скрипт для запуска любого сервиса"""
import sys
import uvicorn
from pathlib import Path

# Добавить корневую директорию в путь
root_dir = Path(__file__).parent
sys.path.insert(0, str(root_dir))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_service.py <service_name> [port]")
        print("Example: python run_service.py authentication 8001")
        sys.exit(1)
    
    service_name = sys.argv[1]
    port = int(sys.argv[2]) if len(sys.argv) > 2 else None
    
    # Маппинг сервисов на порты
    service_ports = {
        "authentication": 8001,
        "client_service": 8002,
        "company_service": 8003,
        "category_service": 8004,
        "ordering": 8005,
        "chat": 8006,
        "review_service": 8007,
        "file_service": 8008,
    }
    
    if service_name not in service_ports:
        print(f"Unknown service: {service_name}")
        print(f"Available services: {', '.join(service_ports.keys())}")
        sys.exit(1)
    
    port = port or service_ports[service_name]
    
    # Импорт приложения
    service_module = f"services.{service_name}.main"
    app_module = __import__(service_module, fromlist=["app"])
    app = app_module.app
    
    print(f"Starting {service_name} on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port, reload=True)
