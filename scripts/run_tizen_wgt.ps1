# Samsung Tizen — Flutter Web packaged as .wgt (HTML5 video — works on T-10.0 emulator)
# Usage:
#   .\scripts\run_tizen_wgt.ps1 -SecurityProfile "YourTizenProfile"
#   .\scripts\run_tizen_wgt.ps1 -SecurityProfile "YourTizenProfile" -DeviceSerial emulator-26111
param(
  [Parameter(Mandatory = $true)]
  [string]$SecurityProfile,
  [string]$DeviceSerial = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$flutterBin = "D:\flutter sdk\flutter\bin"
if (Test-Path $flutterBin) { $env:Path = "$flutterBin;$env:Path" }

$tizenTools = "C:\tizen-studio\tools"
if (Test-Path $tizenTools) { $env:Path = "$tizenTools;$env:Path" }

Write-Host "=== Samsung Tizen .wgt pipeline ===" -ForegroundColor Cyan
Write-Host "Use emulator: T-10.0-x86_64 (NOT T-samsung — .wgt install disabled there)" -ForegroundColor Yellow

Write-Host "`n[1/5] flutter build web..." -ForegroundColor Cyan
flutter build web --release --no-web-resources-cdn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n[2/5] patch_tv_js.js + repair_bootstrap.js..." -ForegroundColor Cyan
node patch_tv_js.js
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path "repair_bootstrap.js") { node repair_bootstrap.js }

Write-Host "`n[3/5] tizen package -t wgt..." -ForegroundColor Cyan
tizen package -t wgt -s $SecurityProfile -- ./build/web
if ($LASTEXITCODE -ne 0) {
  Write-Host "Package failed. Create a Tizen cert profile in Certificate Manager (not Samsung-only for T-10.0)." -ForegroundColor Red
  exit $LASTEXITCODE
}

$wgt = Get-ChildItem -Path ".\build\web\*.wgt" | Select-Object -First 1
if (-not $wgt) {
  Write-Host "No .wgt found under build/web" -ForegroundColor Red
  exit 1
}
Write-Host "WGT: $($wgt.FullName)" -ForegroundColor Green

Write-Host "`n[4/5] sdb devices..." -ForegroundColor Cyan
sdb devices
if (-not $DeviceSerial) {
  Write-Host "`nPass -DeviceSerial from the list above, e.g.:" -ForegroundColor Yellow
  Write-Host "  .\scripts\run_tizen_wgt.ps1 -SecurityProfile `"$SecurityProfile`" -DeviceSerial emulator-26111" -ForegroundColor Yellow
  exit 0
}

Write-Host "`n[5/5] install + launch on $DeviceSerial ..." -ForegroundColor Cyan
tizen install -s $DeviceSerial -n $wgt.FullName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

sdb -s $DeviceSerial shell "app_launcher -s tIzeNPlAyR.MultiPlatformVideoPlayer"
Write-Host "Done. Video uses HTML5 (WebAppVideoPlayer) — should be visible on T-10.0." -ForegroundColor Green
