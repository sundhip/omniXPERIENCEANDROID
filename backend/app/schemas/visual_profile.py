from pydantic import BaseModel, ConfigDict
from typing import Optional, Dict, Any, List
from datetime import datetime

class VisualProfileBase(BaseModel):
    detected_face_shape: Optional[str] = None
    confirmed_face_shape: Optional[str] = None
    face_shape_confidence: Optional[float] = None
    
    detected_skin_tone: Optional[str] = None
    confirmed_skin_tone: Optional[str] = None
    skin_tone_confidence: Optional[float] = None
    
    detected_skin_undertone: Optional[str] = None
    confirmed_skin_undertone: Optional[str] = None
    skin_undertone_confidence: Optional[float] = None
    
    hair_visible: bool = True
    detected_hair_length: Optional[str] = None
    confirmed_hair_length: Optional[str] = None
    detected_hair_texture: Optional[str] = None
    confirmed_hair_texture: Optional[str] = None
    hair_confidence: Optional[float] = None
    
    confirmed_by_user: bool = False

class VisualProfileConfirmRequest(BaseModel):
    confirmed_face_shape: Optional[str] = None
    confirmed_skin_tone: Optional[str] = None
    confirmed_skin_undertone: Optional[str] = None
    confirmed_hair_length: Optional[str] = None
    confirmed_hair_texture: Optional[str] = None

class VisualProfileResponse(VisualProfileBase):
    id: str
    user_id: str
    source_image_id: Optional[str] = None
    face_detected: bool = False
    face_count: int = 0
    image_quality: Dict[str, Any] = {}
    quality_score: Optional[float] = None
    analysis_method: str = "mediapipe_geometry"
    model_name: str = "MediaPipe Face Landmarker"
    model_version: str = "1.1.0"
    analysis_version: str = "1.0.0"
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class VisualProfileAnalysisResult(BaseModel):
    success: bool
    visual_profile: Optional[VisualProfileResponse] = None
    error: Optional[str] = None
    user_action: Optional[str] = None
    quality_metrics: Optional[Dict[str, Any]] = None

class VisualContextResponse(BaseModel):
    user_id: str
    face_shape: Optional[str] = None
    skin_tone: Optional[str] = None
    skin_undertone: Optional[str] = None
    hair_length: Optional[str] = None
    hair_texture: Optional[str] = None
    confirmed_by_user: bool = False
    is_active: bool = False
    analysis_date: Optional[datetime] = None
