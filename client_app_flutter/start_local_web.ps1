param(
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logsDir = Join-Path $root "build_artifacts\local_logs"
$stdout = Join-Path $logsDir "flutter-web.out.log"
$stderr = Join-Path $logsDir "flutter-web.err.log"

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

if (Test-Path $stdout) {
    try { Clear-Content $stdout -ErrorAction Stop } catch {}
}
if (Test-Path $stderr) {
    try { Clear-Content $stderr -ErrorAction Stop } catch {}
}

function Get-FreePort {
    param([int]$StartPort)

    for ($candidate = $StartPort; $candidate -lt ($StartPort + 100); $candidate++) {
        $listener = Get-NetTCPConnection -LocalPort $candidate -State Listen -ErrorAction SilentlyContinue
        if (-not $listener) {
            return $candidate
        }
    }

    throw "Could not find a free port in range $StartPort-$($StartPort + 99)"
}

$selectedPort = Get-FreePort -StartPort $Port
if ($selectedPort -ne $Port) {
    Write-Host "Port $Port is busy, using free port $selectedPort instead."
}

$arguments = @(
    "run",
    "-d", "web-server",
    "--web-hostname", "127.0.0.1",
    "--web-port", "$selectedPort",
    "--dart-define=API_HOST=127.0.0.1",
    "--dart-define=API_SCHEME=http"
)

Start-Process `
    -FilePath "flutter" `
    -ArgumentList $arguments `
    -WorkingDirectory $root `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr | Out-Null

Write-Host "Starting Flutter web on http://127.0.0.1:$selectedPort"

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$selectedPort" -TimeoutSec 5
        Write-Host "Flutter web is ready: http://127.0.0.1:$selectedPort"
        Write-Host "Logs: $logsDir"
        exit 0
    }
    catch {
    }
}

Write-Host "Flutter web is still starting at http://127.0.0.1:$selectedPort. Check logs in $logsDir"
