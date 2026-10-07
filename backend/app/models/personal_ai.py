from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, Text, Boolean, ForeignKey
from datetime import datetime
from app.models.database import Base

class UserMemory(Base):
    __tablename__ = "user_memories"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    key = Column(String(100), nullable=False, index=True)
    value = Column(Text, nullable=False)
    domain = Column(String(50), default="general", index=True) # wardrobe, productivity, learning, wellness, finance, general
    source = Column(String(50), default="user_confirmed") # user_confirmed, explicit_setting
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class ProactiveInsight(Base):
    __tablename__ = "proactive_insights"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    dedup_hash = Column(String(64), nullable=False, index=True) # MD5/SHA256 of type+entity_id+date
    insight_type = Column(String(50), nullable=False, index=True) # deadline_approaching, schedule_conflict, overloaded_day, neglected_goal, high_spending, missed_habit, weather_alert
    severity = Column(String(20), default="info") # info, warning, urgent
    title = Column(String(200), nullable=False)
    explanation = Column(Text, nullable=False)
    supporting_data = Column(JSON, default=dict)
    recommended_action = Column(String(255), nullable=True)
    dismissed = Column(Boolean, default=False)
    cooldown_until = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)


class ActionProposalRecord(Base):
    __tablename__ = "action_proposals"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    action_type = Column(String(50), nullable=False) # create_task, update_task, create_event, create_goal, create_study_session
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    payload = Column(JSON, default=dict) # arguments for tool execution
    requires_confirmation = Column(Boolean, default=True)
    status = Column(String(20), default="pending", index=True) # pending, confirmed, rejected, executed
    executed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
