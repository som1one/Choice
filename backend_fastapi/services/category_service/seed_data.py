"""Seed данные для категорий"""
from sqlalchemy.orm import Session
from .models import Category
from common.database import SessionLocal

def seed_categories():
    """Заполнение начальными данными"""
    db = SessionLocal()
    
    try:
        # Проверяем, есть ли уже категории
        existing = db.query(Category).count()
        if existing > 0:
            return
        
        # Системные категории (ID 1-7)
        categories = [
            Category(id=1, title="Ремонт", icon_uri="https://example.com/icons/repair.png"),
            Category(id=2, title="Уборка", icon_uri="https://example.com/icons/cleaning.png"),
            Category(id=3, title="Переезд", icon_uri="https://example.com/icons/moving.png"),
            Category(id=4, title="Красота", icon_uri="https://example.com/icons/beauty.png"),
            Category(id=5, title="Обучение", icon_uri="https://example.com/icons/education.png"),
            Category(id=6, title="Ремонт техники", icon_uri="https://example.com/icons/tech.png"),
            Category(id=7, title="Другое", icon_uri="https://example.com/icons/other.png"),
        ]
        
        for category in categories:
            db.add(category)
        
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error seeding categories: {e}")
    finally:
        db.close()
