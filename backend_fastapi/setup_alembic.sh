#!/bin/bash
# Скрипт для настройки Alembic

cd /opt/Choice/backend_fastapi
source .venv/bin/activate

# Инициализация Alembic (если еще не инициализирован)
if [ ! -d "alembic" ]; then
    alembic init alembic
    echo "Alembic initialized"
fi

# Обновление alembic.ini с правильным DATABASE_URL
python << EOF
import os
from pathlib import Path
from pydantic_settings import BaseSettings

class DatabaseSettings(BaseSettings):
    database_url: str = "sqlite:///./choice.db"
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"

settings = DatabaseSettings()

# Читаем .env если есть
env_file = Path(".env")
if env_file.exists():
    with open(env_file) as f:
        for line in f:
            if line.startswith("DATABASE_URL"):
                settings.database_url = line.split("=", 1)[1].strip().strip('"').strip("'")
                break

# Обновляем alembic.ini
alembic_ini = Path("alembic.ini")
if alembic_ini.exists():
    content = alembic_ini.read_text()
    # Заменяем sqlalchemy.url
    import re
    content = re.sub(
        r'sqlalchemy\.url\s*=\s*.*',
        f'sqlalchemy.url = {settings.database_url}',
        content
    )
    alembic_ini.write_text(content)
    print(f"Updated alembic.ini with DATABASE_URL: {settings.database_url}")
else:
    print("alembic.ini not found")
EOF

echo "Alembic setup complete"
