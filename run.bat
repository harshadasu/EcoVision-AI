@echo off
echo ==========================================
echo   EcoVision AI - Starting Server
echo ==========================================
cd /d "%~dp0"

REM Create data directories
if not exist "data" mkdir data
if not exist "data\uploads" mkdir data\uploads

REM Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause
