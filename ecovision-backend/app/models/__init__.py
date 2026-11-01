from app.database import Base
from app.models.user import User
from app.models.waste import WasteScan, WasteCategory
from app.models.report import EnvironmentalReport
from app.models.location import Hotspot
from app.models.rewards import (
    UserPoints,
    PointTransaction,
    Achievement,
    UserAchievement,
    Reward,
)

__all__ = [
    "Base",
    "User",
    "WasteScan",
    "WasteCategory",
    "EnvironmentalReport",
    "Hotspot",
    "UserPoints",
    "PointTransaction",
    "Achievement",
    "UserAchievement",
    "Reward",
]
