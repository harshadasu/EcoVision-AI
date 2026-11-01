from datetime import datetime, timedelta
from typing import Dict, Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.database import get_db
from app.models.user import User
from app.models.waste import WasteScan
from app.models.report import EnvironmentalReport
from app.models.rewards import UserPoints, UserAchievement
from app.security.auth import get_current_user
from app.services.reward_service import get_user_points

router = APIRouter(prefix="/analytics", tags=["Analytics & Impact"])


@router.get("/dashboard")
def get_dashboard_analytics(db: Session = Depends(get_db)) -> Dict[str, Any]:
    total_scans = db.query(WasteScan).count()

    cat_counts = (
        db.query(WasteScan.category, func.count(WasteScan.id))
        .group_by(WasteScan.category)
        .all()
    )
    scans_by_category = {cat: count for cat, count in cat_counts}

    total_reports = db.query(EnvironmentalReport).count()
    rep_status_counts = (
        db.query(EnvironmentalReport.status, func.count(EnvironmentalReport.id))
        .group_by(EnvironmentalReport.status)
        .all()
    )
    reports_by_status = {status: count for status, count in rep_status_counts}

    active_users = db.query(User).filter(User.is_active == True).count()

    top_types_q = (
        db.query(WasteScan.category, func.count(WasteScan.id).label("count"))
        .group_by(WasteScan.category)
        .order_by(desc("count"))
        .limit(5)
        .all()
    )
    top_waste_types = [{"category": row[0], "count": row[1]} for row in top_types_q]

    # Weekly scans for last 7 days
    today = datetime.utcnow().date()
    weekly_scans = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        next_day = day + timedelta(days=1)
        day_count = (
            db.query(WasteScan)
            .filter(WasteScan.created_at >= datetime.combine(day, datetime.min.time()))
            .filter(WasteScan.created_at < datetime.combine(next_day, datetime.min.time()))
            .count()
        )
        weekly_scans.append({
            "date": day.strftime("%Y-%m-%d"),
            "day": day.strftime("%a"),
            "count": day_count,
        })

    # Recyclable items count
    recyclable_count = db.query(WasteScan).filter(WasteScan.recyclable == True).count()
    recycled_kg = round(recyclable_count * 0.35, 2)
    # Average ~1.5 kg CO2 emission prevented per kg of material recycled
    co2_saved = round(recycled_kg * 1.5, 2)

    return {
        "total_scans": total_scans,
        "scans_by_category": scans_by_category,
        "total_reports": total_reports,
        "reports_by_status": reports_by_status,
        "active_users": active_users,
        "top_waste_types": top_waste_types,
        "weekly_scans": weekly_scans,
        "co2_saved": co2_saved,
        "recycled_kg": recycled_kg,
    }


@router.get("/user-stats")
def get_user_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Dict[str, Any]:
    scans_count = db.query(WasteScan).filter(WasteScan.user_id == current_user.id).count()
    reports_count = db.query(EnvironmentalReport).filter(EnvironmentalReport.user_id == current_user.id).count()
    points_rec = get_user_points(db, current_user.id)

    recyclable_count = (
        db.query(WasteScan)
        .filter(WasteScan.user_id == current_user.id, WasteScan.recyclable == True)
        .count()
    )

    recycled_kg = round(recyclable_count * 0.35, 2)
    co2_saved = round(recycled_kg * 1.5, 2)
    achievements_count = db.query(UserAchievement).filter(UserAchievement.user_id == current_user.id).count()

    return {
        "scans": scans_count,
        "reports": reports_count,
        "points": points_rec.balance,
        "total_earned": points_rec.total_earned,
        "co2_saved": co2_saved,
        "recycled_kg": recycled_kg,
        "achievements": achievements_count,
    }
