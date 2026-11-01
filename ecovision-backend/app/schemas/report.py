from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class ReportCreate(BaseModel):
    client_uuid: str
    category: str
    description: str
    area: str
    latitude: float
    longitude: float


class ReportStatusUpdate(BaseModel):
    status: str
    resolution_note: Optional[str] = None


class ReportOut(BaseModel):
    id: int
    client_uuid: Optional[str] = None
    user_id: Optional[int] = None
    category: str
    description: str
    image_path: Optional[str] = None
    area: str
    latitude: float
    longitude: float
    status: str
    resolution_note: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
