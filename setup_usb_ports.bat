@echo off
echo ========================================
echo   Настройка USB портов для Android
echo ========================================
echo.

REM Проверка подключения устройства
echo [1/2] Checking device connection...
adb devices
if %errorlevel% neq 0 (
    echo ERROR: ADB not found!
    echo Please install Android SDK Platform Tools.
    pause
    exit /b 1
)
echo.

REM Настройка проброса портов
echo [2/2] Setting up port forwarding...
adb reverse tcp:8001 tcp:8001
adb reverse tcp:8002 tcp:8002
adb reverse tcp:8003 tcp:8003
adb reverse tcp:8004 tcp:8004
adb reverse tcp:8005 tcp:8005
adb reverse tcp:8006 tcp:8006
adb reverse tcp:8007 tcp:8007
adb reverse tcp:8008 tcp:8008

echo.
echo ========================================
echo   Проверка проброса портов:
echo ========================================
adb reverse --list

echo.
echo ========================================
echo   Готово! Порты настроены.
echo ========================================
echo.
echo Теперь можно запускать Flutter:
echo   cd client_app_flutter
echo   flutter run
echo.
pause
