from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, Text, Boolean
from datetime import datetime
from app.models.database import Base

class Event(Base):
    __tablename__ = "events"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime, nullable=False, index=True)
    end_time = Column(DateTime, nullable=False, index=True)
    all_day = Column(Boolean, default=False)
    location = Column(String(255), nullable=True)
    category = Column(String(50), default="Personal", index=True) # College, Work, Personal, Health, Fitness, Finance, Errands, Projects, Other
    priority = Column(String(20), default="Medium") # Low, Medium, High, Urgent
    status = Column(String(20), default="scheduled", index=True) # scheduled, ongoing, completed, cancelled
    color = Column(String(20), nullable=True)
    notes = Column(Text, nullable=True)
    recurrence = Column(JSON, nullable=True) # {"frequency": "daily|weekly|monthly", "interval": 1, "until": "..."}
    reminder_settings = Column(JSON, default=list) # [15, 30, 60] minutes before
    related_task_ids = Column(JSON, default=list)
    related_goal_id = Column(String(64), nullable=True)
    occasion = Column(String(100), nullable=True) # For future Wardrobe AI integration: e.g. "Presentation", "Lecture", "Workout"
    source_type = Column(String(50), nullable=True) # Extensibility for college/academics: "course", "assignment", "exam"
    source_id = Column(String(64), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Task(Base):
    __tablename__ = "tasks"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String(20), default="Todo", index=True) # Todo, In Progress, Completed, Cancelled
    priority = Column(String(20), default="Medium", index=True) # Low, Medium, High, Urgent
    due_date = Column(DateTime, nullable=True, index=True)
    due_time = Column(String(10), nullable=True) # "14:30"
    estimated_duration_minutes = Column(Integer, default=30)
    category = Column(String(50), default="Personal", index=True) # College, Work, Personal, Health, Fitness, Finance, Errands, Projects, Other
    tags = Column(JSON, default=list)
    event_id = Column(String(64), nullable=True)
    parent_task_id = Column(String(64), nullable=True)
    dependency_task_ids = Column(JSON, default=list) # [task_id_1, task_id_2]
    recurrence = Column(JSON, nullable=True)
    notes = Column(Text, nullable=True)
    reminder_settings = Column(JSON, default=list)
    completed_at = Column(DateTime, nullable=True)
    source_type = Column(String(50), nullable=True) # Extensibility for college/academics
    source_id = Column(String(64), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
