$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $root "venv\Scripts\python.exe"
$logsDir = Join-Path $root "etc\local_logs"

if (-not (Test-Path $python)) {
    throw "Python venv not found: $python"
}

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$services = @(
    @{ Name = "authentication"; Port = 8001 },
    @{ Name = "client_service"; Port = 8002 },
    @{ Name = "company_service"; Port = 8003 },
    @{ Name = "category_service"; Port = 8004 },
    @{ Name = "ordering"; Port = 8005 },
    @{ Name = "chat"; Port = 8006 },
    @{ Name = "review_service"; Port = 8007 },
    @{ Name = "file_service"; Port = 8008 }
)

Write-Host "Starting local backend services from $root"
Write-Host "SQLite DB: $(Join-Path $root 'choice.db')"
Write-Host "RabbitMQ: disabled"
Write-Host ""

foreach ($service in $services) {
    $name = $service.Name
    $port = [int]$service.Port
    $stdout = Join-Path $logsDir "$name.out.log"
    $stderr = Join-Path $logsDir "$name.err.log"

    if (Test-Path $stdout) {
        try { Clear-Content $stdout -ErrorAction Stop } catch {}
    }
    if (Test-Path $stderr) {
        try { Clear-Content $stderr -ErrorAction Stop } catch {}
    }

    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($listener) {
        Write-Host ("[{0}] port {1} is already busy, skipping start" -f $name, $port)
        continue
    }

    $previousPythonPath = $env:PYTHONPATH
    $previousDatabaseUrl = $env:DATABASE_URL
    $previousRabbitEnabled = $env:RABBITMQ_ENABLED
    $previousPythonUtf8 = $env:PYTHONUTF8

    $env:PYTHONPATH = $root
    $env:DATABASE_URL = "sqlite:///./choice.db"
    $env:RABBITMQ_ENABLED = "false"
    $env:PYTHONUTF8 = "1"

    try {
        Start-Process `
            -FilePath $python `
            -ArgumentList @("run_service.py", $name, "$port") `
            -WorkingDirectory $root `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr | Out-Null
    }
    finally {
        if ($null -ne $previousPythonPath) { $env:PYTHONPATH = $previousPythonPath } else { Remove-Item Env:PYTHONPATH -ErrorAction SilentlyContinue }
        if ($null -ne $previousDatabaseUrl) { $env:DATABASE_URL = $previousDatabaseUrl } else { Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue }
        if ($null -ne $previousRabbitEnabled) { $env:RABBITMQ_ENABLED = $previousRabbitEnabled } else { Remove-Item Env:RABBITMQ_ENABLED -ErrorAction SilentlyContinue }
        if ($null -ne $previousPythonUtf8) { $env:PYTHONUTF8 = $previousPythonUtf8 } else { Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue }
    }

    Start-Sleep -Seconds 2
    Write-Host ("[{0}] started on port {1}" -f $name, $port)
}

Write-Host ""
Write-Host "Health check:"
foreach ($service in $services) {
    $port = [int]$service.Port
    $healthUrl = "http://127.0.0.1:$port/health"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 5
        Write-Host ("[OK]  {0} -> {1}" -f $service.Name, $response.StatusCode)
    }
    catch {
        Write-Host ("[FAIL] {0} -> {1}" -f $service.Name, $_.Exception.Message)
    }
}

Write-Host ""
Write-Host "Logs: $logsDir"
