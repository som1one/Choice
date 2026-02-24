# ⚡ Быстрый старт

## 🚀 За 3 шага

### 1. Установка
```bash
cd backend_fastapi
python -m venv venv
venv\Scripts\activate  # Windows
# или
source venv/bin/activate  # Linux/Mac

pip install -r requirements.txt
```

### 2. Настройка
Создайте `.env` файл (см. `START_GUIDE.md`)

### 3. Запуск

**Windows (PowerShell):**
```powershell
.\start_all.bat
```

**Windows (CMD):**
```cmd
start_all.bat
```

**Linux/Mac:**
```bash
chmod +x start_all.sh
./start_all.sh
```

**Или вручную:**
```bash
# Терминал 1
cd services/authentication
uvicorn main:app --port 8001 --reload

# Терминал 2
cd services/category_service
uvicorn main:app --port 8004 --reload

# И т.д.
```

---

## ✅ Проверка

### Через браузер:
- http://localhost:8001/docs - Swagger UI
- http://localhost:8001/health - Health check

### Через скрипт:
```bash
python check_services.py
```

### Через тест:
```bash
python test_api.py
```

---

## 📚 Документация

- `START_GUIDE.md` - Подробное руководство
- `README.md` - Общая информация
- Swagger UI - Интерактивная документация API
