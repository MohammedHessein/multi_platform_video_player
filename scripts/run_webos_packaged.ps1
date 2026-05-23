# LG webOS — packaged .ipk (file://) — closer to real TV than ares-launch -H hosted
# Prerequisite: ares-cli, webOS TV emulator or physical TV registered
param(
  [string]$DeviceName = "emulator"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$flutterBin = "D:\flutter sdk\flutter\bin"
if (Test-Path $flutterBin) { $env:Path = "$flutterBin;$env:Path" }

function Show-AresDevices {
  Write-Host "`nRegistered ares devices:" -ForegroundColor Cyan
  ares-setup-device --list 2>&1
  Write-Host "`nUse: .\scripts\run_webos_packaged.ps1 -DeviceName <name from list>" -ForegroundColor Yellow
  Write-Host "Default webOS emulator is usually: emulator" -ForegroundColor Yellow
}

function Test-AresDevice([string]$name) {
  $list = ares-setup-device --list 2>&1 | Out-String
  return $list -match [regex]::Escape($name)
}

Write-Host "=== LG webOS .ipk pipeline ===" -ForegroundColor Cyan

if (-not (Test-AresDevice $DeviceName)) {
  Write-Host "Device '$DeviceName' is not registered in ares." -ForegroundColor Red
  Show-AresDevices
  Write-Host "`nTo add a physical LG TV (example):" -ForegroundColor Yellow
  Write-Host '  ares-setup-device -a tv_living_room -i "host=192.168.x.x" -i "port=9922" -i "username=developer"' -ForegroundColor Gray
  Write-Host "  ares-novacom --device tv_living_room --getkey" -ForegroundColor Gray
  exit 1
}

Write-Host "`n[1/4] flutter build web..." -ForegroundColor Cyan
# base href "./" for file:// is applied by patch_tv_js.js after build (Flutter only accepts /.../ here).
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[2/4] patch + repair..." -ForegroundColor Cyan
node patch_tv_js.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path "repair_bootstrap.js") { node repair_bootstrap.js }

Write-Host "`n[3/4] ares-package (no minify)..." -ForegroundColor Cyan
ares-package --no-minify ./build/web
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ipk = Get-ChildItem -Filter "com.multiplatform.videoplayer_*.ipk" | Select-Object -First 1
if (-not $ipk) {
  Write-Host "No .ipk found in project root" -ForegroundColor Red
  exit 1
}
Write-Host "IPK: $($ipk.Name)" -ForegroundColor Green

Write-Host "`n[4/4] install + launch on '$DeviceName' ..." -ForegroundColor Cyan
ares-install -d $DeviceName $ipk.Name
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
ares-launch -d $DeviceName com.multiplatform.videoplayer
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nDone. In app logs look for: WebTV video loaded from: .../media/sample.mp4" -ForegroundColor Green
