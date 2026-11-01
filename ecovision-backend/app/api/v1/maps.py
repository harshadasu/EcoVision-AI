from typing import List, Optional, Dict, Any
from datetime import datetime
from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.security.auth import require_role
from app.services import map_service

router = APIRouter(prefix="/maps", tags=["Maps & Hotspots"])


class HotspotCreate(BaseModel):
    name: str
    type: str = "hotspot"  # hotspot / recycling_centre / collection_point
    latitude: float
    longitude: float
    description: Optional[str] = None
    severity: Optional[str] = None  # low / medium / high
    is_verified: bool = True


class HotspotOut(BaseModel):
    id: int
    name: str
    type: str
    latitude: float
    longitude: float
    description: Optional[str] = None
    severity: Optional[str] = None
    is_verified: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


@router.get("/hotspots", response_model=List[HotspotOut])
def list_hotspots(
    lat: Optional[float] = Query(None, description="Optional center latitude"),
    lng: Optional[float] = Query(None, description="Optional center longitude"),
    radius_km: Optional[float] = Query(None, ge=0.1, le=100.0, description="Optional radius in km"),
    type: Optional[str] = Query(None, description="Filter by type (hotspot, recycling_centre, collection_point)"),
    db: Session = Depends(get_db),
):
    return map_service.get_hotspots(
        db=db,
        lat=lat,
        lng=lng,
        radius_km=radius_km,
        hotspot_type=type,
    )


@router.post("/hotspots", response_model=HotspotOut, status_code=status.HTTP_201_CREATED)
def create_hotspot(
    data: HotspotCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    return map_service.create_hotspot(
        db=db,
        data=data.model_dump(),
        user_id=current_user.id,
    )


@router.get("/centres", response_model=List[HotspotOut])
def get_recycling_centres(db: Session = Depends(get_db)):
    return map_service.get_hotspots(db=db, hotspot_type="recycling_centre")


@router.get("/summary")
def get_summary(db: Session = Depends(get_db)) -> Dict[str, Any]:
    return map_service.get_map_summary(db=db)
