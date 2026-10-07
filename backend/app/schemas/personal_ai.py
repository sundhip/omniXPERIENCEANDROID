from typing import List, Dict, Any, Optional
from datetime import datetime
from enum import Enum
from pydantic import BaseModel, Field, ConfigDict


class EpistemicLevel(str, Enum):
    KNOWN = "KNOWN"              # Directly supported by user data
    CALCULATED = "CALCULATED"    # Derived mathematically or through deterministic logic
    RECOMMENDED = "RECOMMENDED"  # AI-generated suggestion
    UNCERTAIN = "UNCERTAIN"      # Inference with insufficient evidence


class ActionProposal(BaseModel):
    id: str
    action_type: str            # "create_task", "update_task", "create_event", "create_goal", "create_study_session"
    title: str
    description: str
    payload: Dict[str, Any] = Field(default_factory=dict)
    requires_confirmation: bool = True
    status: str = "pending"     # "pending", "confirmed", "rejected", "executed"
    created_at: Optional[datetime] = None


class ActionExecutionRequest(BaseModel):
    proposal_id: str
    confirm: bool = True
    modifications: Optional[Dict[str, Any]] = None


class ActionExecutionResponse(BaseModel):
    proposal_id: str
    success: bool
    status: str                 # "executed" or "rejected"
    result: Optional[Dict[str, Any]] = None
    message: str


class AssistantMessageRequest(BaseModel):
    prompt: str
    current_time: Optional[datetime] = None
    client_timezone: Optional[str] = "UTC"
    conversation_id: Optional[str] = None


class AssistantMessageResponse(BaseModel):
    id: str
    prompt: str
    response: str
    epistemic_level: EpistemicLevel = EpistemicLevel.RECOMMENDED
    referenced_domains: List[str] = Field(default_factory=list) # ["calendar", "tasks", "wardrobe", "weather", etc.]
    citations: List[str] = Field(default_factory=list)
    action_proposal: Optional[ActionProposal] = None
    suggested_followups: List[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DailyPersonalBrief(BaseModel):
    date: str                   # "YYYY-MM-DD"
    greeting: str               # "Good morning, Alex"
    user_name: str
    events_count: int = 0
    priority_tasks_count: int = 0
    approaching_deadlines_count: int = 0
    pending_habits_count: int = 0
    focus: str                  # "Complete DBMS module review before 5 PM"
    plan: str                   # "Study Machine Learning from 6:00 PM to 7:30 PM"
    prepare: str                # "Rain expected tomorrow afternoon; carry an umbrella and wear water-resistant shoes."
    wellness: str               # "Evening skincare routine completed 4/7 days this week."
    proactive_alerts: List[str] = Field(default_factory=list)


class ProactiveInsightResponse(BaseModel):
    id: str
    insight_type: str
    severity: str               # "info", "warning", "urgent"
    title: str
    explanation: str
    supporting_data: Dict[str, Any] = Field(default_factory=dict)
    recommended_action: Optional[str] = None
    action_proposal: Optional[ActionProposal] = None
    dismissed: bool = False
    created_at: datetime


class UserMemoryDTO(BaseModel):
    id: str
    key: str
    value: str
    domain: str
    source: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserMemoryCreate(BaseModel):
    key: str
    value: str
    domain: str = "general"


class PersonalContextSnapshot(BaseModel):
    user_id: str
    snapshot_time: datetime = Field(default_factory=datetime.utcnow)
    profile: Dict[str, Any] = Field(default_factory=dict)
    style_profile: Dict[str, Any] = Field(default_factory=dict)
    upcoming_events: List[Dict[str, Any]] = Field(default_factory=list)
    today_tasks: List[Dict[str, Any]] = Field(default_factory=list)
    overdue_tasks: List[Dict[str, Any]] = Field(default_factory=list)
    deadlines: List[Dict[str, Any]] = Field(default_factory=list)
    active_goals: List[Dict[str, Any]] = Field(default_factory=list)
    learning_workload: List[Dict[str, Any]] = Field(default_factory=list)
    project_workload: List[Dict[str, Any]] = Field(default_factory=list)
    budget_state: Dict[str, Any] = Field(default_factory=dict)
    recent_expenses: List[Dict[str, Any]] = Field(default_factory=list)
    wellness_state: Dict[str, Any] = Field(default_factory=dict)
    habits: List[Dict[str, Any]] = Field(default_factory=list)
    wardrobe_summary: Dict[str, Any] = Field(default_factory=dict)
    relevant_notes: List[Dict[str, Any]] = Field(default_factory=list)
    user_memories: List[Dict[str, Any]] = Field(default_factory=list)
    weather: Optional[Dict[str, Any]] = None


class FilteredContext(BaseModel):
    selected_domains: List[str]
    context_data: Dict[str, Any]
    epistemic_context: Dict[str, str] = Field(default_factory=dict)
