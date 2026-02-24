@echo off
setlocal

REM Получить директорию, где находится скрипт
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo Starting all FastAPI services...
echo Script directory: %SCRIPT_DIR%
echo.

REM Проверка виртуального окружения
if not exist "venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run: python -m venv venv
    pause
    exit /b 1
)

REM Запуск сервисов из корневой директории
start "Auth Service (8001)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.authentication.main:app --port 8001 --reload"
timeout /t 2 /nobreak >nul

start "Client Service (8002)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.client_service.main:app --port 8002 --reload"
timeout /t 2 /nobreak >nul

start "Company Service (8003)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.company_service.main:app --port 8003 --reload"
timeout /t 2 /nobreak >nul

start "Category Service (8004)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.category_service.main:app --port 8004 --reload"
timeout /t 2 /nobreak >nul

start "Ordering Service (8005)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.ordering.main:app --port 8005 --reload"
timeout /t 2 /nobreak >nul

start "Chat Service (8006)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.chat.main:app --port 8006 --reload"
timeout /t 2 /nobreak >nul

start "Review Service (8007)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.review_service.main:app --port 8007 --reload"
timeout /t 2 /nobreak >nul

start "File Service (8008)" cmd /k "cd /d %SCRIPT_DIR% && call venv\Scripts\activate.bat && set PYTHONPATH=%SCRIPT_DIR% && python -m uvicorn services.file_service.main:app --port 8008 --reload"

echo.
echo All services started!
echo.
echo NOTE: If windows are empty, check:
echo 1. Virtual environment is activated
echo 2. Database is running
echo 3. .env file is configured
echo.
echo Check Swagger UI:
echo - Authentication: http://localhost:8001/docs
echo - Client: http://localhost:8002/docs
echo - Company: http://localhost:8003/docs
echo - Category: http://localhost:8004/docs
echo - Ordering: http://localhost:8005/docs
echo - Chat: http://localhost:8006/docs
echo - Review: http://localhost:8007/docs
echo - File: http://localhost:8008/docs
echo.
echo Press any key to close this window (services will continue running)...
pause >nul
