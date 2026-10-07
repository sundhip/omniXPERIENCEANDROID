import os
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.user import User, VisualProfile
from app.schemas.visual_profile import (
    VisualProfileResponse,
    VisualProfileConfirmRequest,
    VisualProfileAnalysisResult,
    VisualContextResponse
)
from app.core.security import get_current_user_id
from app.services.face_analysis_service import face_analysis_service

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
UPLOADS_DIR = os.path.join(BASE_DIR, "uploads")

@router.post("/analyze", response_model=VisualProfileAnalysisResult)
async def analyze_visual_profile_photo(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Uploads a photo for real computer-vision face and appearance analysis.
    Validates quality, single-face presence, extracts geometric features,
    and returns detected attributes with confidence scores.
    """
    # 1. Validate content type
    allowed_types = ["image/jpeg", "image/png", "image/webp", "image/jpg"]
    content_type = file.content_type.lower() if file.content_type else ""
    if content_type not in allowed_types:
        return VisualProfileAnalysisResult(
            success=False,
            error="Invalid image format. Please upload a JPEG, PNG, or WebP photo.",
            user_action="Select Another Photo"
        )

    # 2. Read bytes with size protection (max 10MB)
    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        return VisualProfileAnalysisResult(
            success=False,
            error="Image size exceeds 10 MB limit. Please select a smaller photo.",
            user_action="Select Another Photo"
        )

    # 3. Execute real Computer Vision Analysis
    result = face_analysis_service.analyze_photo(image_bytes, user_id, UPLOADS_DIR)
    if not result.get("success"):
        return VisualProfileAnalysisResult(
            success=False,
            error=result.get("error", "Analysis failed."),
            user_action=result.get("user_action", "Try Another Photo"),
            quality_metrics=result.get("quality_metrics")
        )

    # 4. Check for existing visual profile and clean up any old private image
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    existing_res = await db.execute(stmt)
    existing_profile = existing_res.scalars().first()

    if existing_profile and existing_profile.source_image_id:
        # Delete prior image file to prevent orphaned private images
        face_analysis_service.delete_analysis_image(user_id, existing_profile.source_image_id, UPLOADS_DIR)

    # 5. Persist analysis results into SQLite
    if not existing_profile:
        existing_profile = VisualProfile(
            id=result["id"],
            user_id=user_id
        )
        db.add(existing_profile)

    existing_profile.source_image_id = result["source_image_id"]
    existing_profile.face_detected = result["face_detected"]
    existing_profile.face_count = result["face_count"]
    
    # Detected & initial confirmed values
    existing_profile.detected_face_shape = result["detected_face_shape"]
    existing_profile.confirmed_face_shape = result["detected_face_shape"]
    existing_profile.face_shape_confidence = result["face_shape_confidence"]
    
    existing_profile.detected_skin_tone = result["detected_skin_tone"]
    existing_profile.confirmed_skin_tone = result["detected_skin_tone"]
    existing_profile.skin_tone_confidence = result["skin_tone_confidence"]
    
    existing_profile.detected_skin_undertone = result["detected_skin_undertone"]
    existing_profile.confirmed_skin_undertone = result["detected_skin_undertone"]
    existing_profile.skin_undertone_confidence = result["skin_undertone_confidence"]
    
    existing_profile.hair_visible = result["hair_visible"]
    existing_profile.detected_hair_length = result["detected_hair_length"]
    existing_profile.confirmed_hair_length = result["detected_hair_length"]
    existing_profile.detected_hair_texture = result["detected_hair_texture"]
    existing_profile.confirmed_hair_texture = result["detected_hair_texture"]
    existing_profile.hair_confidence = result["hair_confidence"]
    
    existing_profile.image_quality = result["image_quality"]
    existing_profile.quality_score = result["quality_score"]
    
    existing_profile.confirmed_by_user = False
    existing_profile.analysis_method = result["analysis_method"]
    existing_profile.model_name = result["model_name"]
    existing_profile.model_version = result["model_version"]
    existing_profile.analysis_version = result["analysis_version"]
    existing_profile.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(existing_profile)

    return VisualProfileAnalysisResult(
        success=True,
        visual_profile=VisualProfileResponse.model_validate(existing_profile),
        quality_metrics=result["image_quality"]
    )

@router.get("", response_model=VisualProfileResponse)
async def get_visual_profile(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Fetches the current authenticated user's Visual Profile."""
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    res = await db.execute(stmt)
    vp = res.scalars().first()
    if not vp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Visual profile not found. Please upload a photo to analyze your visual profile."
        )
    return VisualProfileResponse.model_validate(vp)

@router.put("/confirm", response_model=VisualProfileResponse)
async def confirm_visual_profile(
    data: VisualProfileConfirmRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Allows the user to review, edit, and confirm their visual appearance attributes.
    Future AI recommendations prioritize the confirmed values.
    """
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    res = await db.execute(stmt)
    vp = res.scalars().first()
    if not vp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No visual profile found to confirm."
        )

    if data.confirmed_face_shape is not None:
        vp.confirmed_face_shape = data.confirmed_face_shape
    if data.confirmed_skin_tone is not None:
        vp.confirmed_skin_tone = data.confirmed_skin_tone
    if data.confirmed_skin_undertone is not None:
        vp.confirmed_skin_undertone = data.confirmed_skin_undertone
    if data.confirmed_hair_length is not None:
        vp.confirmed_hair_length = data.confirmed_hair_length
    if data.confirmed_hair_texture is not None:
        vp.confirmed_hair_texture = data.confirmed_hair_texture

    vp.confirmed_by_user = True
    vp.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(vp)
    return VisualProfileResponse.model_validate(vp)

@router.delete("")
async def delete_visual_profile(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Deletes the visual profile and deletes the source image file from private storage.
    Ensures zero orphaned private images.
    """
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    res = await db.execute(stmt)
    vp = res.scalars().first()
    if not vp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Visual profile not found.")

    if vp.source_image_id:
        face_analysis_service.delete_analysis_image(user_id, vp.source_image_id, UPLOADS_DIR)

    await db.delete(vp)
    await db.commit()
    return {"message": "Visual profile and associated photo deleted successfully."}

@router.get("/image")
async def get_visual_profile_image(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Streams the private source selfie for the authenticated user only.
    Multi-tenant isolation: Users cannot access another user's image.
    Never exposes internal disk paths to clients.
    """
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    res = await db.execute(stmt)
    vp = res.scalars().first()
    if not vp or not vp.source_image_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No profile image available.")

    safe_filename = os.path.basename(vp.source_image_id)
    image_path = os.path.join(UPLOADS_DIR, "visual_profiles", user_id, safe_filename)

    if not os.path.exists(image_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Image file not found.")

    return FileResponse(image_path, media_type="image/jpeg")

@router.get("/context", response_model=VisualContextResponse)
async def get_visual_context_for_ai(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Exposes clean interface for future AI Orchestrator / Context Engine
    (Wardrobe AI, Outfit Recommendations, Self-Care, Grooming).
    Prioritizes confirmed attributes over detected ones.
    """
    stmt = select(VisualProfile).where(VisualProfile.user_id == user_id)
    res = await db.execute(stmt)
    vp = res.scalars().first()
    if not vp:
        return VisualContextResponse(
            user_id=user_id,
            is_active=False
        )

    return VisualContextResponse(
        user_id=user_id,
        face_shape=vp.confirmed_face_shape or vp.detected_face_shape,
        skin_tone=vp.confirmed_skin_tone or vp.detected_skin_tone,
        skin_undertone=vp.confirmed_skin_undertone or vp.detected_skin_undertone,
        hair_length=vp.confirmed_hair_length or vp.detected_hair_length,
        hair_texture=vp.confirmed_hair_texture or vp.detected_hair_texture,
        confirmed_by_user=vp.confirmed_by_user,
        is_active=True,
        analysis_date=vp.created_at
    )
