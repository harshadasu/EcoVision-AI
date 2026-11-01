@echo off
title EcoVision AI Mobile App
cd /d "%~dp0mobile"

echo =======================================================
echo   Launching EcoVision AI Mobile App (Flutter)
echo =======================================================
echo.
echo Starting app in Google Chrome view...
flutter run -d chrome

pause
