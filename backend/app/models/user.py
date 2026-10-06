from sqlalchemy import Column, String, Boolean, Integer, Float, DateTime, JSON, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.models.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(64), primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    preferences = relationship("Preference", back_populates="user", uselist=False, cascade="all, delete-orphan")

class Profile(Base):
    __tablename__ = "profiles"
    
    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), ForeignKey("users.id"), unique=True, nullable=False)
    display_name = Column(String(100), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    age = Column(Integer, nullable=True)
    gender = Column(String(50), nullable=True)
    location = Column(String(100), nullable=True)
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    body_type = Column(String(50), nullable=True) # slim, athletic, average, broad, other
    onboarding_completed = Column(Boolean, default=False)
    timezone = Column(String(50), default="UTC")
    locale = Column(String(20), default="en-US")
    gender_preference = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    sync_version = Column(Integer, default=1)
    
    user = relationship("User", back_populates="profile")

class Preference(Base):
    __tablename__ = "preferences"
    
    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), ForeignKey("users.id"), unique=True, nullable=False)
    style_preferences = Column(JSON, default=list) # ["Minimal", "Classic", "Casual", etc.]
    fit_preference = Column(String(50), default="Regular") # Slim, Regular, Relaxed, Oversized, Mixed
    preferred_colors = Column(JSON, default=list)
    disliked_colors = Column(JSON, default=list)
    preferred_categories = Column(JSON, default=list)
    occasions = Column(JSON, default=list) # ["college", "office", "party", etc.]
    lifestyle = Column(JSON, default=list) # ["work", "gym", "travel", etc.]
    priorities = Column(JSON, default=dict) # {"comfort": 0.8, "appearance": 0.9, etc.}
    notification_preferences = Column(JSON, default=dict)
    ai_personalization_enabled = Column(Boolean, default=True)
    privacy_settings = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    sync_version = Column(Integer, default=1)
    
    user = relationship("User", back_populates="preferences")
