from typing import List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.models.rewards import (
    UserPoints,
    PointTransaction,
    Achievement,
    UserAchievement,
    Reward,
)
from app.models.user import User


def get_user_points(db: Session, user_id: int) -> UserPoints:
    points_record = db.query(UserPoints).filter(UserPoints.user_id == user_id).first()
    if not points_record:
        points_record = UserPoints(user_id=user_id, balance=0, total_earned=0)
        db.add(points_record)
        db.commit()
        db.refresh(points_record)
    return points_record


def check_achievements(db: Session, user_id: int) -> List[UserAchievement]:
    points_record = get_user_points(db, user_id)
    total_points = points_record.total_earned

    # Fetch all achievements achievable with user's total points
    eligible_achievements = (
        db.query(Achievement)
        .filter(Achievement.points_required <= total_points)
        .all()
    )

    existing_ids = {
        ua.achievement_id
        for ua in db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
    }

    new_earned = []
    for ach in eligible_achievements:
        if ach.id not in existing_ids:
            ua = UserAchievement(user_id=user_id, achievement_id=ach.id)
            db.add(ua)
            new_earned.append(ua)

    if new_earned:
        db.commit()

    return new_earned


def award_points(
    db: Session,
    user_id: int,
    points: int,
    reason: str,
    action_type: str,
) -> UserPoints:
    points_record = get_user_points(db, user_id)
    points_record.balance += points
    if points > 0:
        points_record.total_earned += points

    tx = PointTransaction(
        user_id=user_id,
        points=points,
        reason=reason,
        action_type=action_type,
    )
    db.add(tx)
    db.commit()
    db.refresh(points_record)

    # Check for unlocked achievements
    check_achievements(db, user_id)

    return points_record


def get_transactions(
    db: Session,
    user_id: int,
    limit: int = 50,
) -> List[PointTransaction]:
    return (
        db.query(PointTransaction)
        .filter(PointTransaction.user_id == user_id)
        .order_by(desc(PointTransaction.created_at))
        .limit(limit)
        .all()
    )


def get_leaderboard(db: Session, limit: int = 10) -> List[Dict[str, Any]]:
    results = (
        db.query(UserPoints, User)
        .join(User, User.id == UserPoints.user_id)
        .filter(User.is_active == True)
        .order_by(desc(UserPoints.total_earned))
        .limit(limit)
        .all()
    )

    leaderboard = []
    for rank, (points_rec, user) in enumerate(results, start=1):
        leaderboard.append({
            "rank": rank,
            "user_id": user.id,
            "name": user.name,
            "points": points_rec.total_earned,
        })
    return leaderboard


def seed_achievements(db: Session) -> None:
    default_achievements = [
        {
            "title": "First Eco Step",
            "description": "Complete your first scan and identify waste properly.",
            "icon": "footprints",
            "points_required": 10,
            "badge_color": "#4CAF50",
        },
        {
            "title": "Waste Classifier",
            "description": "Earn 50 points by classifying waste items correctly.",
            "icon": "recycle",
            "points_required": 50,
            "badge_color": "#2196F3",
        },
        {
            "title": "Green Sentinel",
            "description": "Reach 100 points and actively participate in civic cleanliness.",
            "icon": "shield-check",
            "points_required": 100,
            "badge_color": "#FF9800",
        },
        {
            "title": "Eco Champion",
            "description": "Earn 250 points and become a neighborhood eco-advocate.",
            "icon": "award",
            "points_required": 250,
            "badge_color": "#9C27B0",
        },
        {
            "title": "Planet Hero",
            "description": "Earn 500 total points and stand at the forefront of sustainability.",
            "icon": "globe",
            "points_required": 500,
            "badge_color": "#E91E63",
        },
    ]

    for item in default_achievements:
        existing = db.query(Achievement).filter(Achievement.title == item["title"]).first()
        if not existing:
            ach = Achievement(
                title=item["title"],
                description=item["description"],
                icon=item["icon"],
                points_required=item["points_required"],
                badge_color=item["badge_color"],
            )
            db.add(ach)

    # Also seed sample rewards if table empty
    default_rewards = [
        {
            "title": "Plant a Tree in Your Name",
            "description": "We partner with local NGOs to plant and nurture a native sapling.",
            "points_cost": 200,
            "category": "Environmental Impact",
            "is_active": True,
        },
        {
            "title": "Eco-Friendly Bamboo Toothbrush Kit",
            "description": "100% biodegradable bamboo toothbrush set delivered to your doorstep.",
            "points_cost": 150,
            "category": "Sustainable Goods",
            "is_active": True,
        },
        {
            "title": "Municipal Recycling Champion Certificate",
            "description": "Official digital certificate signed by the city environmental authority.",
            "points_cost": 80,
            "category": "Digital Badge",
            "is_active": True,
        },
        {
            "title": "Public Transit 20% Discount Pass",
            "description": "Valid on municipal electric bus routes across the metropolitan region.",
            "points_cost": 300,
            "category": "Transit Voucher",
            "is_active": True,
        },
    ]

    for r_item in default_rewards:
        existing_reward = db.query(Reward).filter(Reward.title == r_item["title"]).first()
        if not existing_reward:
            rew = Reward(
                title=r_item["title"],
                description=r_item["description"],
                points_cost=r_item["points_cost"],
                category=r_item["category"],
                is_active=r_item["is_active"],
            )
            db.add(rew)

    db.commit()
