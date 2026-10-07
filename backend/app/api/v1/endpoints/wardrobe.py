import os
import uuid
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_

from app.models.database import get_db
from app.models.wardrobe import WardrobeItem
from app.schemas.wardrobe import (
    WardrobeItemCreate,
    WardrobeItemUpdate,
    WardrobeItemResponse,
    ClothingAnalysisResponse,
    ConfidenceBreakdown
)
from app.core.security import get_current_user_id
from app.services.clothing_ai_service import clothing_ai_service, TAXONOMY, COLOR_PALETTE
from app.services.vision_service import vision_service

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")

@router.get("/categories", response_model=Dict[str, Any])
async def get_wardrobe_categories():
    """
    Returns structured categories, subcategories, formality levels,
    patterns, and standard color palette for UI selection.
    """
    return {
        "categories": TAXONOMY,
        "formalities": ["Casual", "Smart Casual", "Formal", "Sport", "Business Casual", "Lounge"],
        "patterns": ["Solid", "Striped", "Checkered", "Floral", "Printed", "Textured"],
        "fits": ["Regular", "Slim", "Relaxed", "Oversized"],
        "seasons": ["Spring", "Summer", "Fall", "Winter", "All-Season"],
        "colors": list(COLOR_PALETTE.keys())
    }

@router.get("", response_model=List[WardrobeItemResponse])
async def list_wardrobe_items(
    category: Optional[str] = None,
    subcategory: Optional[str] = None,
    color: Optional[str] = None,
    formality: Optional[str] = None,
    pattern: Optional[str] = None,
    favorite: Optional[bool] = None,
    status_filter: Optional[str] = Query("available", alias="status"),
    search: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List wardrobe items belonging exclusively to the authenticated user.
    Enforces strict multi-tenant tenant isolation.
    """
    query = select(WardrobeItem).where(WardrobeItem.owner_id == user_id)
    
    if status_filter and status_filter.lower() != "all":
        query = query.where(WardrobeItem.status == status_filter)
        
    if category and category.lower() != "all":
        query = query.where(WardrobeItem.category == category)
        
    if subcategory:
        query = query.where(WardrobeItem.subcategory == subcategory)
        
    if formality:
        query = query.where(WardrobeItem.formality == formality)
        
    if pattern:
        query = query.where(WardrobeItem.pattern == pattern)
        
    if color:
        query = query.where(
            or_(
                WardrobeItem.primary_color == color,
                WardrobeItem.name.ilike(f"%{color}%")
            )
        )
        
    if favorite is not None:
        query = query.where(WardrobeItem.favorite == favorite)
        
    if search:
        search_pattern = f"%{search.strip()}%"
        query = query.where(
            or_(
                WardrobeItem.name.ilike(search_pattern),
                WardrobeItem.subcategory.ilike(search_pattern),
                WardrobeItem.category.ilike(search_pattern),
                WardrobeItem.brand.ilike(search_pattern),
                WardrobeItem.primary_color.ilike(search_pattern)
            )
        )
    
    result = await db.execute(query.order_by(WardrobeItem.created_at.desc()))
    return result.scalars().all()

@router.post("/analyze", response_model=ClothingAnalysisResponse)
async def analyze_clothing_photo(
    file: UploadFile = File(...),
    context_hint: Optional[str] = Form(None),
    user_size: Optional[str] = Form("M"),
    user_id: str = Depends(get_current_user_id)
):
    """
    Receives garment photo from camera or gallery.
    Performs real computer-vision image validation and fashion attribute extraction:
    - Dominant primary & secondary colors (pixel-level skin/background filtering)
    - Fabric pattern detection (gradient & spatial frequency)
    - Garment taxonomy classification (category, subcategory, formality, fit)
    - Generates 200x200 thumbnail and saves securely in user directory.
    """
    allowed_types = ["image/jpeg", "image/png", "image/webp", "image/jpg"]
    content_type = (file.content_type or "").lower()
    if content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format. Please upload a JPEG, PNG, or WebP photo."
        )

    image_bytes = await file.read()
    if len(image_bytes) > 15 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image file exceeds 15 MB limit. Please select a smaller photo."
        )

    result = clothing_ai_service.analyze_garment(
        image_bytes=image_bytes,
        user_id=user_id,
        uploads_dir=UPLOADS_DIR,
        context_hint=context_hint,
        user_size=user_size
    )

    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{result.get('error', 'Image analysis failed')}. {result.get('guidance', '')}".strip()
        )

    filename = result["image_filename"]
    thumb_filename = filename.replace(".jpg", "_thumb.jpg")
    
    # Store media asset URL endpoints
    image_url = f"/api/v1/wardrobe/media/{filename}"
    thumbnail_url = f"/api/v1/wardrobe/media/{thumb_filename}"

    return ClothingAnalysisResponse(
        success=True,
        name=result["name"],
        category=result["category"],
        subcategory=result["subcategory"],
        primary_color=result["primary_color"],
        secondary_colors=result["secondary_colors"],
        colors=result["colors"],
        pattern=result["pattern"],
        style_tags=result["style_tags"],
        formality=result["formality"],
        fit=result["fit"],
        size=result["size"],
        material=result.get("material"),
        occasion_tags=result["occasion_tags"],
        season_tags=result["season_tags"],
        seasons=result["seasons"],
        confidence=result["confidence"],
        confidence_breakdown=ConfidenceBreakdown(**result["confidence_breakdown"]),
        ai_model=result["ai_model"],
        ai_model_version=result["ai_model_version"],
        analysis_version=result["analysis_version"],
        ai_summary=result["ai_summary"],
        image_url=image_url,
        thumbnail_url=thumbnail_url,
        image_validation=result.get("image_validation")
    )

@router.post("/vision/prefill")
async def vision_prefill(labels: List[str] = Query(default=[]), color: str = Query(default="White")):
    return vision_service.extract_attributes_from_labels(labels, color)

@router.post("", response_model=WardrobeItemResponse)
async def create_wardrobe_item(
    data: WardrobeItemCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Creates a new digital wardrobe item.
    Enforces that owner_id is set to authenticated user_id.
    """
    item_id = data.id if data.id else str(uuid.uuid4())
    item_data = data.model_dump(exclude={"id"})
    
    # Ensure color arrays are consistent
    if item_data.get("primary_color") and not item_data.get("colors"):
        colors = [item_data["primary_color"]]
        if item_data.get("secondary_colors"):
            colors.extend([c for c in item_data["secondary_colors"] if c not in colors])
        item_data["colors"] = colors

    # Ensure season arrays are consistent
    if item_data.get("season_tags") and not item_data.get("seasons"):
        item_data["seasons"] = item_data["season_tags"]

    item = WardrobeItem(
        id=item_id,
        owner_id=user_id,
        **item_data
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item

@router.get("/media/{filename}")
async def get_wardrobe_media(
    filename: str,
    user_id: str = Depends(get_current_user_id)
):
    """
    Secure multi-tenant file stream for wardrobe images and thumbnails.
    Checks that the file resides in the authenticated user's uploads folder.
    """
    safe_filename = os.path.basename(filename)
    user_file_path = os.path.join(UPLOADS_DIR, "wardrobe", user_id, safe_filename)
    
    if not os.path.exists(user_file_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe media not found.")
        
    return FileResponse(user_file_path, media_type="image/jpeg")

@router.get("/{item_id}", response_model=WardrobeItemResponse)
async def get_wardrobe_item(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve single wardrobe item with multi-tenant authorization check.
    """
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id, WardrobeItem.owner_id == user_id)
    )
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found.")
    return item

@router.put("/{item_id}", response_model=WardrobeItemResponse)
async def update_wardrobe_item(
    item_id: str,
    data: WardrobeItemUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update an existing wardrobe item after user review or edits.
    """
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id, WardrobeItem.owner_id == user_id)
    )
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found.")
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(item, key, value)
        
    # Sync colors if primary_color changed
    if "primary_color" in update_data:
        p_col = update_data["primary_color"]
        sec_cols = item.secondary_colors or []
        item.colors = [p_col] + [c for c in sec_cols if c != p_col]

    item.sync_version = (item.sync_version or 1) + 1
    await db.commit()
    await db.refresh(item)
    return item

@router.post("/{item_id}/favorite", response_model=WardrobeItemResponse)
async def toggle_favorite_item(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggles the favorite state of a wardrobe item.
    """
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id, WardrobeItem.owner_id == user_id)
    )
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found.")
    
    item.favorite = not (item.favorite or False)
    item.sync_version = (item.sync_version or 1) + 1
    await db.commit()
    await db.refresh(item)
    return item

@router.delete("/{item_id}")
async def delete_wardrobe_item(
    item_id: str,
    permanent: bool = Query(False),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete or archive a wardrobe item with strict ownership verification.
    """
    result = await db.execute(
        select(WardrobeItem).where(WardrobeItem.id == item_id, WardrobeItem.owner_id == user_id)
    )
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Wardrobe item not found.")
        
    if permanent:
        await db.delete(item)
    else:
        item.status = "archived"
        item.sync_version = (item.sync_version or 1) + 1

    await db.commit()
    return {"status": "success", "message": "Item deleted successfully" if permanent else "Item archived successfully"}
