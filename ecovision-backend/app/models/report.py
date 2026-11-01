from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class EnvironmentalReport(Base):
    __tablename__ = "environmental_reports"

    id = Column(Integer, primary_key=True, index=True)
    client_uuid = Column(String(100), unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    image_path = Column(String(500), nullable=True)
    area = Column(String(200), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    status = Column(
        String(50),
        default="Submitted",
        nullable=False,
    )  # Submitted / Under Review / Assigned / Resolved / Rejected
    assigned_to = Column(Integer, ForeignKey("users.id"), nullable=True)
    resolution_note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    user = relationship("User", foreign_keys=[user_id], back_populates="reports")
    assignee = relationship("User", foreign_keys=[assigned_to], back_populates="assigned_reports")
