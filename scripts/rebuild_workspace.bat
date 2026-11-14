@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo  PROVALUER COMMERCIAL - WORKSPACE REBUILD PIPELINE
echo ========================================================

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
set "FRONTEND_DIR=%REPO_ROOT%\frontend"
set "RELEASE_DIR=D:\ProValuer-Releases"

if not exist "%FRONTEND_DIR%" (
    echo [ERROR] Frontend directory not found at "%FRONTEND_DIR%"
    exit /b 1
)

pushd "%FRONTEND_DIR%"

if /i "%~1"=="dev" goto :BUILD_DEV
if /i "%~1"=="arm64" goto :BUILD_DEV
if /i "%~1"=="/dev" goto :BUILD_DEV

:BUILD_RELEASE
echo.
echo Mode: FULL PRODUCTION RELEASE (Universal APK + Play Store AAB)
echo --------------------------------------------------------
echo [1/3] Resolving dependencies (flutter pub get)...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter pub get failed.
    popd
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Building Universal Production Release APK...
call flutter build apk --flavor production --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter build apk failed.
    popd
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Building Production Release App Bundle (AAB)...
call flutter build appbundle --flavor production --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter build appbundle failed.
    popd
    exit /b %ERRORLEVEL%
)

popd

echo.
echo ========================================================
echo  EXPORTING RELEASE BINARIES TO EXTERNAL REPOSITORY
echo  Target: %RELEASE_DIR%
echo ========================================================
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"

if exist "%FRONTEND_DIR%\build\app\outputs\flutter-apk\app-production-release.apk" (
    copy /y "%FRONTEND_DIR%\build\app\outputs\flutter-apk\app-production-release.apk" "%RELEASE_DIR%\app-production-universal-release.apk" >nul
    echo  [+] Exported: %RELEASE_DIR%\app-production-universal-release.apk
)
if exist "%FRONTEND_DIR%\build\app\outputs\bundle\productionRelease\app-production-release.aab" (
    copy /y "%FRONTEND_DIR%\build\app\outputs\bundle\productionRelease\app-production-release.aab" "%RELEASE_DIR%\app-production-release.aab" >nul
    echo  [+] Exported: %RELEASE_DIR%\app-production-release.aab
)

echo.
echo Rebuild complete. Artifacts stored in %RELEASE_DIR%.
exit /b 0

:BUILD_DEV
echo.
echo Mode: LEAN LOCAL DEV BUILD (--target-platform android-arm64)
echo Saves ~290 MB build intermediates and ~42 MB APK download size
echo --------------------------------------------------------
echo [1/2] Resolving dependencies (flutter pub get)...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter pub get failed.
    popd
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Building Lean 64-bit ARM APK (--target-platform android-arm64)...
call flutter build apk --flavor production --release --target-platform android-arm64
if %ERRORLEVEL% neq 0 (
    echo [ERROR] flutter build apk [arm64] failed.
    popd
    exit /b %ERRORLEVEL%
)

popd

if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
if exist "%FRONTEND_DIR%\build\app\outputs\flutter-apk\app-production-release.apk" (
    copy /y "%FRONTEND_DIR%\build\app\outputs\flutter-apk\app-production-release.apk" "%RELEASE_DIR%\app-production-arm64-v8a-release.apk" >nul
    echo  [+] Exported: %RELEASE_DIR%\app-production-arm64-v8a-release.apk
)

echo.
echo Lean dev rebuild complete. Artifacts stored in %RELEASE_DIR%.
exit /b 0

