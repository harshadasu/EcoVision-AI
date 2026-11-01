from typing import List, Dict, Any
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.rewards import Achievement, UserAchievement, Reward
from app.schemas.rewards import (
    PointsOut,
    TransactionOut,
    AchievementOut,
    RewardOut,
    LeaderboardEntry,
)
from app.security.auth import get_current_user
from app.services import reward_service

router = APIRouter(prefix="/rewards", tags=["Rewards & Gamification"])


@router.get("/points", response_model=PointsOut)
def get_user_points(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    points_rec = reward_service.get_user_points(db, current_user.id)
    return points_rec


@router.get("/transactions", response_model=List[TransactionOut])
def get_user_transactions(
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return reward_service.get_transactions(db, current_user.id, limit=limit)


@router.get("/leaderboard", response_model=List[LeaderboardEntry])
def get_leaderboard(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    return reward_service.get_leaderboard(db, limit=limit)


@router.get("/achievements", response_model=List[AchievementOut])
def list_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Ensure any pending achievements are awarded
    reward_service.check_achievements(db, current_user.id)

    all_achievements = db.query(Achievement).all()
    user_achievements = {
        ua.achievement_id: ua.earned_at
        for ua in db.query(UserAchievement).filter(UserAchievement.user_id == current_user.id).all()
    }

    result = []
    for ach in all_achievements:
        is_earned = ach.id in user_achievements
        result.append(
            AchievementOut(
                id=ach.id,
                title=ach.title,
                description=ach.description,
                icon=ach.icon,
                points_required=ach.points_required,
                badge_color=ach.badge_color,
                earned=is_earned,
                earned_at=user_achievements.get(ach.id),
            )
        )
    return result


@router.get("/available", response_model=List[RewardOut])
def list_available_rewards(db: Session = Depends(get_db)):
    rewards = db.query(Reward).filter(Reward.is_active == True).all()
    return rewards
