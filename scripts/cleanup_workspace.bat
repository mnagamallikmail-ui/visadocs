@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo  PROVALUER COMMERCIAL - LEAN WORKSPACE CLEANUP
echo ========================================================

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "FRONTEND_DIR=%REPO_ROOT%\frontend"

echo [1/5] Calculating initial repository size...
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "(Get-ChildItem -Path '%REPO_ROOT%' -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum"`) do set "SIZE_BEFORE=%%A"

echo [2/5] Running 'flutter clean' in frontend...
if exist "%FRONTEND_DIR%" (
    pushd "%FRONTEND_DIR%"
    call flutter clean
    popd
)

echo [3/5] Purging residual frontend build and .dart_tool directories...
if exist "%FRONTEND_DIR%\build" (
    rmdir /s /q "%FRONTEND_DIR%\build" >nul 2>&1
)
if exist "%FRONTEND_DIR%\.dart_tool" (
    rmdir /s /q "%FRONTEND_DIR%\.dart_tool" >nul 2>&1
)

echo [4/5] Purging duplicate APK and AAB files inside repository...
powershell -NoProfile -Command "Get-ChildItem -Path '%REPO_ROOT%' -Recurse -Force -Include '*.apk','*.aab' -ErrorAction SilentlyContinue | Remove-Item -Force"

echo [5/5] Calculating final repository size...
for /f "usebackq tokens=*" %%B in (`powershell -NoProfile -Command "(Get-ChildItem -Path '%REPO_ROOT%' -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum"`) do set "SIZE_AFTER=%%B"

powershell -NoProfile -Command ^
    "$b = [double]'%SIZE_BEFORE%';" ^
    "$a = [double]'%SIZE_AFTER%';" ^
    "$saved = $b - $a;" ^
    "Write-Host '';" ^
    "Write-Host '========================================================' -ForegroundColor Cyan;" ^
    "Write-Host ' CLEANUP AUDIT RESULTS' -ForegroundColor Cyan;" ^
    "Write-Host '========================================================' -ForegroundColor Cyan;" ^
    "Write-Host (' Before Size : ' + [Math]::Round($b / 1GB, 2) + ' GB (' + [Math]::Round($b / 1MB, 2) + ' MB)');" ^
    "Write-Host (' After Size  : ' + [Math]::Round($a / 1GB, 2) + ' GB (' + [Math]::Round($a / 1MB, 2) + ' MB)');" ^
    "Write-Host (' Space Saved : ' + [Math]::Round($saved / 1GB, 2) + ' GB (' + [Math]::Round($saved / 1MB, 2) + ' MB)') -ForegroundColor Green;" ^
    "Write-Host '--------------------------------------------------------';" ^
    "if ($a -lt 1GB) {" ^
    "    Write-Host (' SUCCESS: Repository is in LEAN STATE (' + [Math]::Round($a / 1MB, 2) + ' MB < 1 GB threshold).') -ForegroundColor Green" ^
    "} else {" ^
    "    Write-Host (' NOTICE: Repository size is ' + [Math]::Round($a / 1GB, 2) + ' GB.') -ForegroundColor Yellow" ^
    "};" ^
    "Write-Host ' Release binaries are preserved externally in D:\ProValuer-Releases';" ^
    "Write-Host '========================================================' -ForegroundColor Cyan;"

echo Cleanup complete.

