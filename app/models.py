from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum


class EcoCategory(str, Enum):
    DEFORESTATION = "deforestation"
    POLLUTION = "pollution"
    WILDLIFE = "wildlife"
    OCEAN = "ocean"
    CLIMATE = "climate"
    ENERGY = "energy"
    WASTE = "waste"
    GENERAL = "general"


class AnalysisRequest(BaseModel):
    text: str = Field(..., min_length=10, description="Text to analyse for environmental impact")
    category: Optional[EcoCategory] = EcoCategory.GENERAL


class AnalysisResponse(BaseModel):
    category: EcoCategory
    eco_score: float = Field(..., ge=0.0, le=100.0, description="Environmental risk score 0–100")
    summary: str
    recommendations: List[str]
    confidence: float = Field(..., ge=0.0, le=1.0)


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    stream: bool = False


class ChatResponse(BaseModel):
    reply: str
    sources: List[str] = []


class SearchRequest(BaseModel):
    query: str = Field(..., min_length=3)
    top_k: int = Field(5, ge=1, le=20)


class SearchResult(BaseModel):
    text: str
    score: float
    source: str


class SearchResponse(BaseModel):
    results: List[SearchResult]
    total: int


class HealthResponse(BaseModel):
    status: str
    version: str
    models_loaded: bool
