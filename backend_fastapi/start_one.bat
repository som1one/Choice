@echo off
REM Скрипт для запуска одного сервиса для тестирования
REM Использование: start_one.bat authentication 8001

setlocal

if "%~1"=="" (
    echo Usage: start_one.bat ^<service_name^> [port]
    echo Example: start_one.bat authentication 8001
    exit /b 1
)

set "SERVICE_NAME=%~1"
set "PORT=%~2"

if "%PORT%"=="" (
    REM Маппинг сервисов на порты по умолчанию
    if "%SERVICE_NAME%"=="authentication" set PORT=8001
    if "%SERVICE_NAME%"=="client_service" set PORT=8002
    if "%SERVICE_NAME%"=="company_service" set PORT=8003
    if "%SERVICE_NAME%"=="category_service" set PORT=8004
    if "%SERVICE_NAME%"=="ordering" set PORT=8005
    if "%SERVICE_NAME%"=="chat" set PORT=8006
    if "%SERVICE_NAME%"=="review_service" set PORT=8007
    if "%SERVICE_NAME%"=="file_service" set PORT=8008
)

if "%PORT%"=="" (
    echo ERROR: Unknown service: %SERVICE_NAME%
    echo Available services: authentication, client_service, company_service, category_service, ordering, chat, review_service, file_service
    exit /b 1
)

REM Получить директорию скрипта
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo Starting %SERVICE_NAME% on port %PORT%...
echo.

REM Проверка виртуального окружения
if not exist "venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run: python -m venv venv
    pause
    exit /b 1
)

REM Запуск сервиса
cd services\%SERVICE_NAME%
call ..\..\venv\Scripts\activate.bat
python -m uvicorn main:app --port %PORT% --reload

pause
