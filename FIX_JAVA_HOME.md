# 🔧 Исправление JAVA_HOME

## Проблема
```
ERROR: JAVA_HOME is set to an invalid directory: D:\Java\jdk-21
```

## Решение

### Вариант 1: Установить JDK 17 (рекомендуется)

**1. Скачайте JDK 17:**
- Oracle JDK: https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
- Или OpenJDK: https://adoptium.net/temurin/releases/?version=17

**2. Установите JDK** (например, в `C:\Program Files\Java\jdk-17`)

**3. Установите JAVA_HOME:**

**Через PowerShell (администратор):**
```powershell
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-17', [System.EnvironmentVariableTarget]::Machine)
```

**Или через GUI:**
1. Win + R → `sysdm.cpl` → Enter
2. Вкладка "Дополнительно" → "Переменные среды"
3. В "Системные переменные" найдите или создайте `JAVA_HOME`
4. Установите значение: `C:\Program Files\Java\jdk-17` (или путь, куда установили)
5. В `Path` добавьте: `%JAVA_HOME%\bin`

**4. Перезапустите терминал** и проверьте:
```powershell
$env:JAVA_HOME
java -version
javac -version
```

### Вариант 2: Использовать JDK из Android Studio

Если Android Studio установлен, найдите его JDK:
```powershell
# Обычно находится здесь:
$jdkPath = "$env:LOCALAPPDATA\Android\Sdk\jre"
# или
$jdkPath = "$env:ProgramFiles\Android\Android Studio\jbr"
```

Затем установите JAVA_HOME на этот путь.

### Вариант 3: Через Chocolatey (быстро)

```powershell
# Установите Chocolatey, если нет: https://chocolatey.org/install
choco install openjdk17
```

После установки перезапустите терминал.

---

## Проверка

После установки выполните:
```powershell
$env:JAVA_HOME
java -version
javac -version
```

Должно показать версию Java и путь к JDK.

Затем попробуйте снова:
```bash
npm run android
```
