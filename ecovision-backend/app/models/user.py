from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), default="citizen", nullable=False)  # citizen / collector / authority / admin
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    scans = relationship("WasteScan", back_populates="user", cascade="all, delete-orphan")
    reports = relationship(
        "EnvironmentalReport",
        back_populates="user",
        foreign_keys="EnvironmentalReport.user_id",
        cascade="all, delete-orphan",
    )
    assigned_reports = relationship(
        "EnvironmentalReport",
        foreign_keys="EnvironmentalReport.assigned_to",
        back_populates="assignee",
    )
    point_transactions = relationship("PointTransaction", back_populates="user", cascade="all, delete-orphan")
    points = relationship("UserPoints", back_populates="user", uselist=False, cascade="all, delete-orphan")
    achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")
