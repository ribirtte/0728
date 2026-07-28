param(
  [int]$Port = 8787
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverScript = Join-Path $root 'server.ps1'
$url = "http://localhost:$Port/"

if (-not (Test-Path $serverScript)) {
  throw "server.ps1 not found at $serverScript"
}

$server = Start-Process -FilePath powershell -ArgumentList @(
  '-NoProfile',
  '-ExecutionPolicy', 'Bypass',
  '-File', $serverScript,
  '-Port', $Port
) -WorkingDirectory $root -WindowStyle Hidden -PassThru

try {
  $ready = $false
  for ($i = 0; $i -lt 40; $i++) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing $url -TimeoutSec 2
      if ($response.StatusCode -eq 200) {
        $ready = $true
        break
      }
    } catch {
      Start-Sleep -Milliseconds 250
    }
  }

  if (-not $ready) {
    throw "Server did not become ready on $url"
  }

  Start-Process $url | Out-Null
  Write-Host "Opened $url"
  Write-Host "Keep this window open to keep the local server alive."
  Wait-Process -Id $server.Id
}
finally {
  if ($server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force
  }
}
