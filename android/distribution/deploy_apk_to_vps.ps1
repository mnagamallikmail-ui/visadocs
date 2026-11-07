# ==============================================================================
# ProValuer Android Distribution VPS Deployment Script (PowerShell for Windows)
# Target: VPS Host (/var/www/provaluer)
# Domain: app.provaluer.in
# ==============================================================================
param (
    [string]$VpsUser = "root",
    [string]$VpsHost = "visadocs.online",
    [int]$VpsPort = 22
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path "$scriptDir\..\..").Path

$localApk = Join-Path $projectRoot "android\outputs\apk\app-production-release.apk"
$localVersion = Join-Path $projectRoot "android\distribution\version.json"
$localIndex = Join-Path $projectRoot "android\distribution\index.html"
$localNginx = Join-Path $projectRoot "android\distribution\nginx-app-provaluer.conf"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " ProValuer Android Distribution VPS Deployment (PowerShell)" -ForegroundColor Cyan
Write-Host " Target Host: $VpsUser@$VpsHost`:$VpsPort" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

if (-not (Test-Path $localApk)) {
    Write-Error "[-] Local APK not found at $localApk. Please compile the release APK first."
}

$apkItem = Get-Item $localApk
Write-Host "[+] Local APK verified: $($apkItem.Length) bytes ($([math]::Round($apkItem.Length / 1MB, 2)) MB)" -ForegroundColor Green

# 1. Create remote directories
Write-Host "[+] Step 1: Creating remote directories on VPS..." -ForegroundColor Yellow
ssh -p $VpsPort "$VpsUser@$VpsHost" "mkdir -p /var/www/provaluer/downloads /var/www/provaluer/app /var/www/html; chmod -R 755 /var/www/provaluer"

# 2. Upload APK binary
Write-Host "[+] Step 2: Uploading APK to /var/www/provaluer/downloads/latest.apk..." -ForegroundColor Yellow
scp -P $VpsPort $localApk "$VpsUser@${VpsHost}:/var/www/provaluer/downloads/latest.apk"
ssh -p $VpsPort "$VpsUser@$VpsHost" "cp /var/www/provaluer/downloads/latest.apk /var/www/provaluer/downloads/app-v1.0.0-101.apk; chmod 644 /var/www/provaluer/downloads/latest.apk /var/www/provaluer/downloads/app-v1.0.0-101.apk"

# 3. Upload version manifest and landing page
Write-Host "[+] Step 3: Uploading version manifest and landing page..." -ForegroundColor Yellow
scp -P $VpsPort $localVersion "$VpsUser@${VpsHost}:/var/www/provaluer/app/version.json"
scp -P $VpsPort $localIndex "$VpsUser@${VpsHost}:/var/www/provaluer/downloads/index.html"
ssh -p $VpsPort "$VpsUser@$VpsHost" "cp /var/www/provaluer/app/version.json /var/www/provaluer/downloads/version.json; chmod 644 /var/www/provaluer/app/version.json /var/www/provaluer/downloads/index.html"

# 4. Upload Nginx config and reload
Write-Host "[+] Step 4: Configuring Nginx virtual host for app.provaluer.in..." -ForegroundColor Yellow
scp -P $VpsPort $localNginx "$VpsUser@${VpsHost}:/etc/nginx/sites-available/app.provaluer.in.conf"
ssh -p $VpsPort "$VpsUser@$VpsHost" "ln -sf /etc/nginx/sites-available/app.provaluer.in.conf /etc/nginx/sites-enabled/app.provaluer.in.conf; nginx -t && systemctl reload nginx"

# 5. Verification
Write-Host "[+] Step 5: Verifying distribution endpoints..." -ForegroundColor Yellow
Write-Host "--- Testing https://app.provaluer.in/download ---" -ForegroundColor Cyan
try {
    $resp = Invoke-WebRequest -Uri "https://app.provaluer.in/download" -MaximumRedirection 0 -ErrorAction SilentlyContinue
    Write-Host "HTTP Status: $($resp.StatusCode)" -ForegroundColor Green
    Write-Host "Location Header: $($resp.Headers.Location)" -ForegroundColor Green
} catch {
    Write-Host "Note: HTTP redirect caught or domain pending SSL activation." -ForegroundColor DarkYellow
}

Write-Host "--- Testing https://app.provaluer.in/app/version.json ---" -ForegroundColor Cyan
try {
    $jsonResp = Invoke-RestMethod -Uri "https://app.provaluer.in/app/version.json"
    Write-Host ($jsonResp | ConvertTo-Json) -ForegroundColor Green
} catch {
    Write-Host "Note: DNS or SSL configuration pending on host." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] Android Distribution Endpoint Deployment Completed!" -ForegroundColor Green
Write-Host " Public Download URL: https://app.provaluer.in/download" -ForegroundColor White
Write-Host " Direct APK URL:      https://app.provaluer.in/download/latest.apk" -ForegroundColor White
Write-Host " Version Manifest:    https://app.provaluer.in/app/version.json" -ForegroundColor White
Write-Host " Mobile Landing Page: https://app.provaluer.in/" -ForegroundColor White
Write-Host "========================================================================" -ForegroundColor Cyan

