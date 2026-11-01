from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models.location import Hotspot
from app.models.report import EnvironmentalReport
from app.services.report_service import haversine_distance


def get_hotspots(
    db: Session,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radius_km: Optional[float] = None,
    hotspot_type: Optional[str] = None,
) -> List[Hotspot]:
    query = db.query(Hotspot)
    if hotspot_type:
        query = query.filter(Hotspot.type == hotspot_type)

    all_items = query.all()

    if lat is not None and lng is not None and radius_km is not None:
        filtered = []
        for item in all_items:
            dist = haversine_distance(lat, lng, item.latitude, item.longitude)
            if dist <= radius_km:
                filtered.append(item)
        return filtered

    return all_items


def create_hotspot(
    db: Session,
    data: Dict[str, Any],
    user_id: Optional[int] = None,
) -> Hotspot:
    hotspot = Hotspot(
        name=data["name"],
        type=data.get("type", "hotspot"),
        latitude=data["latitude"],
        longitude=data["longitude"],
        description=data.get("description"),
        severity=data.get("severity"),
        is_verified=data.get("is_verified", True),
    )
    db.add(hotspot)
    db.commit()
    db.refresh(hotspot)
    return hotspot


def get_map_summary(db: Session) -> Dict[str, Any]:
    hotspot_count = db.query(Hotspot).filter(Hotspot.type == "hotspot").count()
    centre_count = db.query(Hotspot).filter(Hotspot.type == "recycling_centre").count()
    collection_count = db.query(Hotspot).filter(Hotspot.type == "collection_point").count()

    active_reports = (
        db.query(EnvironmentalReport.area, func.count(EnvironmentalReport.id))
        .filter(EnvironmentalReport.status.in_(["Submitted", "Under Review", "Assigned"]))
        .group_by(EnvironmentalReport.area)
        .all()
    )

    return {
        "total_hotspots": hotspot_count,
        "recycling_centres": centre_count,
        "collection_points": collection_count,
        "active_reports_by_area": {area: count for area, count in active_reports},
    }


def seed_sample_hotspots(db: Session) -> None:
    sample_data = [
        {
            "name": "Kothrud E-Waste & Plastic Depot",
            "type": "recycling_centre",
            "latitude": 18.5074,
            "longitude": 73.8077,
            "description": "Certified drop-off centre for electronic scrap, cables, and sorted plastics.",
            "severity": None,
            "is_verified": True,
        },
        {
            "name": "Shivaji Nagar Overflow Hotspot",
            "type": "hotspot",
            "latitude": 18.5314,
            "longitude": 73.8446,
            "description": "Repeated municipal container overflow near market junction.",
            "severity": "high",
            "is_verified": True,
        },
        {
            "name": "Viman Nagar Swachh Collection Point",
            "type": "collection_point",
            "latitude": 18.5679,
            "longitude": 73.9143,
            "description": "Secondary segregated dry waste transfer and sorting station.",
            "severity": None,
            "is_verified": True,
        },
        {
            "name": "Hadapsar Industrial Waste Hotspot",
            "type": "hotspot",
            "latitude": 18.5089,
            "longitude": 73.9260,
            "description": "Mixed commercial packaging accumulation site requiring clearing.",
            "severity": "medium",
            "is_verified": True,
        },
        {
            "name": "Aundh Community Composting & Bottle Bank",
            "type": "recycling_centre",
            "latitude": 18.5580,
            "longitude": 73.8075,
            "description": "Glass bottle recycling drop-off and decentralized wet waste composting unit.",
            "severity": None,
            "is_verified": True,
        },
    ]

    for item in sample_data:
        exists = db.query(Hotspot).filter(Hotspot.name == item["name"]).first()
        if not exists:
            h = Hotspot(
                name=item["name"],
                type=item["type"],
                latitude=item["latitude"],
                longitude=item["longitude"],
                description=item["description"],
                severity=item["severity"],
                is_verified=item["is_verified"],
            )
            db.add(h)
    db.commit()
