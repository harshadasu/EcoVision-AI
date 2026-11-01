from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class WasteScan(Base):
    __tablename__ = "waste_scans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_path = Column(String(500), nullable=False)
    predicted_class = Column(String(100), nullable=False)
    confidence = Column(Float, nullable=False)
    confirmed_class = Column(String(100), nullable=True)
    category = Column(String(100), nullable=False)
    recyclable = Column(Boolean, default=False, nullable=False)
    disposal_guidance = Column(Text, nullable=False)
    model_version = Column(String(50), default="1.0.0", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="scans")


class WasteCategory(Base):
    __tablename__ = "waste_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    description = Column(Text, nullable=False)
    disposal_guidance = Column(Text, nullable=False)
    recyclable = Column(Boolean, default=False, nullable=False)
    color_code = Column(String(20), default="#4CAF50", nullable=False)
    icon_name = Column(String(50), default="recycle", nullable=False)
    bin_type = Column(String(100), default="General Waste", nullable=False)
