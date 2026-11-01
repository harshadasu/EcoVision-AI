import os
import sys
from pathlib import Path

# Automatically ensure cwd and sys.path point to ecovision-backend
current_dir = Path(__file__).resolve().parent
os.chdir(current_dir)
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))

import uvicorn

if __name__ == "__main__":
    print("\n=======================================================")
    print("  🌿 EcoVision AI Platform is starting up...")
    print("  👉 Website Frontend: http://localhost:8000/")
    print("  👉 Swagger API Docs:  http://localhost:8000/docs")
    print("=======================================================\n")
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
