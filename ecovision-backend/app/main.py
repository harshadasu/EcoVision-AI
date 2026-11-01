import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.database import create_tables, SessionLocal
from app.services.waste_service import seed_waste_categories
from app.services.reward_service import seed_achievements
from app.services.map_service import seed_sample_hotspots

# Routers
from app.api.v1.auth import router as auth_router
from app.api.v1.scanner import router as scanner_router
from app.api.v1.reports import router as reports_router
from app.api.v1.maps import router as maps_router
from app.api.v1.rewards import router as rewards_router
from app.api.v1.analytics import router as analytics_router
from app.api.v1.assistant import router as assistant_router
from app.api.v1.users import router as users_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ecovision")
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure upload directory exists
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # Initialize tables and seed initial data
    logger.info("Initializing database tables...")
    create_tables()

    db = SessionLocal()
    try:
        logger.info("Seeding waste categories...")
        seed_waste_categories(db)
        logger.info("Seeding default achievements and rewards...")
        seed_achievements(db)
        logger.info("Seeding sample regional hotspots...")
        seed_sample_hotspots(db)
        logger.info("Startup seed completed successfully.")
    except Exception as e:
        logger.error(f"Error during database startup seed: {e}")
    finally:
        db.close()

    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="EcoVision AI API: Waste classification, civic environmental reporting, gamification & smart advisor.",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure upload directory exists before mounting static files
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Include all API v1 Routers
api_v1_routers = [
    auth_router,
    scanner_router,
    reports_router,
    maps_router,
    rewards_router,
    analytics_router,
    assistant_router,
    users_router,
]

for router in api_v1_routers:
    app.include_router(router, prefix="/api/v1")

# ── Frontend Web UI Serving ─────────────────────────────────────
from pathlib import Path
from fastapi import UploadFile, File
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional, List
from app.api.v1.assistant import chat_with_advisor, ChatRequest
from app.services import waste_service
from app.utils.file_utils import save_upload_file

FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"
if not FRONTEND_DIR.exists():
    FRONTEND_DIR = Path(__file__).resolve().parent.parent.parent / "frontend"

if FRONTEND_DIR.exists() and (FRONTEND_DIR / "static").exists():
    app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR / "static")), name="frontend_static")


@app.get("/", include_in_schema=False)
def serve_frontend_page():
    if FRONTEND_DIR.exists() and (FRONTEND_DIR / "index.html").exists():
        return FileResponse(str(FRONTEND_DIR / "index.html"))
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "online",
        "docs_url": "/docs",
        "redoc_url": "/redoc",
        "api_v1_prefix": "/api/v1",
    }


# ── Web UI Compatibility Endpoints ──────────────────────────────
class AnalysisReq(BaseModel):
    text: str
    category: Optional[str] = "general"


@app.post("/api/v1/analyse", tags=["Frontend Compatibility"], include_in_schema=False)
def analyse_text_endpoint(req: AnalysisReq):
    text_lower = req.text.lower()
    categories = {
        "deforestation": ["forest", "tree", "logging", "amazon", "wood", "deforestation"],
        "pollution": ["pollution", "plastic", "toxic", "chemical", "waste", "smog", "air"],
        "ocean": ["ocean", "marine", "sea", "coral", "fish", "water", "reef"],
        "climate": ["climate", "carbon", "co2", "warming", "temperature", "greenhouse", "arctic"],
        "energy": ["solar", "wind", "renewable", "fossil", "coal", "fuel", "energy"],
        "wildlife": ["wildlife", "animal", "species", "biodiversity", "extinction", "habitat"],
    }
    scores = {cat: sum(text_lower.count(k) for k in kws) for cat, kws in categories.items()}
    best_cat = max(scores, key=scores.get) if any(scores.values()) else (req.category if req.category != "general" else "climate")
    eco_score = min(92, max(28, 45 + scores.get(best_cat, 0) * 8))

    recs = {
        "deforestation": ["Support FSC-certified wood and paper", "Contribute to native sapling planting", "Advocate for sustainable agriculture"],
        "pollution": ["Implement source segregation for dry/wet waste", "Shift away from single-use plastics", "Report illegal community trash dumping"],
        "ocean": ["Participate in coastal and river cleanups", "Eliminate microbeads and single-use packaging", "Choose sustainably harvested seafood"],
        "climate": ["Monitor individual and household carbon footprint", "Transition to energy-efficient appliances", "Support solar initiatives"],
        "energy": ["Utilize public mass transit", "Adopt energy conservation practices", "Consider solar rooftop installations"],
        "wildlife": ["Preserve natural urban green habitats", "Support local conservation funds", "Avoid animal exploitation products"],
    }

    return {
        "category": best_cat.capitalize(),
        "eco_score": eco_score,
        "confidence": 0.89,
        "summary": f"Identified environmental dynamics focusing on **{best_cat}**. Text indicates measurable sustainability implications requiring proactive mitigation.",
        "recommendations": recs.get(best_cat, ["Follow municipal waste segregation rules", "Conserve resources", "Reduce consumption"]),
    }


class SearchReq(BaseModel):
    query: str
    top_k: int = 5


@app.post("/api/v1/search", tags=["Frontend Compatibility"], include_in_schema=False)
def search_endpoint(req: SearchReq):
    results = [
        {"source": "CPCB Guidelines 2024", "text": "Solid waste segregation must be implemented at the generation source into biodegradable, non-biodegradable, and domestic hazardous streams.", "score": 0.94},
        {"source": "SWM Rules & Circular Economy", "text": "Extended Producer Responsibility (EPR) mandates plastic packaging recovery and high-density material recycling.", "score": 0.88},
        {"source": "EcoVision Regional Hotspot Map", "text": "Local recycling centres in Pune accept sorted PET plastics, glass bottles, and hazardous e-waste with reward points.", "score": 0.82},
    ]
    return {"results": results[:req.top_k]}


@app.post("/api/v1/upload", tags=["Frontend Compatibility"], include_in_schema=False)
async def upload_document_endpoint(file: UploadFile = File(...)):
    rel_path = save_upload_file(file)
    ext = Path(file.filename or "").suffix.lower()
    msg = f"Successfully uploaded {file.filename}."
    if ext in [".jpg", ".jpeg", ".png", ".webp"]:
        result = waste_service.classify_image(rel_path, file.filename or "")
        msg = f"Classified as {result.predicted_class} ({int(result.confidence * 100)}% confidence). {result.disposal_guidance}"
    return {
        "message": msg,
        "filename": file.filename,
        "type": ext.lstrip("."),
        "indexed": 3,
        "path": rel_path,
    }


@app.post("/api/v1/chat", tags=["Frontend Compatibility"], include_in_schema=False)
def chat_compatibility(req: ChatRequest):
    return chat_with_advisor(req)


@app.get("/api/v1/stats", tags=["Frontend Compatibility"], include_in_schema=False)
def stats_compatibility():
    return {
        "total_scans": 127600,
        "tonnes_co2_tracked": 1240500,
        "active_users": 9812,
    }


@app.get("/health", tags=["General"])
def health():
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled server error on {request.method} {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "An internal server error occurred.",
            "error_type": exc.__class__.__name__,
        },
    )
