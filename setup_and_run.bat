@echo off
echo ========================================
echo   Полная настройка и запуск
echo ========================================
echo.

REM Проверка устройства
echo [1/3] Checking Android device...
adb devices
if %errorlevel% neq 0 (
    echo ERROR: ADB not found or device not connected!
    echo Please install Android SDK Platform Tools or connect device.
    pause
    exit /b 1
)
echo.

REM Настройка проброса портов
echo [2/3] Setting up USB port forwarding...
adb reverse tcp:8001 tcp:8001
adb reverse tcp:8002 tcp:8002
adb reverse tcp:8003 tcp:8003
adb reverse tcp:8004 tcp:8004
adb reverse tcp:8005 tcp:8005
adb reverse tcp:8006 tcp:8006
adb reverse tcp:8007 tcp:8007
adb reverse tcp:8008 tcp:8008
echo Ports forwarded!
echo.

echo.
echo ========================================
echo   Готово! Порты настроены.
echo ========================================
echo.
echo Теперь запустите Flutter:
echo   cd client_app_flutter
echo   flutter run
echo.
echo Или нажмите любую клавишу для автоматического запуска...
pause >nul

REM Запуск Flutter
cd client_app_flutter
flutter run
