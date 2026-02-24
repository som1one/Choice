# 🚀 Быстрый запуск

## Backend (Сервер)

### 1. Требования
- .NET 8.0 SDK
- SQL Server (локально или удаленно)
- RabbitMQ (для Event Bus)

### 2. Установка RabbitMQ

**Windows:**
```powershell
# Через Chocolatey
choco install rabbitmq

# Или скачайте с https://www.rabbitmq.com/download.html
```

**macOS:**
```bash
brew install rabbitmq
brew services start rabbitmq
```

**Linux:**
```bash
sudo apt-get install rabbitmq-server
sudo systemctl start rabbitmq-server
```

### 3. Настройка SQL Server

**Локально:**
- Установите SQL Server Express или используйте Docker:
```bash
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourPassword123" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```

### 4. Обновите appsettings.json

**Для каждого сервиса** (authentication, chat, client-service и т.д.):

```json
{
  "SqlServerSettings": {
    "ConnectionString": "Server=localhost;Database=YourDb;User Id=sa;Password=YourPassword123;TrustServerCertificate=True;"
  },
  "EventBusSettings": {
    "HostAddress": "amqp://guest:guest@localhost:5672"
  },
  "JwtSettings": {
    "Issuer": "http://localhost:5001",
    "Audience": "http://localhost:5001"
  }
}
```

### 5. Запуск сервисов

**Откройте отдельный терминал для каждого сервиса:**

```bash
# Терминал 1 - Authentication
cd services/services/authentication
dotnet run

# Терминал 2 - Client Service
cd services/services/client-service/src/ClientService.Api
dotnet run

# Терминал 3 - Company Service
cd services/services/company-service
dotnet run

# Терминал 4 - Category Service
cd services/services/category-service
dotnet run

# Терминал 5 - Chat Service
cd services/services/chat
dotnet run

# Терминал 6 - Ordering Service
cd services/services/ordering/src/Ordering.Api
dotnet run

# Терминал 7 - Review Service
cd services/services/review-service
dotnet run

# Терминал 8 - File Service
cd services/services/file-service
dotnet run
```

**Или используйте один скрипт (Windows PowerShell):**
```powershell
# start-all-services.ps1
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/authentication; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/client-service/src/ClientService.Api; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/company-service; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/category-service; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/chat; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/ordering/src/Ordering.Api; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/review-service; dotnet run"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd services/services/file-service; dotnet run"
```

### 6. Проверка работы

Откройте в браузере:
- Authentication: http://localhost:5001/swagger
- Client Service: http://localhost:5002/swagger
- И т.д.

---

## Frontend (Мобильное приложение)

### 1. Требования
- Node.js >= 18
- Android Studio (для Android) или Xcode (для iOS)

### 2. Установка зависимостей

```bash
cd ClientApp
npm install
```

### 3. Обновите env.js

```javascript
export default {
    api_url: 'http://10.0.2.2:5001',  // Для Android эмулятора
    // api_url: 'http://localhost:5001',  // Для iOS симулятора
    auth_url: 'http://10.0.2.2:5001'
}
```

> **Важно:** 
> - Android эмулятор: используйте `10.0.2.2` вместо `localhost`
> - iOS симулятор: используйте `localhost`
> - Реальное устройство: используйте IP вашего ПК (например, `192.168.1.100:5001`)

### 4. Запуск Metro Bundler

```bash
cd ClientApp
npm start
```

Оставьте этот терминал открытым.

### 5. Запуск на Android

**В новом терминале:**
```bash
cd ClientApp
npm run android
```

**Или через Android Studio:**
1. Откройте Android Studio
2. Запустите эмулятор
3. В Android Studio: File → Open → выберите `ClientApp/android`
4. Нажмите Run

### 6. Запуск на iOS (только macOS)

**Установите CocoaPods зависимости:**
```bash
cd ClientApp/ios
pod install
cd ../..
```

**Запустите:**
```bash
npm run ios
```

---

## 🔧 Быстрая проверка

### Backend работает если:
- ✅ Swagger открывается в браузере
- ✅ Нет ошибок в терминале
- ✅ RabbitMQ запущен

### Frontend работает если:
- ✅ Metro bundler показывает "Metro waiting on..."
- ✅ Эмулятор/симулятор открылся
- ✅ Приложение загрузилось

---

## ⚠️ Частые проблемы

### Backend не запускается:
```bash
# Проверьте .NET SDK
dotnet --version  # Должно быть 8.0.x

# Проверьте RabbitMQ
# Windows: http://localhost:15672
# macOS/Linux: sudo systemctl status rabbitmq-server

# Проверьте SQL Server
# Windows: SQL Server Configuration Manager
# Docker: docker ps
```

### Frontend не подключается к серверу:
- Проверьте `env.js` - правильный ли URL
- Для Android: используйте `10.0.2.2` вместо `localhost`
- Проверьте, что все сервисы запущены
- Проверьте файрвол Windows

### Metro bundler ошибки:
```bash
# Очистите кэш
npm start -- --reset-cache
```

---

## 📝 Порты сервисов (по умолчанию)

- Authentication: 5001
- Client Service: 5002
- Company Service: 5003
- Category Service: 5004
- Chat Service: 5005
- Ordering API: 5006
- Review Service: 5007
- File Service: 5008

---

**Готово! Сервер и приложение должны работать.** 🎉
