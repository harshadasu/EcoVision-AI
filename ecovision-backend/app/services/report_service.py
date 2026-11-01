import math
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.report import EnvironmentalReport
from app.schemas.report import ReportCreate
from app.services.reward_service import award_points


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2.0) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return r * c


def create_report(
    db: Session,
    user_id: int,
    data: ReportCreate,
    image_path: Optional[str] = None,
) -> EnvironmentalReport:
    # Check idempotency by client_uuid
    existing = (
        db.query(EnvironmentalReport)
        .filter(EnvironmentalReport.client_uuid == data.client_uuid)
        .first()
    )
    if existing:
        return existing

    report = EnvironmentalReport(
        client_uuid=data.client_uuid,
        user_id=user_id,
        category=data.category,
        description=data.description,
        area=data.area,
        latitude=data.latitude,
        longitude=data.longitude,
        image_path=image_path,
        status="Submitted",
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    # Award citizen reporting points
    award_points(
        db=db,
        user_id=user_id,
        points=20,
        reason=f"Reported civic issue: {data.category} at {data.area}",
        action_type="report",
    )

    return report


def get_reports(
    db: Session,
    user_id: int,
    role: str = "citizen",
    skip: int = 0,
    limit: int = 100,
) -> List[EnvironmentalReport]:
    query = db.query(EnvironmentalReport)
    if role not in ["authority", "admin", "collector"]:
        query = query.filter(EnvironmentalReport.user_id == user_id)
    return query.order_by(desc(EnvironmentalReport.created_at)).offset(skip).limit(limit).all()


def get_report(
    db: Session,
    report_id: int,
    user_id: int,
    role: str = "citizen",
) -> Optional[EnvironmentalReport]:
    report = db.query(EnvironmentalReport).filter(EnvironmentalReport.id == report_id).first()
    if not report:
        return None
    if role not in ["authority", "admin", "collector"] and report.user_id != user_id:
        return None
    return report


def update_report_status(
    db: Session,
    report_id: int,
    status: str,
    note: Optional[str] = None,
    updater_id: Optional[int] = None,
) -> Optional[EnvironmentalReport]:
    report = db.query(EnvironmentalReport).filter(EnvironmentalReport.id == report_id).first()
    if not report:
        return None

    report.status = status
    if note is not None:
        report.resolution_note = note
    if updater_id is not None:
        report.assigned_to = updater_id

    db.commit()
    db.refresh(report)
    return report


def get_nearby_reports(
    db: Session,
    lat: float,
    lng: float,
    radius_km: float = 5.0,
) -> List[EnvironmentalReport]:
    all_reports = db.query(EnvironmentalReport).all()
    nearby = []
    for rep in all_reports:
        dist = haversine_distance(lat, lng, rep.latitude, rep.longitude)
        if dist <= radius_km:
            nearby.append(rep)
    return nearby
