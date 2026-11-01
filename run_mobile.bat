@echo off
echo ==========================================
echo   EcoVision AI - Flutter Mobile App
echo ==========================================
cd /d "%~dp0mobile"

echo.
echo Choose how you want to run the App:
echo [1] Instant App View (Google Chrome - Recommended, No setup needed)
echo [2] Windows Native Desktop App (Requires Windows Developer Mode)
echo [3] Android Phone / Emulator
echo.
set /p target="Enter choice (1, 2, or 3, default is 1): "

if "%target%"=="2" (
    echo Starting Windows Native Desktop App...
    flutter run -d windows
) else if "%target%"=="3" (
    echo Starting on Android...
    flutter run -d android
) else (
    echo Starting Mobile App in Chrome...
    flutter run -d chrome
)

pause
