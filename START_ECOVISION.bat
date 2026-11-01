@echo off
title EcoVision AI Platform
cd /d "%~dp0"

echo =======================================================
echo   Starting EcoVision AI Platform...
echo =======================================================

:: Install requirements if not already present
echo Checking dependencies...
python -m pip install -q -r ecovision-backend\requirements.txt

:: Launch server
echo Starting server on http://localhost:8000 ...
start "" http://localhost:8000/
python run.py

pause
