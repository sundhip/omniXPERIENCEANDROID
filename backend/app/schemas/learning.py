from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

# --- Learning Items ---

class LearningItemBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    type: str = Field(default="subject", max_length=50) # subject, course, certification, skill, project_task, exam, assignment, milestone, topic
    category: str = Field(default="Academic", max_length=50) # Academic, Work, Skill, Personal, Research, Project
    status: str = Field(default="Not Started", max_length=20) # Not Started, In Progress, Completed, Paused, Cancelled
    priority: str = Field(default="Medium", max_length=20) # Low, Medium, High, Urgent
    progress: float = Field(default=0.0, ge=0.0, le=100.0)
    target_date: Optional[datetime] = None
    estimated_duration_minutes: int = Field(default=60, ge=0)
    parent_id: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    related_task_ids: List[str] = Field(default_factory=list)
    related_goal_id: Optional[str] = None

class LearningItemCreate(LearningItemBase):
    pass

class LearningItemUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    type: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    target_date: Optional[datetime] = None
    estimated_duration_minutes: Optional[int] = Field(default=None, ge=0)
    parent_id: Optional[str] = None
    tags: Optional[List[str]] = None
    related_task_ids: Optional[List[str]] = None
    related_goal_id: Optional[str] = None

class LearningItemResponse(LearningItemBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    children: List["LearningItemResponse"] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


# --- Goals & Milestones ---

class MilestoneItem(BaseModel):
    id: str
    title: str
    completed: bool = False
    target_date: Optional[str] = None
    order: int = 1

class GoalBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    category: str = Field(default="Personal", max_length=50) # Academic, Career, Financial, Fitness, Personal, Project, Learning
    priority: str = Field(default="Medium", max_length=20) # Low, Medium, High, Urgent
    status: str = Field(default="Active", max_length=20) # Active, Completed, Paused, Cancelled
    target_date: Optional[datetime] = None
    progress: float = Field(default=0.0, ge=0.0, le=100.0)
    milestones: List[Dict[str, Any]] = Field(default_factory=list)
    related_task_ids: List[str] = Field(default_factory=list)
    financial_target_amount: Optional[float] = None
    financial_saved_amount: Optional[float] = Field(default=0.0)

class GoalCreate(GoalBase):
    pass

class GoalUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    category: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    target_date: Optional[datetime] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    milestones: Optional[List[Dict[str, Any]]] = None
    related_task_ids: Optional[List[str]] = None
    financial_target_amount: Optional[float] = None
    financial_saved_amount: Optional[float] = None

class GoalResponse(GoalBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Study Sessions ---

class StudySessionBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    learning_item_id: Optional[str] = None
    goal_id: Optional[str] = None
    task_id: Optional[str] = None
    event_id: Optional[str] = None
    session_type: str = Field(default="Study", max_length=50) # Study, Coding, Project, Reading, Assignment, Research, Work, Skill
    planned_duration_minutes: int = Field(default=45, ge=5)
    actual_duration_minutes: int = Field(default=0, ge=0)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: str = Field(default="Scheduled", max_length=20) # Scheduled, In Progress, Completed, Interrupted, Cancelled
    notes: Optional[str] = None

class StudySessionCreate(StudySessionBase):
    pass

class StudySessionUpdate(BaseModel):
    title: Optional[str] = None
    session_type: Optional[str] = None
    planned_duration_minutes: Optional[int] = None
    actual_duration_minutes: Optional[int] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class StudySessionResponse(StudySessionBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Knowledge Notes ---

class KnowledgeNoteBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str
    tags: List[str] = Field(default_factory=list)
    linked_entity_type: str = Field(default="general", max_length=50) # learning_item, goal, project, task, general
    linked_entity_id: Optional[str] = None

class KnowledgeNoteCreate(KnowledgeNoteBase):
    pass

class KnowledgeNoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    linked_entity_type: Optional[str] = None
    linked_entity_id: Optional[str] = None

class KnowledgeNoteResponse(KnowledgeNoteBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- Personal Projects ---

class ProjectBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    category: str = Field(default="Development", max_length=50)
    status: str = Field(default="Active", max_length=20)
    priority: str = Field(default="Medium", max_length=20)
    target_date: Optional[datetime] = None
    progress: float = Field(default=0.0, ge=0.0, le=100.0)
    related_goal_id: Optional[str] = None
    related_task_ids: List[str] = Field(default_factory=list)

class ProjectCreate(ProjectBase):
    pass

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    target_date: Optional[datetime] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=100.0)
    related_goal_id: Optional[str] = None
    related_task_ids: Optional[List[str]] = None

class ProjectResponse(ProjectBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --- AI Planning & Intelligence Schemas ---

class MilestonePlanSuggestion(BaseModel):
    title: str
    target_date: str
    estimated_hours: float
    order: int

class GoalPlanResponse(BaseModel):
    goal_id: str
    goal_title: str
    feasible: bool
    total_estimated_hours: float
    weekly_hours_required: float
    deadline_status: str # "On Track", "Tight", "Unrealistic", "Passed"
    suggested_milestones: List[MilestonePlanSuggestion]
    recommended_next_action: str
    detected_conflicts: List[str]
    rationale: str

class LearningInsight(BaseModel):
    type: str # "approaching_deadline", "neglected_item", "workload_imbalance", "wellness_overload", "momentum"
    title: str
    description: str
    severity: str # "info", "warning", "critical"
    actionable_recommendation: str
    supporting_data: Dict[str, Any] = Field(default_factory=dict)

class PriorityScoreResponse(BaseModel):
    entity_id: str
    entity_type: str # "learning_item", "goal", "project"
    title: str
    priority_level: str # "Urgent", "High", "Medium", "Low"
    score: float # 0 to 100
    rationale: str

class LearnDashboardResponse(BaseModel):
    # Today section
    today_learning: List[LearningItemResponse]
    today_milestones: List[Dict[str, Any]]
    today_sessions: List[StudySessionResponse]
    upcoming_deadlines: List[Dict[str, Any]]
    # Progress section
    active_goals_count: int
    active_learning_count: int
    completed_milestones_count: int
    total_study_minutes_this_week: int
    # Attention Needed section
    overdue_items: List[Dict[str, Any]]
    at_risk_goals: List[Dict[str, Any]]
    insights: List[LearningInsight]
