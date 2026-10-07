from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, Text, Boolean, ForeignKey
from datetime import datetime
from app.models.database import Base

class LearningItem(Base):
    __tablename__ = "learning_items"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    # Type: "course", "subject", "certification", "skill", "project_task", "exam", "assignment", "milestone", "topic"
    type = Column(String(50), default="subject", index=True)
    # Category: "Academic", "Work", "Skill", "Personal", "Research", "Project"
    category = Column(String(50), default="Academic", index=True)
    # Status: "Not Started", "In Progress", "Completed", "Paused", "Cancelled"
    status = Column(String(20), default="Not Started", index=True)
    # Priority: "Low", "Medium", "High", "Urgent"
    priority = Column(String(20), default="Medium", index=True)
    progress = Column(Float, default=0.0) # 0.0 to 100.0
    target_date = Column(DateTime, nullable=True, index=True)
    estimated_duration_minutes = Column(Integer, default=60)
    parent_id = Column(String(64), nullable=True, index=True) # Hierarchical structure: Subject -> Module -> Topic
    tags = Column(JSON, default=list)
    related_task_ids = Column(JSON, default=list)
    related_goal_id = Column(String(64), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Goal(Base):
    __tablename__ = "goals"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    # Category: "Academic", "Career", "Financial", "Fitness", "Personal", "Project", "Learning"
    category = Column(String(50), default="Personal", index=True)
    # Priority: "Low", "Medium", "High", "Urgent"
    priority = Column(String(20), default="Medium", index=True)
    # Status: "Active", "Completed", "Paused", "Cancelled"
    status = Column(String(20), default="Active", index=True)
    target_date = Column(DateTime, nullable=True, index=True)
    progress = Column(Float, default=0.0) # 0.0 to 100.0
    # Milestones list: [{"id": "...", "title": "...", "completed": False, "target_date": "...", "order": 1}]
    milestones = Column(JSON, default=list)
    related_task_ids = Column(JSON, default=list)
    # Phase 6 Money cross-module connection:
    financial_target_amount = Column(Float, nullable=True)
    financial_saved_amount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    learning_item_id = Column(String(64), nullable=True, index=True)
    goal_id = Column(String(64), nullable=True, index=True)
    task_id = Column(String(64), nullable=True, index=True)
    event_id = Column(String(64), nullable=True, index=True)
    # session_type: "Study", "Coding", "Project", "Reading", "Assignment", "Research", "Work", "Skill"
    session_type = Column(String(50), default="Study", index=True)
    planned_duration_minutes = Column(Integer, default=45)
    actual_duration_minutes = Column(Integer, default=0)
    start_time = Column(DateTime, nullable=True)
    end_time = Column(DateTime, nullable=True)
    # status: "Scheduled", "In Progress", "Completed", "Interrupted", "Cancelled"
    status = Column(String(20), default="Scheduled", index=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class KnowledgeNote(Base):
    __tablename__ = "knowledge_notes"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    tags = Column(JSON, default=list)
    # linked_entity_type: "learning_item", "goal", "project", "task", "general"
    linked_entity_type = Column(String(50), default="general", index=True)
    linked_entity_id = Column(String(64), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Project(Base):
    __tablename__ = "personal_projects"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    # category: "Development", "Research", "Startup", "Content", "Freelance", "Personal"
    category = Column(String(50), default="Development", index=True)
    # status: "Active", "Completed", "Paused", "Cancelled"
    status = Column(String(20), default="Active", index=True)
    priority = Column(String(20), default="Medium", index=True)
    target_date = Column(DateTime, nullable=True, index=True)
    progress = Column(Float, default=0.0) # 0.0 to 100.0
    related_goal_id = Column(String(64), nullable=True, index=True)
    related_task_ids = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
