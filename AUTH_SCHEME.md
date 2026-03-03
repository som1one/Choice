# Схема логики входа и регистрации

## 1. РЕГИСТРАЦИЯ

### 1.1 Регистрация клиента
```
1. Пользователь заполняет форму (ФИО, email, пароль, город)
2. Валидация данных на клиенте
3. Отправка запроса на сервер /api/auth/register
4. Сервер создает пользователя и возвращает JWT токен
5. Сохранение данных:
   - Токен в AuthTokenStore.setToken()
   - Токен в SharedPreferences (_authTokenKey)
   - Данные пользователя в SharedPreferences (_clientCredentialsKey)
   - Статус loggedIn = true
   - Статус registered = true
   - userType = UserType.client
6. Автоматический переход на ClientTabNavigator
```

### 1.2 Регистрация компании
```
1. Пользователь заполняет форму (название, email, пароль, тип)
2. Валидация данных на клиенте
3. Отправка запроса на сервер /api/auth/register с type='Company'
4. Сервер создает пользователя и возвращает JWT токен
5. Сохранение данных:
   - Токен в AuthTokenStore.setToken()
   - Токен в SharedPreferences (_authTokenKey)
   - Данные компании в SharedPreferences (_companyCredentialsKey)
   - Статус loggedIn = true
   - Статус registered = true
   - userType = UserType.company
6. Автоматический переход на CompanyTabNavigator
```

## 2. ВХОД

### 2.1 Вход клиента
```
1. Пользователь вводит email/логин и пароль
2. Проверка тестового аккаунта (если debug режим)
3. Отправка запроса на сервер /api/auth/login
4. Сервер проверяет данные и возвращает JWT токен
5. Декодирование токена для получения user_type
6. Сохранение данных:
   - Токен в AuthTokenStore.setToken()
   - Токен в SharedPreferences (_authTokenKey)
   - Статус loggedIn = true
   - userType из токена (Client/Company/Admin)
7. Переход на соответствующий экран (ClientTabNavigator/CompanyTabNavigator)
```

### 2.2 Вход компании
```
1. Пользователь вводит email и пароль
2. Проверка тестового аккаунта (если debug режим)
3. Отправка запроса на сервер /api/auth/login
4. Сервер проверяет данные и возвращает JWT токен
5. Декодирование токена для получения user_type
6. Сохранение данных:
   - Токен в AuthTokenStore.setToken()
   - Токен в SharedPreferences (_authTokenKey)
   - Статус loggedIn = true
   - userType из токена
7. Переход на CompanyTabNavigator
```

### 2.3 Вход администратора
```
1. Пользователь вводит email и пароль
2. Отправка запроса на сервер /api/auth/login
3. Сервер проверяет данные (включая bootstrap admin из .env)
4. Если user_type в токене = 'Admin':
   - Сохранение токена в AuthTokenStore.setToken()
   - Сохранение токена в SharedPreferences
   - Статус loggedIn = true
   - userType = UserType.admin
5. Переход на AdminPanelScreen
```

## 3. ПРОВЕРКА АВТОРИЗАЦИИ ПРИ ЗАПУСКЕ

```
1. Проверка наличия токена в AuthTokenStore
2. Если токен есть:
   - Проверка валидности токена (опционально, по exp)
   - Декодирование токена для получения user_type
   - Установка userType
   - Установка loggedIn = true
3. Если токена нет:
   - Проверка статуса loggedIn в SharedPreferences
   - Если loggedIn = true, восстановление userType
4. Результат:
   - Если авторизован и userType = company -> CompanyTabNavigator
   - Если авторизован и userType = client -> ClientTabNavigator
   - Если авторизован и userType = admin -> AdminPanelScreen
   - Если не авторизован -> WelcomeScreen -> LoginScreen
```

## 4. ВЫХОД

```
1. Очистка токена:
   - AuthTokenStore.clearToken()
   - SharedPreferences.remove(_authTokenKey)
2. Очистка статусов:
   - loggedIn = false
   - registered = false (опционально)
   - userType = null
3. Очистка данных пользователя (опционально)
4. Переход на WelcomeScreen -> LoginScreen
```

## 5. КРИТИЧЕСКИЕ МОМЕНТЫ

1. **Токен должен сохраняться в двух местах:**
   - AuthTokenStore (для ApiClient)
   - SharedPreferences (для проверки авторизации)

2. **После регистрации ОБЯЗАТЕЛЬНО:**
   - Сохранить токен
   - Установить loggedIn = true
   - Установить userType
   - Перейти на главный экран

3. **После входа ОБЯЗАТЕЛЬНО:**
   - Сохранить токен
   - Установить loggedIn = true
   - Установить userType из токена
   - Перейти на главный экран

4. **При проверке авторизации:**
   - Сначала проверять токен
   - Если токена нет, проверять loggedIn
   - userType должен определяться из токена или из сохраненного значения
