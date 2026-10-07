from sqlalchemy import Column, String, Integer, DateTime, JSON, Text, Boolean
from datetime import datetime
from app.models.database import Base

class Habit(Base):
    __tablename__ = "habits"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    name = Column(String(100), nullable=False) # e.g. "Drink water", "Morning walk", "Study", "Read"
    description = Column(Text, nullable=True)
    frequency = Column(String(20), default="Daily") # Daily, Weekly, Custom
    target = Column(Integer, default=1) # e.g. 8 glasses, 1 workout
    unit = Column(String(30), default="times") # "glasses", "minutes", "times", "pages"
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime, nullable=True)
    reminder_settings = Column(JSON, default=list) # e.g. ["08:00", "20:00"]
    category = Column(String(50), default="General") # Skincare, Fitness, Hydration, Mindfulness, Sleep, Study, General
    active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(String(64), primary_key=True, index=True)
    habit_id = Column(String(64), nullable=False, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    log_date = Column(String(10), nullable=False, index=True) # Normalized "YYYY-MM-DD"
    status = Column(String(20), default="Completed") # Completed, Skipped, Missed
    count = Column(Integer, default=1)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class SkincareProfile(Base):
    __tablename__ = "skincare_profiles"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, unique=True, index=True)
    skin_type = Column(String(50), nullable=True) # "Normal", "Dry", "Oily", "Combination", "Sensitive"
    skin_concerns = Column(JSON, default=list) # ["Acne", "Hyperpigmentation", "Dryness", "Dullness", "Aging", "Texture"]
    sensitivity_level = Column(String(50), default="Normal") # "Low", "Normal", "High"
    routine_frequency = Column(String(50), default="Twice daily") # "Once daily", "Twice daily"
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class RoutineProduct(Base):
    __tablename__ = "routine_products"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    product_name = Column(String(100), nullable=False)
    category = Column(String(50), default="Cleanser") # Cleanser, Moisturizer, Sunscreen, Serum, Toner, Treatment, Other
    brand = Column(String(100), nullable=True)
    active_ingredients = Column(JSON, default=list) # ["Hyaluronic Acid", "Niacinamide", "Salicylic Acid", "SPF 50"]
    routine_step = Column(Integer, default=1) # 1, 2, 3...
    time_of_day = Column(String(20), default="morning") # "morning", "evening", "both"
    frequency = Column(String(50), default="Daily") # "Daily", "Weekly", "2-3x per week"
    notes = Column(Text, nullable=True)
    enabled = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
