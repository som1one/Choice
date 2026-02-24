@echo off
echo Installing FastAPI dependencies...
echo.

echo Updating pip...
python -m pip install --upgrade pip setuptools wheel

echo.
echo Installing dependencies (this may take a few minutes)...
echo.

REM Установка psycopg2-binary отдельно с принудительной переустановкой
python -m pip install --upgrade --force-reinstall --no-cache-dir psycopg2-binary

echo.
echo Installing remaining dependencies...
python -m pip install -r requirements.txt

echo.
echo Done!
echo.
pause
