"""
EcoVision AI – API Routes
"""
from __future__ import annotations

import io
import logging
from pathlib import Path
from typing import List

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from fastapi.responses import JSONResponse

from .models import (
    AnalysisRequest,
    AnalysisResponse,
    ChatRequest,
    ChatResponse,
    HealthResponse,
    SearchRequest,
    SearchResponse,
    SearchResult,
)
from .pipeline import add_to_index, analyse_text, chat_response, semantic_search
from .config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1")
settings = get_settings()


# ── Health ──────────────────────────────────────────────
@router.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    return HealthResponse(
        status="ok",
        version=settings.APP_VERSION,
        models_loaded=True,
    )


# ── Text Analysis ────────────────────────────────────────
@router.post("/analyse", response_model=AnalysisResponse, tags=["Analysis"])
async def analyse(req: AnalysisRequest):
    try:
        result = analyse_text(req.text, req.category.value)
        return AnalysisResponse(**result)
    except Exception as e:
        logger.error(f"Analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── Document Upload ──────────────────────────────────────
@router.post("/upload", tags=["Documents"])
async def upload_document(file: UploadFile = File(...)):
    ext = Path(file.filename).suffix.lower().lstrip(".")
    if ext not in ["pdf", "txt", "png", "jpg", "jpeg"]:
        raise HTTPException(status_code=400, detail="Unsupported file type.")

    contents = await file.read()
    size_mb = len(contents) / (1024 * 1024)
    if size_mb > settings.MAX_UPLOAD_SIZE_MB:
        raise HTTPException(status_code=413, detail=f"File exceeds {settings.MAX_UPLOAD_SIZE_MB} MB limit.")

    texts: List[str] = []
    if ext == "txt":
        texts = [contents.decode("utf-8", errors="ignore")]
    elif ext == "pdf":
        try:
            import PyPDF2
            reader = PyPDF2.PdfReader(io.BytesIO(contents))
            texts = [page.extract_text() or "" for page in reader.pages]
            texts = [t for t in texts if t.strip()]
        except Exception as e:
            raise HTTPException(status_code=422, detail=f"PDF parse error: {e}")
    else:
        # Image: return a placeholder analysis
        return JSONResponse({
            "filename": file.filename,
            "type": "image",
            "message": "Image uploaded. Vision analysis requires GPU runtime. Text-based analysis is available.",
            "indexed": 0,
        })

    indexed = add_to_index(texts, source=file.filename)
    return JSONResponse({
        "filename": file.filename,
        "type": ext,
        "pages_or_chunks": len(texts),
        "indexed": indexed,
        "message": f"Successfully indexed {indexed} chunk(s) from '{file.filename}'.",
    })


# ── Semantic Search ───────────────────────────────────────
@router.post("/search", response_model=SearchResponse, tags=["Search"])
async def search(req: SearchRequest):
    try:
        raw = semantic_search(req.query, req.top_k)
        results = [SearchResult(**r) for r in raw]
        return SearchResponse(results=results, total=len(results))
    except Exception as e:
        logger.error(f"Search error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── Chat ─────────────────────────────────────────────────
@router.post("/chat", response_model=ChatResponse, tags=["Chat"])
async def chat(req: ChatRequest):
    try:
        messages = [m.model_dump() for m in req.messages]
        reply, sources = chat_response(messages)
        return ChatResponse(reply=reply, sources=sources)
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── Stats (demo) ─────────────────────────────────────────
@router.get("/stats", tags=["System"])
async def stats():
    return {
        "co2_reduction_tonnes": 1_240_500,
        "documents_indexed": 3_842,
        "analyses_run": 127_600,
        "active_users": 9_812,
        "top_threats": ["deforestation", "ocean plastic", "carbon emissions"],
    }
