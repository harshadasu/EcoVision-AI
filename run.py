"""
EcoVision AI – Main Launcher
Run this file directly in VS Code (click the Play ▶ button or press F5).
"""
import os
import sys
from pathlib import Path

# Path to ecovision-backend
backend_dir = Path(__file__).resolve().parent / "ecovision-backend"
if not backend_dir.exists():
    backend_dir = Path(__file__).resolve().parent

# Ensure cwd and sys.path are set to ecovision-backend
os.chdir(backend_dir)
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

import uvicorn

if __name__ == "__main__":
    print("\n=======================================================")
    print("  🌿 EcoVision AI Platform is starting up...")
    print("  👉 Website Frontend: http://localhost:8000/")
    print("  👉 Swagger API Docs:  http://localhost:8000/docs")
    print("=======================================================\n")
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
