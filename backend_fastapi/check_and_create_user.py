#!/usr/bin/env python3
"""Скрипт для проверки и создания тестового пользователя"""
import sys
from pathlib import Path

# Добавить корневую директорию в путь
current_file = Path(__file__).resolve()
project_root = current_file.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from common.database import SessionLocal, engine
from services.authentication.models import User, UserType
from common.security import get_password_hash
from sqlalchemy import inspect
import uuid

def check_database():
    """Проверка подключения к БД"""
    print("=== Проверка базы данных ===")
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            result.fetchone()
            print("✓ Подключение к БД работает")
    except Exception as e:
        print(f"✗ Ошибка подключения к БД: {e}")
        return False
    
    # Проверка таблиц
    try:
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"✓ Найдено таблиц: {len(tables)}")
        print(f"  Таблицы: {', '.join(tables)}")
        
        if "Users" not in tables:
            print("✗ Таблица Users не найдена!")
            print("  Запустите инициализацию БД через init_db()")
            return False
        print("✓ Таблица Users существует")
    except Exception as e:
        print(f"✗ Ошибка проверки таблиц: {e}")
        return False
    
    return True

def check_user(email: str):
    """Проверка существования пользователя"""
    print(f"\n=== Проверка пользователя {email} ===")
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if user:
            print(f"✓ Пользователь найден:")
            print(f"  ID: {user.id}")
            print(f"  Email: {user.email}")
            print(f"  Имя: {user.user_name}")
            print(f"  Тип: {user.user_type}")
            print(f"  Заблокирован: {user.is_blocked if hasattr(user, 'is_blocked') else 'N/A'}")
            return user
        else:
            print(f"✗ Пользователь {email} не найден")
            return None
    except Exception as e:
        print(f"✗ Ошибка при поиске пользователя: {e}")
        return None
    finally:
        db.close()

def create_test_user(email: str, password: str, name: str = "Test User"):
    """Создание тестового пользователя"""
    print(f"\n=== Создание пользователя {email} ===")
    db = SessionLocal()
    try:
        # Проверка, не существует ли уже
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            print(f"⚠ Пользователь {email} уже существует")
            return existing
        
        # Создание нового пользователя
        user = User(
            id=uuid.uuid4(),
            email=email,
            user_name=name,
            phone_number="0000000000",
            city="Test City",
            street="Test Street",
            user_type=UserType.CLIENT,
            password_hash=get_password_hash(password)
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        print(f"✓ Пользователь создан:")
        print(f"  ID: {user.id}")
        print(f"  Email: {user.email}")
        print(f"  Имя: {user.user_name}")
        print(f"  Тип: {user.user_type}")
        return user
    except Exception as e:
        print(f"✗ Ошибка при создании пользователя: {e}")
        db.rollback()
        return None
    finally:
        db.close()

def list_all_users():
    """Список всех пользователей"""
    print("\n=== Список всех пользователей ===")
    db = SessionLocal()
    try:
        users = db.query(User).all()
        if users:
            print(f"Найдено пользователей: {len(users)}")
            for user in users:
                print(f"  - {user.email} ({user.user_type.value})")
        else:
            print("Пользователи не найдены")
    except Exception as e:
        print(f"✗ Ошибка при получении списка: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    if not check_database():
        sys.exit(1)
    
    email = "cp@gmail.com"
    password = "qwerty123"
    
    user = check_user(email)
    
    if not user:
        response = input(f"\nСоздать пользователя {email}? (y/n): ")
        if response.lower() == 'y':
            create_test_user(email, password, "Test Client")
        else:
            print("Пользователь не создан")
    else:
        print(f"\nПользователь уже существует. Для сброса пароля используйте:")
        print(f"  python3 -c \"from common.security import get_password_hash; print(get_password_hash('{password}'))\"")
    
    list_all_users()
