# Encodes a TV-friendly H.264 1080p MP4 (lower bitrate, short GOP).
# Requires FFmpeg: winget install Gyan.FFmpeg  OR  choco install ffmpeg
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$InputVideo = Join-Path $ProjectRoot "assets\videos\sample.mp4"
$OutputVideo = Join-Path $ProjectRoot "assets\videos\sample_tv_1080p_low.mp4"

# ~2.5 Mbps video + AAC — good for Android TV / webOS testing
$VideoBitrate = "2500k"
$MaxRate = "3000k"
$BufSize = "6000k"

function Find-Ffmpeg {
  $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $wingetPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\ffmpeg.exe"
  if (Test-Path $wingetPath) { return $wingetPath }
  return $null
}

$ffmpeg = Find-Ffmpeg
if (-not $ffmpeg) {
  Write-Host "FFmpeg not found." -ForegroundColor Red
  Write-Host "Install: winget install Gyan.FFmpeg" -ForegroundColor Yellow
  Write-Host "Then reopen PowerShell and run this script again." -ForegroundColor Yellow
  exit 1
}

if (-not (Test-Path $InputVideo)) {
  Write-Host "Missing input: $InputVideo" -ForegroundColor Red
  exit 1
}

Write-Host "Input:  $InputVideo" -ForegroundColor Cyan
Write-Host "Output: $OutputVideo" -ForegroundColor Cyan
Write-Host "Profile: H.264 Main @ 1080p, ${VideoBitrate} (TV test)" -ForegroundColor Cyan

& $ffmpeg -y -i $InputVideo `
  -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p `
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" `
  -b:v $VideoBitrate -maxrate $MaxRate -bufsize $BufSize `
  -g 48 -keyint_min 48 -sc_threshold 0 `
  -c:a aac -b:a 128k -ac 2 `
  -movflags +faststart `
  $OutputVideo

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$inSize = (Get-Item $InputVideo).Length / 1MB
$outSize = (Get-Item $OutputVideo).Length / 1MB
Write-Host ("Done. {0:N1} MB -> {1:N1} MB" -f $inSize, $outSize) -ForegroundColor Green
Write-Host "App uses: assets/videos/sample_tv_1080p_low.mp4 (see AppConstants.videoAssetPath)" -ForegroundColor Green
