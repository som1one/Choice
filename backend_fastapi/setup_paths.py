"""Настройка путей для импортов"""
import sys
from pathlib import Path

# Добавить корневую директорию проекта в sys.path
root_dir = Path(__file__).parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))
