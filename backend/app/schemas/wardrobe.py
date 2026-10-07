from pydantic import BaseModel, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

class WardrobeItemBase(BaseModel):
    category: str
    subcategory: str
    name: str
    primary_color: Optional[str] = None
    secondary_colors: List[str] = []
    colors: List[str] = []
    pattern: Optional[str] = "Solid"
    style_tags: List[str] = []
    formality: str = "Casual"
    fit: str = "Regular"
    size: Optional[str] = None
    material: Optional[str] = None
    seasons: List[str] = ["Spring", "Summer", "Fall", "Winter"]
    season_tags: List[str] = []
    occasion_tags: List[str] = []
    brand: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    purchase_date: Optional[str] = None
    purchase_price: float = 0.0
    currency: str = "USD"
    notes: Optional[str] = None
    favorite: bool = False
    ai_analyzed: bool = False
    ai_confidence: Optional[float] = None
    ai_model: Optional[str] = None
    ai_model_version: Optional[str] = None
    analysis_version: Optional[str] = None
    user_confirmed: bool = True
    status: str = "available"

class WardrobeItemCreate(WardrobeItemBase):
    id: Optional[str] = None

class WardrobeItemUpdate(BaseModel):
    category: Optional[str] = None
    subcategory: Optional[str] = None
    name: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_colors: Optional[List[str]] = None
    colors: Optional[List[str]] = None
    pattern: Optional[str] = None
    style_tags: Optional[List[str]] = None
    formality: Optional[str] = None
    fit: Optional[str] = None
    size: Optional[str] = None
    material: Optional[str] = None
    seasons: Optional[List[str]] = None
    season_tags: Optional[List[str]] = None
    occasion_tags: Optional[List[str]] = None
    brand: Optional[str] = None
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    purchase_date: Optional[str] = None
    purchase_price: Optional[float] = None
    currency: Optional[str] = None
    notes: Optional[str] = None
    favorite: Optional[bool] = None
    ai_analyzed: Optional[bool] = None
    ai_confidence: Optional[float] = None
    user_confirmed: Optional[bool] = None
    status: Optional[str] = None
    wear_count: Optional[int] = None
    last_worn_date: Optional[datetime] = None

class WardrobeItemResponse(WardrobeItemBase):
    id: str
    owner_id: str
    wear_count: int
    last_worn_date: Optional[datetime] = None
    embedding_ref: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    sync_version: int
    
    model_config = ConfigDict(from_attributes=True)

class WardrobeFilter(BaseModel):
    category: Optional[str] = None
    subcategory: Optional[str] = None
    color: Optional[str] = None
    formality: Optional[str] = None
    pattern: Optional[str] = None
    favorite: Optional[bool] = None
    status: Optional[str] = "available"
    search_query: Optional[str] = None

class ConfidenceBreakdown(BaseModel):
    category: float
    color: float
    pattern: float
    overall: float

class ClothingAnalysisResponse(BaseModel):
    success: bool
    name: str
    category: str
    subcategory: str
    primary_color: str
    secondary_colors: List[str]
    colors: List[str]
    pattern: str
    style_tags: List[str]
    formality: str
    fit: str
    size: Optional[str] = None
    material: Optional[str] = None
    occasion_tags: List[str]
    season_tags: List[str]
    seasons: List[str]
    confidence: float
    confidence_breakdown: ConfidenceBreakdown
    ai_model: str
    ai_model_version: str
    analysis_version: str
    ai_summary: str
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    image_validation: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
