from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class PriorityLevel(str, Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"
    URGENT = "Urgent"

class EventStatus(str, Enum):
    SCHEDULED = "scheduled"
    ONGOING = "ongoing"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class TaskStatus(str, Enum):
    TODO = "Todo"
    IN_PROGRESS = "In Progress"
    COMPLETED = "Completed"
    CANCELLED = "Cancelled"

class ProductivityCategory(str, Enum):
    COLLEGE = "College"
    WORK = "Work"
    PERSONAL = "Personal"
    HEALTH = "Health"
    FITNESS = "Fitness"
    FINANCE = "Finance"
    ERRANDS = "Errands"
    PROJECTS = "Projects"
    OTHER = "Other"

# --- EVENT SCHEMAS ---

class EventBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    all_day: bool = False
    location: Optional[str] = None
    category: str = "Personal"
    priority: str = "Medium"
    status: str = "scheduled"
    color: Optional[str] = None
    notes: Optional[str] = None
    recurrence: Optional[Dict[str, Any]] = None
    reminder_settings: List[int] = Field(default_factory=list) # Minutes before: e.g. [15, 60, 1440]
    related_task_ids: List[str] = Field(default_factory=list)
    related_goal_id: Optional[str] = None
    occasion: Optional[str] = None # For wardrobe intelligence integration
    source_type: Optional[str] = None # College course, exam, etc.
    source_id: Optional[str] = None

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    all_day: Optional[bool] = None
    location: Optional[str] = None
    category: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    color: Optional[str] = None
    notes: Optional[str] = None
    recurrence: Optional[Dict[str, Any]] = None
    reminder_settings: Optional[List[int]] = None
    related_task_ids: Optional[List[str]] = None
    related_goal_id: Optional[str] = None
    occasion: Optional[str] = None
    source_type: Optional[str] = None
    source_id: Optional[str] = None

class EventResponse(EventBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- TASK SCHEMAS ---

class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    status: str = "Todo"
    priority: str = "Medium"
    due_date: Optional[datetime] = None
    due_time: Optional[str] = None
    estimated_duration_minutes: int = 30
    category: str = "Personal"
    tags: List[str] = Field(default_factory=list)
    event_id: Optional[str] = None
    parent_task_id: Optional[str] = None
    dependency_task_ids: List[str] = Field(default_factory=list)
    recurrence: Optional[Dict[str, Any]] = None
    notes: Optional[str] = None
    reminder_settings: List[int] = Field(default_factory=list)
    source_type: Optional[str] = None
    source_id: Optional[str] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None
    due_time: Optional[str] = None
    estimated_duration_minutes: Optional[int] = None
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    event_id: Optional[str] = None
    parent_task_id: Optional[str] = None
    dependency_task_ids: Optional[List[str]] = None
    recurrence: Optional[Dict[str, Any]] = None
    notes: Optional[str] = None
    reminder_settings: Optional[List[int]] = None
    completed_at: Optional[datetime] = None
    source_type: Optional[str] = None
    source_id: Optional[str] = None

class TaskResponse(TaskBase):
    id: str
    user_id: str
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- INTELLIGENCE SCHEMAS ---

class ScheduleConflict(BaseModel):
    event_a_id: str
    event_a_title: str
    event_b_id: str
    event_b_title: str
    overlap_start: datetime
    overlap_end: datetime
    message: str

class TimeBlock(BaseModel):
    start_time: datetime
    end_time: datetime
    duration_minutes: int
    is_free: bool

class TaskSlotSuggestion(BaseModel):
    task_id: str
    task_title: str
    suggested_start: datetime
    suggested_end: datetime
    duration_minutes: int
    reason: str

class PriorityAssessment(BaseModel):
    task_id: str
    title: str
    explicit_priority: str
    calculated_priority: str
    urgency_score: float # 0.0 to 1.0
    is_blocked: bool
    blocking_task_ids: List[str]
    explanation: str

class TodayProductivityResponse(BaseModel):
    date: str # YYYY-MM-DD
    total_events: int
    total_tasks: int
    completed_tasks: int
    overdue_tasks: List[TaskResponse]
    upcoming_deadlines: List[TaskResponse]
    events: List[EventResponse]
    tasks: List[TaskResponse]
    conflicts: List[ScheduleConflict]
    free_blocks: List[TimeBlock]
    suggested_slots: List[TaskSlotSuggestion]
    summary_message: str
