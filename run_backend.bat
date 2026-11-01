@echo off
cd /d "%~dp0ecovision-backend"
echo ==============================================
echo   Starting EcoVision AI Backend
echo   Swagger UI: http://localhost:8000/docs
echo   Health Check: http://localhost:8000/health
echo ==============================================
python run.py
pause
