# LG webOS TV — hosted dev launch (recommended; http:// works, file:// .ipk is fragile)
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$flutterBin = "D:\flutter sdk\flutter\bin"
if (Test-Path $flutterBin) {
  $env:Path = "$flutterBin;$env:Path"
}

Write-Host "Building Flutter web for TV..." -ForegroundColor Cyan
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Patching for webOS TV (includes media/ + CanvasKit)..." -ForegroundColor Cyan
node patch_tv_js.js
node repair_bootstrap.js

Write-Host "Launching on emulator (hosted)..." -ForegroundColor Cyan
Write-Host "Use TV remote; Ctrl+C here stops the host server." -ForegroundColor Yellow
ares-launch -H .\build\web -d emulator
