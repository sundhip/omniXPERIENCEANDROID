from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

class HabitBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    frequency: str = Field(default="Daily") # Daily, Weekly, Custom
    target: int = Field(default=1, ge=1)
    unit: str = Field(default="times", max_length=30)
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    reminder_settings: List[str] = Field(default_factory=list) # e.g. ["08:00"]
    category: str = Field(default="General", max_length=50)
    active: bool = True

class HabitCreate(HabitBase):
    pass

class HabitUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    frequency: Optional[str] = None
    target: Optional[int] = Field(default=None, ge=1)
    unit: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    reminder_settings: Optional[List[str]] = None
    category: Optional[str] = None
    active: Optional[bool] = None

class HabitResponse(HabitBase):
    id: str
    user_id: str
    current_streak: int = 0
    longest_streak: int = 0
    completion_rate: float = 0.0 # 0.0 - 100.0
    completed_today: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class HabitLogCreate(BaseModel):
    log_date: str = Field(..., pattern=r"^\d{4}-\d{2}-\d{2}$") # YYYY-MM-DD
    status: str = Field(default="Completed") # Completed, Skipped, Missed
    count: int = Field(default=1, ge=0)
    notes: Optional[str] = None

class HabitLogResponse(BaseModel):
    id: str
    habit_id: str
    user_id: str
    log_date: str
    status: str
    count: int
    notes: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class SkincareProfileBase(BaseModel):
    skin_type: Optional[str] = Field(default=None, max_length=50) # Normal, Dry, Oily, Combination, Sensitive
    skin_concerns: List[str] = Field(default_factory=list)
    sensitivity_level: str = Field(default="Normal", max_length=50)
    routine_frequency: str = Field(default="Twice daily", max_length=50)
    notes: Optional[str] = None

class SkincareProfileCreate(SkincareProfileBase):
    pass

class SkincareProfileUpdate(SkincareProfileBase):
    pass

class SkincareProfileResponse(SkincareProfileBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class RoutineProductBase(BaseModel):
    product_name: str = Field(..., min_length=1, max_length=100)
    category: str = Field(default="Cleanser", max_length=50)
    brand: Optional[str] = Field(default=None, max_length=100)
    active_ingredients: List[str] = Field(default_factory=list)
    routine_step: int = Field(default=1, ge=1)
    time_of_day: str = Field(default="morning", max_length=20) # morning, evening, both
    frequency: str = Field(default="Daily", max_length=50)
    notes: Optional[str] = None
    enabled: bool = True

class RoutineProductCreate(RoutineProductBase):
    pass

class RoutineProductUpdate(BaseModel):
    product_name: Optional[str] = None
    category: Optional[str] = None
    brand: Optional[str] = None
    active_ingredients: Optional[List[str]] = None
    routine_step: Optional[int] = None
    time_of_day: Optional[str] = None
    frequency: Optional[str] = None
    notes: Optional[str] = None
    enabled: Optional[bool] = None

class RoutineProductResponse(RoutineProductBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class WellnessInsight(BaseModel):
    type: str # 'habit_streak' | 'routine_consistency' | 'missed_alert' | 'info'
    title: str
    description: str
    severity: str # 'info' | 'positive' | 'warning'
    supporting_data: Dict[str, Any] = Field(default_factory=dict)

class RoutineStepToday(BaseModel):
    id: str
    product_name: str
    category: str
    routine_step: int
    time_of_day: str
    completed: bool = False

class TodayWellnessResponse(BaseModel):
    date: str
    morning_routine: List[RoutineStepToday] = Field(default_factory=list)
    evening_routine: List[RoutineStepToday] = Field(default_factory=list)
    habits: List[HabitResponse] = Field(default_factory=list)
    total_habits_count: int = 0
    completed_habits_count: int = 0
    insights: List[WellnessInsight] = Field(default_factory=list)
