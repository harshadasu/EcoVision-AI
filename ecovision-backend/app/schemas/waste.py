from datetime import datetime
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, ConfigDict


class AlternativeCategory(BaseModel):
    category: str
    confidence: float
    recyclable: bool


class ClassificationResult(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

    predicted_class: str
    confidence: float
    category: str
    recyclable: bool
    disposal_guidance: str
    bin_type: Optional[str] = "General Waste"
    safety_note: Optional[str] = None
    model_version: str = "1.0.0"
    points_awarded: int = 10
    alternatives: List[Dict[str, Any]] = []


class ScanCreate(BaseModel):
    confirmed_class: Optional[str] = None


class ScanOut(BaseModel):
    id: int
    predicted_class: str
    confidence: float
    category: str
    recyclable: bool
    disposal_guidance: str
    image_path: Optional[str] = None
    model_version: str = "1.0.0"
    created_at: datetime

    model_config = ConfigDict(from_attributes=True, protected_namespaces=())


class ScanResponse(BaseModel):
    scan_id: int
    result: ClassificationResult


class WasteCategoryOut(BaseModel):
    id: int
    name: str
    description: str
    disposal_guidance: str
    recyclable: bool
    color_code: str
    icon_name: str
    bin_type: str

    model_config = ConfigDict(from_attributes=True)
