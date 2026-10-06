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
    primary_style: Optional[str] = "Casual"
    secondary_styles: List[str] = []
    fit_preference: str = "Regular"
    primary_fit: str = "Regular"
    secondary_fit: Optional[str] = None
    preferred_colors: List[str] = []
    disliked_colors: List[str] = []
    neutral_colors: List[str] = []
    colors_to_experiment: List[str] = []
    color_experimentation_score: float = 0.5
    experimentation_score: float = 0.5
    comfort_appearance_score: float = 0.5
    preferred_categories: List[str] = []
    occasions: List[str] = []
    top_occasions: List[str] = []
    occasion_frequencies: Dict[str, float] = {}
    lifestyle: List[str] = []
    priorities: Dict[str, float] = {}
    fashion_priorities_ranked: List[str] = []
    fashion_priority_weights: Dict[str, float] = {}
    preferred_brands: List[str] = []
    avoided_brands: List[str] = []
    budget_tier: Optional[str] = "Mid-range"
    personal_style_profile: Dict[str, Any] = {}
    personalization_version: int = 1
    notification_preferences: Dict[str, Any] = {}
    ai_personalization_enabled: bool = True
    privacy_settings: Dict[str, Any] = {}

class PreferenceCreate(PreferenceBase):
    pass

class PreferenceUpdate(BaseModel):
    style_preferences: Optional[List[str]] = None
    primary_style: Optional[str] = None
    secondary_styles: Optional[List[str]] = None
    fit_preference: Optional[str] = None
    primary_fit: Optional[str] = None
    secondary_fit: Optional[str] = None
    preferred_colors: Optional[List[str]] = None
    disliked_colors: Optional[List[str]] = None
    neutral_colors: Optional[List[str]] = None
    colors_to_experiment: Optional[List[str]] = None
    color_experimentation_score: Optional[float] = None
    experimentation_score: Optional[float] = None
    comfort_appearance_score: Optional[float] = None
    preferred_categories: Optional[List[str]] = None
    occasions: Optional[List[str]] = None
    top_occasions: Optional[List[str]] = None
    occasion_frequencies: Optional[Dict[str, float]] = None
    lifestyle: Optional[List[str]] = None
    priorities: Optional[Dict[str, float]] = None
    fashion_priorities_ranked: Optional[List[str]] = None
    fashion_priority_weights: Optional[Dict[str, float]] = None
    preferred_brands: Optional[List[str]] = None
    avoided_brands: Optional[List[str]] = None
    budget_tier: Optional[str] = None
    personal_style_profile: Optional[Dict[str, Any]] = None
    personalization_version: Optional[int] = None
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
    
    # Preferences & Personalization
    style_preferences: List[str] = []
    primary_style: Optional[str] = None
    secondary_styles: List[str] = []
    fit_preference: str = "Regular"
    primary_fit: str = "Regular"
    secondary_fit: Optional[str] = None
    preferred_colors: List[str] = []
    disliked_colors: List[str] = []
    neutral_colors: List[str] = []
    colors_to_experiment: List[str] = []
    color_experimentation_score: float = 0.5
    experimentation_score: float = 0.5
    comfort_appearance_score: float = 0.5
    occasions: List[str] = []
    top_occasions: List[str] = []
    occasion_frequencies: Dict[str, float] = {}
    lifestyle: List[str] = []
    priorities: Dict[str, float] = {}
    fashion_priorities_ranked: List[str] = []
    fashion_priority_weights: Dict[str, float] = {}
    preferred_brands: List[str] = []
    avoided_brands: List[str] = []
    budget_tier: Optional[str] = None
    personal_style_profile: Dict[str, Any] = {}
    personalization_version: int = 1
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
    
    # Preferences & Personalization
    style_preferences: Optional[List[str]] = None
    primary_style: Optional[str] = None
    secondary_styles: Optional[List[str]] = None
    fit_preference: Optional[str] = None
    primary_fit: Optional[str] = None
    secondary_fit: Optional[str] = None
    preferred_colors: Optional[List[str]] = None
    disliked_colors: Optional[List[str]] = None
    neutral_colors: Optional[List[str]] = None
    colors_to_experiment: Optional[List[str]] = None
    color_experimentation_score: Optional[float] = None
    experimentation_score: Optional[float] = None
    comfort_appearance_score: Optional[float] = None
    occasions: Optional[List[str]] = None
    top_occasions: Optional[List[str]] = None
    occasion_frequencies: Optional[Dict[str, float]] = None
    lifestyle: Optional[List[str]] = None
    priorities: Optional[Dict[str, float]] = None
    fashion_priorities_ranked: Optional[List[str]] = None
    fashion_priority_weights: Optional[Dict[str, float]] = None
    preferred_brands: Optional[List[str]] = None
    avoided_brands: Optional[List[str]] = None
    budget_tier: Optional[str] = None
    personal_style_profile: Optional[Dict[str, Any]] = None
    personalization_version: Optional[int] = None
    ai_personalization_enabled: Optional[bool] = None
