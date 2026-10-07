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
    visual_profile = relationship("VisualProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")

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
    primary_style = Column(String(50), nullable=True)
    secondary_styles = Column(JSON, default=list)
    fit_preference = Column(String(50), default="Regular") # Slim, Regular, Relaxed, Oversized, Mixed
    primary_fit = Column(String(50), default="Regular")
    secondary_fit = Column(String(50), nullable=True)
    preferred_colors = Column(JSON, default=list)
    disliked_colors = Column(JSON, default=list)
    neutral_colors = Column(JSON, default=list)
    colors_to_experiment = Column(JSON, default=list)
    color_experimentation_score = Column(Float, default=0.5)
    experimentation_score = Column(Float, default=0.5)
    comfort_appearance_score = Column(Float, default=0.5)
    preferred_categories = Column(JSON, default=list)
    occasions = Column(JSON, default=list) # ["college", "office", "party", etc.]
    top_occasions = Column(JSON, default=list)
    occasion_frequencies = Column(JSON, default=dict) # {"formal": 0.33, "casual": 1.0, ...}
    lifestyle = Column(JSON, default=list) # ["work", "gym", "travel", etc.]
    priorities = Column(JSON, default=dict) # {"comfort": 0.8, "appearance": 0.9, etc.}
    fashion_priorities_ranked = Column(JSON, default=list)
    fashion_priority_weights = Column(JSON, default=dict)
    preferred_brands = Column(JSON, default=list)
    avoided_brands = Column(JSON, default=list)
    budget_tier = Column(String(50), nullable=True)
    personal_style_profile = Column(JSON, default=dict)
    personalization_version = Column(Integer, default=1)
    notification_preferences = Column(JSON, default=dict)
    ai_personalization_enabled = Column(Boolean, default=True)
    privacy_settings = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    sync_version = Column(Integer, default=1)
    
    user = relationship("User", back_populates="preferences")
 
class VisualProfile(Base):
    __tablename__ = "visual_profiles"
    
    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), ForeignKey("users.id"), unique=True, nullable=False)
    source_image_id = Column(String(128), nullable=True) # Safe private image filename / UUID
    face_detected = Column(Boolean, default=False)
    face_count = Column(Integer, default=0)
    
    # Face shape
    detected_face_shape = Column(String(50), nullable=True) # Oval, Round, Square, Oblong, Heart, Diamond, Triangle, Unknown
    confirmed_face_shape = Column(String(50), nullable=True)
    face_shape_confidence = Column(Float, nullable=True)
    
    # Skin tone
    detected_skin_tone = Column(String(50), nullable=True) # Very Light, Light, Medium, Tan, Deep, Unknown
    confirmed_skin_tone = Column(String(50), nullable=True)
    skin_tone_confidence = Column(Float, nullable=True)
    
    # Skin undertone
    detected_skin_undertone = Column(String(50), nullable=True) # Warm, Cool, Neutral, Unknown
    confirmed_skin_undertone = Column(String(50), nullable=True)
    skin_undertone_confidence = Column(Float, nullable=True)
    
    # Hair attributes
    hair_visible = Column(Boolean, default=True)
    detected_hair_length = Column(String(50), nullable=True) # Short, Medium, Long, Bald/Buzz, Unknown
    confirmed_hair_length = Column(String(50), nullable=True)
    detected_hair_texture = Column(String(50), nullable=True) # Straight, Wavy, Curly, Coily, Unknown
    confirmed_hair_texture = Column(String(50), nullable=True)
    hair_confidence = Column(Float, nullable=True)
    
    # Image Quality metrics
    image_quality = Column(JSON, default=dict)
    quality_score = Column(Float, nullable=True)
    
    # User Confirmation flag
    confirmed_by_user = Column(Boolean, default=False)
    
    # Provenance and Model Metadata
    analysis_method = Column(String(50), default="mediapipe_geometry")
    model_name = Column(String(100), default="MediaPipe Face Landmarker")
    model_version = Column(String(50), default="1.1.0")
    analysis_version = Column(String(50), default="1.0.0")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="visual_profile")
