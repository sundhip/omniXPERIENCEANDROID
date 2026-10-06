from pydantic import BaseModel, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

class ProfileBase(BaseModel):
    display_name: str
    avatar_url: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    body_type: Optional[str] = None # slim, athletic, average, broad, prefer_not_to_say
    onboarding_completed: bool = False
    timezone: str = "UTC"
    locale: str = "en-US"
    gender_preference: Optional[str] = None

class ProfileCreate(ProfileBase):
    pass

class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    body_type: Optional[str] = None
    onboarding_completed: Optional[bool] = None
    timezone: Optional[str] = None
    locale: Optional[str] = None
    gender_preference: Optional[str] = None

class ProfileResponse(ProfileBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    sync_version: int
    
    model_config = ConfigDict(from_attributes=True)

class PreferenceBase(BaseModel):
    style_preferences: List[str] = ["Casual", "Minimal"]
    fit_preference: str = "Regular"
    preferred_colors: List[str] = []
    disliked_colors: List[str] = []
    preferred_categories: List[str] = []
    occasions: List[str] = []
    lifestyle: List[str] = []
    priorities: Dict[str, float] = {}
    notification_preferences: Dict[str, Any] = {}
    ai_personalization_enabled: bool = True
    privacy_settings: Dict[str, Any] = {}

class PreferenceCreate(PreferenceBase):
    pass

class PreferenceUpdate(BaseModel):
    style_preferences: Optional[List[str]] = None
    fit_preference: Optional[str] = None
    preferred_colors: Optional[List[str]] = None
    disliked_colors: Optional[List[str]] = None
    preferred_categories: Optional[List[str]] = None
    occasions: Optional[List[str]] = None
    lifestyle: Optional[List[str]] = None
    priorities: Optional[Dict[str, float]] = None
    notification_preferences: Optional[Dict[str, Any]] = None
    ai_personalization_enabled: Optional[bool] = None
    privacy_settings: Optional[Dict[str, Any]] = None

class PreferenceResponse(PreferenceBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    sync_version: int
    
    model_config = ConfigDict(from_attributes=True)

class FullProfileResponse(BaseModel):
    id: str
    user_id: str
    display_name: str
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    body_type: Optional[str] = None
    onboarding_completed: bool = False
    
    # Preferences
    style_preferences: List[str] = []
    fit_preference: str = "Regular"
    preferred_colors: List[str] = []
    disliked_colors: List[str] = []
    occasions: List[str] = []
    lifestyle: List[str] = []
    priorities: Dict[str, float] = {}
    ai_personalization_enabled: bool = True
    
    created_at: datetime
    updated_at: datetime
    sync_version: int

    model_config = ConfigDict(from_attributes=True)

class FullProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    body_type: Optional[str] = None
    onboarding_completed: Optional[bool] = None
    
    # Preferences
    style_preferences: Optional[List[str]] = None
    fit_preference: Optional[str] = None
    preferred_colors: Optional[List[str]] = None
    disliked_colors: Optional[List[str]] = None
    occasions: Optional[List[str]] = None
    lifestyle: Optional[List[str]] = None
    priorities: Optional[Dict[str, float]] = None
    ai_personalization_enabled: Optional[bool] = None
