from typing import List, Optional, Any, Dict
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.database import get_db
from app.models.user import User
from app.models.waste import WasteScan, WasteCategory
from app.schemas.waste import ScanOut, WasteCategoryOut
from app.security.auth import get_current_user
from app.services import waste_service
from app.utils.file_utils import save_upload_file

router = APIRouter(prefix="/scanner", tags=["Waste Scanner"])


@router.post("/predict")
def predict_waste(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    # 1. Save uploaded file safely and validate
    saved_rel_path = save_upload_file(file)

    # 2. Run waste classification
    result = waste_service.classify_image(
        image_path=saved_rel_path,
        filename=file.filename or "",
    )

    # 3. Save to database and award user points
    scan = waste_service.save_scan(
        db=db,
        user_id=current_user.id,
        image_path=saved_rel_path,
        result=result,
    )

    return {
        "scan_id": scan.id,
        "predicted_class": result.predicted_class,
        "confidence": result.confidence,
        "category": result.category,
        "recyclable": result.recyclable,
        "disposal_guidance": result.disposal_guidance,
        "bin_type": result.bin_type,
        "safety_note": result.safety_note,
        "model_version": result.model_version,
        "points_awarded": result.points_awarded,
        "alternatives": result.alternatives,
        "image_path": scan.image_path,
        "created_at": scan.created_at,
    }


@router.get("/history", response_model=List[ScanOut])
def get_scan_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    scans = (
        db.query(WasteScan)
        .filter(WasteScan.user_id == current_user.id)
        .order_by(desc(WasteScan.created_at))
        .offset(skip)
        .limit(limit)
        .all()
    )
    return scans


@router.get("/history/{scan_id}", response_model=ScanOut)
def get_single_scan(
    scan_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    scan = db.query(WasteScan).filter(WasteScan.id == scan_id).first()
    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan record not found",
        )

    if current_user.role not in ["authority", "admin", "collector"] and scan.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this scan",
        )
    return scan


@router.get("/categories", response_model=List[WasteCategoryOut])
def list_categories(db: Session = Depends(get_db)):
    categories = db.query(WasteCategory).all()
    return categories
