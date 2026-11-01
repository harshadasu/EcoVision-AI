from typing import List, Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.report import ReportCreate, ReportOut, ReportStatusUpdate
from app.security.auth import get_current_user, require_role
from app.services import report_service
from app.utils.file_utils import save_upload_file

router = APIRouter(prefix="/reports", tags=["Environmental Reports"])


@router.post("/", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
def submit_report(
    client_uuid: str = Form(...),
    category: str = Form(...),
    description: str = Form(...),
    area: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    image_path: Optional[str] = None
    if file and file.filename:
        image_path = save_upload_file(file)

    report_in = ReportCreate(
        client_uuid=client_uuid,
        category=category,
        description=description,
        area=area,
        latitude=latitude,
        longitude=longitude,
    )

    report = report_service.create_report(
        db=db,
        user_id=current_user.id,
        data=report_in,
        image_path=image_path,
    )
    return report


@router.get("/", response_model=List[ReportOut])
def list_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return report_service.get_reports(
        db=db,
        user_id=current_user.id,
        role=current_user.role,
        skip=skip,
        limit=limit,
    )


@router.get("/my", response_model=List[ReportOut])
def get_my_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return report_service.get_reports(
        db=db,
        user_id=current_user.id,
        role="citizen",
        skip=skip,
        limit=limit,
    )


@router.get("/nearby", response_model=List[ReportOut])
def get_nearby_reports(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
    radius_km: float = Query(5.0, ge=0.1, le=50.0, description="Radius in km"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return report_service.get_nearby_reports(
        db=db,
        lat=lat,
        lng=lng,
        radius_km=radius_km,
    )


@router.get("/{report_id}", response_model=ReportOut)
def get_report_detail(
    report_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    report = report_service.get_report(
        db=db,
        report_id=report_id,
        user_id=current_user.id,
        role=current_user.role,
    )
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found or access restricted",
        )
    return report


@router.patch("/{report_id}/status", response_model=ReportOut)
def update_status(
    report_id: int,
    status_update: ReportStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("authority", "admin", "collector")),
):
    valid_statuses = ["Submitted", "Under Review", "Assigned", "Resolved", "Rejected"]
    if status_update.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}",
        )

    updated = report_service.update_report_status(
        db=db,
        report_id=report_id,
        status=status_update.status,
        note=status_update.resolution_note,
        updater_id=current_user.id,
    )
    if not updated:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found",
        )
    return updated
