from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class PointsOut(BaseModel):
    balance: int
    total_earned: int

    model_config = ConfigDict(from_attributes=True)


class TransactionOut(BaseModel):
    id: Optional[int] = None
    points: int
    reason: str
    action_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AchievementOut(BaseModel):
    id: int
    title: str
    description: str
    icon: str
    points_required: int
    badge_color: str
    earned: bool = False
    earned_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class RewardOut(BaseModel):
    id: int
    title: str
    description: str
    points_cost: int
    category: str
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: int
    name: str
    points: int
