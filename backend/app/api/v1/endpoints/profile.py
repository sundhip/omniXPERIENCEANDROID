from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid
from app.models.database import get_db
from app.models.user import User, Profile, Preference, VisualProfile
from app.schemas.profile import (
    ProfileUpdate, ProfileResponse, 
    PreferenceUpdate, PreferenceResponse,
    FullProfileResponse, FullProfileUpdate
)
from app.core.security import get_current_user_id

router = APIRouter()

from app.services.personalization_service import PersonalizationService

@router.get("/full", response_model=FullProfileResponse)
async def get_full_profile(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalars().first()
    email = user.email if user else None

    prof_res = await db.execute(select(Profile).where(Profile.user_id == user_id))
    profile = prof_res.scalars().first()
    if not profile:
        profile = Profile(id=str(uuid.uuid4()), user_id=user_id, display_name="OmniPresence User")
        db.add(profile)
        await db.commit()
        await db.refresh(profile)

    pref_res = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = pref_res.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)

    # Ensure personal_style_profile is populated deterministically
    style_profile = pref.personal_style_profile or {}
    if not style_profile:
        style_profile = PersonalizationService.build_personal_style_profile(
            primary_style=pref.primary_style,
            secondary_styles=pref.secondary_styles,
            style_preferences=pref.style_preferences,
            primary_fit=pref.primary_fit,
            secondary_fit=pref.secondary_fit,
            fit_preference=pref.fit_preference,
            preferred_colors=pref.preferred_colors,
            neutral_colors=pref.neutral_colors,
            disliked_colors=pref.disliked_colors,
            colors_to_experiment=pref.colors_to_experiment,
            color_experimentation_score=pref.color_experimentation_score or 0.5,
            occasions=pref.occasions,
            top_occasions=pref.top_occasions,
            occasion_frequencies=pref.occasion_frequencies,
            lifestyle=pref.lifestyle,
            comfort_appearance_score=pref.comfort_appearance_score or 0.5,
            experimentation_score=pref.experimentation_score or 0.5,
            fashion_priorities_ranked=pref.fashion_priorities_ranked,
            priorities=pref.priorities,
            preferred_brands=pref.preferred_brands,
            avoided_brands=pref.avoided_brands,
            budget_tier=pref.budget_tier,
            version=pref.personalization_version or 1,
        )
        pref.personal_style_profile = style_profile
        pref.fashion_priority_weights = style_profile.get("fashion_priority_weights", {})
        await db.commit()
        await db.refresh(pref)

    vp_res = await db.execute(select(VisualProfile).where(VisualProfile.user_id == user_id))
    vp = vp_res.scalars().first()
    vp_data = None
    if vp:
        vp_data = {
            "id": vp.id,
            "source_image_id": vp.source_image_id,
            "face_detected": vp.face_detected,
            "detected_face_shape": vp.detected_face_shape,
            "confirmed_face_shape": vp.confirmed_face_shape,
            "face_shape_confidence": vp.face_shape_confidence,
            "detected_skin_tone": vp.detected_skin_tone,
            "confirmed_skin_tone": vp.confirmed_skin_tone,
            "skin_tone_confidence": vp.skin_tone_confidence,
            "detected_skin_undertone": vp.detected_skin_undertone,
            "confirmed_skin_undertone": vp.confirmed_skin_undertone,
            "detected_hair_length": vp.detected_hair_length,
            "confirmed_hair_length": vp.confirmed_hair_length,
            "detected_hair_texture": vp.detected_hair_texture,
            "confirmed_hair_texture": vp.confirmed_hair_texture,
            "hair_confidence": vp.hair_confidence,
            "confirmed_by_user": vp.confirmed_by_user,
            "analysis_date": vp.created_at.isoformat() if vp.created_at else None
        }

    return FullProfileResponse(
        id=profile.id,
        user_id=user_id,
        display_name=profile.display_name,
        email=email,
        avatar_url=profile.avatar_url,
        age=profile.age,
        gender=profile.gender,
        location=profile.location,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        body_type=profile.body_type,
        onboarding_completed=profile.onboarding_completed,
        style_preferences=pref.style_preferences or [],
        primary_style=pref.primary_style,
        secondary_styles=pref.secondary_styles or [],
        fit_preference=pref.fit_preference or "Regular",
        primary_fit=pref.primary_fit or "Regular",
        secondary_fit=pref.secondary_fit,
        preferred_colors=pref.preferred_colors or [],
        disliked_colors=pref.disliked_colors or [],
        neutral_colors=pref.neutral_colors or [],
        colors_to_experiment=pref.colors_to_experiment or [],
        color_experimentation_score=pref.color_experimentation_score or 0.5,
        experimentation_score=pref.experimentation_score or 0.5,
        comfort_appearance_score=pref.comfort_appearance_score or 0.5,
        occasions=pref.occasions or [],
        top_occasions=pref.top_occasions or [],
        occasion_frequencies=pref.occasion_frequencies or {},
        lifestyle=pref.lifestyle or [],
        priorities=pref.priorities or {},
        fashion_priorities_ranked=pref.fashion_priorities_ranked or [],
        fashion_priority_weights=pref.fashion_priority_weights or {},
        preferred_brands=pref.preferred_brands or [],
        avoided_brands=pref.avoided_brands or [],
        budget_tier=pref.budget_tier,
        personal_style_profile=style_profile,
        personalization_version=pref.personalization_version or 1,
        ai_personalization_enabled=pref.ai_personalization_enabled,
        visual_profile=vp_data,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
        sync_version=profile.sync_version,
    )

@router.put("/full", response_model=FullProfileResponse)
@router.patch("/full", response_model=FullProfileResponse)
async def update_full_profile(data: FullProfileUpdate, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    user_res = await db.execute(select(User).where(User.id == user_id))
    user = user_res.scalars().first()
    email = user.email if user else None

    prof_res = await db.execute(select(Profile).where(Profile.user_id == user_id))
    profile = prof_res.scalars().first()
    if not profile:
        profile = Profile(id=str(uuid.uuid4()), user_id=user_id, display_name="OmniPresence User")
        db.add(profile)

    pref_res = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = pref_res.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id)
        db.add(pref)

    profile_fields = {"display_name", "avatar_url", "age", "gender", "location", "height_cm", "weight_kg", "body_type", "onboarding_completed"}
    pref_fields = {
        "style_preferences", "primary_style", "secondary_styles", "fit_preference",
        "primary_fit", "secondary_fit", "preferred_colors", "disliked_colors",
        "neutral_colors", "colors_to_experiment", "color_experimentation_score",
        "experimentation_score", "comfort_appearance_score", "occasions",
        "top_occasions", "occasion_frequencies", "lifestyle", "priorities",
        "fashion_priorities_ranked", "fashion_priority_weights", "preferred_brands",
        "avoided_brands", "budget_tier", "personal_style_profile", "personalization_version",
        "ai_personalization_enabled"
    }

    data_dict = data.model_dump(exclude_unset=True)
    for k, v in data_dict.items():
        if k in profile_fields:
            setattr(profile, k, v)
        elif k in pref_fields:
            setattr(pref, k, v)

    # Re-calculate deterministic personal_style_profile
    style_profile = PersonalizationService.build_personal_style_profile(
        primary_style=pref.primary_style,
        secondary_styles=pref.secondary_styles,
        style_preferences=pref.style_preferences,
        primary_fit=pref.primary_fit,
        secondary_fit=pref.secondary_fit,
        fit_preference=pref.fit_preference,
        preferred_colors=pref.preferred_colors,
        neutral_colors=pref.neutral_colors,
        disliked_colors=pref.disliked_colors,
        colors_to_experiment=pref.colors_to_experiment,
        color_experimentation_score=pref.color_experimentation_score or 0.5,
        occasions=pref.occasions,
        top_occasions=pref.top_occasions,
        occasion_frequencies=pref.occasion_frequencies,
        lifestyle=pref.lifestyle,
        comfort_appearance_score=pref.comfort_appearance_score or 0.5,
        experimentation_score=pref.experimentation_score or 0.5,
        fashion_priorities_ranked=pref.fashion_priorities_ranked,
        priorities=pref.priorities,
        preferred_brands=pref.preferred_brands,
        avoided_brands=pref.avoided_brands,
        budget_tier=pref.budget_tier,
        version=pref.personalization_version or 1,
    )
    pref.personal_style_profile = style_profile
    pref.fashion_priority_weights = style_profile.get("fashion_priority_weights", {})

    profile.sync_version += 1
    pref.sync_version += 1
    await db.commit()
    await db.refresh(profile)
    await db.refresh(pref)

    vp_res = await db.execute(select(VisualProfile).where(VisualProfile.user_id == user_id))
    vp = vp_res.scalars().first()
    vp_data = None
    if vp:
        vp_data = {
            "id": vp.id,
            "source_image_id": vp.source_image_id,
            "face_detected": vp.face_detected,
            "detected_face_shape": vp.detected_face_shape,
            "confirmed_face_shape": vp.confirmed_face_shape,
            "face_shape_confidence": vp.face_shape_confidence,
            "detected_skin_tone": vp.detected_skin_tone,
            "confirmed_skin_tone": vp.confirmed_skin_tone,
            "skin_tone_confidence": vp.skin_tone_confidence,
            "detected_skin_undertone": vp.detected_skin_undertone,
            "confirmed_skin_undertone": vp.confirmed_skin_undertone,
            "detected_hair_length": vp.detected_hair_length,
            "confirmed_hair_length": vp.confirmed_hair_length,
            "detected_hair_texture": vp.detected_hair_texture,
            "confirmed_hair_texture": vp.confirmed_hair_texture,
            "hair_confidence": vp.hair_confidence,
            "confirmed_by_user": vp.confirmed_by_user,
            "analysis_date": vp.created_at.isoformat() if vp.created_at else None
        }

    return FullProfileResponse(
        id=profile.id,
        user_id=user_id,
        display_name=profile.display_name,
        email=email,
        avatar_url=profile.avatar_url,
        age=profile.age,
        gender=profile.gender,
        location=profile.location,
        height_cm=profile.height_cm,
        weight_kg=profile.weight_kg,
        body_type=profile.body_type,
        onboarding_completed=profile.onboarding_completed,
        style_preferences=pref.style_preferences or [],
        primary_style=pref.primary_style,
        secondary_styles=pref.secondary_styles or [],
        fit_preference=pref.fit_preference or "Regular",
        primary_fit=pref.primary_fit or "Regular",
        secondary_fit=pref.secondary_fit,
        preferred_colors=pref.preferred_colors or [],
        disliked_colors=pref.disliked_colors or [],
        neutral_colors=pref.neutral_colors or [],
        colors_to_experiment=pref.colors_to_experiment or [],
        color_experimentation_score=pref.color_experimentation_score or 0.5,
        experimentation_score=pref.experimentation_score or 0.5,
        comfort_appearance_score=pref.comfort_appearance_score or 0.5,
        occasions=pref.occasions or [],
        top_occasions=pref.top_occasions or [],
        occasion_frequencies=pref.occasion_frequencies or {},
        lifestyle=pref.lifestyle or [],
        priorities=pref.priorities or {},
        fashion_priorities_ranked=pref.fashion_priorities_ranked or [],
        fashion_priority_weights=pref.fashion_priority_weights or {},
        preferred_brands=pref.preferred_brands or [],
        avoided_brands=pref.avoided_brands or [],
        budget_tier=pref.budget_tier,
        personal_style_profile=style_profile,
        personalization_version=pref.personalization_version or 1,
        ai_personalization_enabled=pref.ai_personalization_enabled,
        visual_profile=vp_data,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
        sync_version=profile.sync_version,
    )

@router.get("", response_model=ProfileResponse)
async def get_profile(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Profile).where(Profile.user_id == user_id))
    profile = result.scalars().first()
    if not profile:
        profile = Profile(id=str(uuid.uuid4()), user_id=user_id, display_name="OmniPresence User")
        db.add(profile)
        await db.commit()
        await db.refresh(profile)
    return profile

@router.put("", response_model=ProfileResponse)
async def update_profile(data: ProfileUpdate, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Profile).where(Profile.user_id == user_id))
    profile = result.scalars().first()
    if not profile:
        profile = Profile(id=str(uuid.uuid4()), user_id=user_id, display_name="OmniPresence User", sync_version=1)
        db.add(profile)
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(profile, key, value)
    profile.sync_version = (profile.sync_version or 0) + 1
    await db.commit()
    await db.refresh(profile)
    return profile

@router.get("/preferences", response_model=PreferenceResponse)
async def get_preferences(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id, sync_version=1)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)
    return pref

@router.put("/preferences", response_model=PreferenceResponse)
async def update_preferences(data: PreferenceUpdate, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id, sync_version=1)
        db.add(pref)
        
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(pref, key, value)
    pref.sync_version = (pref.sync_version or 0) + 1
    await db.commit()
    await db.refresh(pref)
    return pref

@router.get("/notifications")
async def get_notification_preferences(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    defaults = {
        "deadlines": True,
        "budget": True,
        "habits": True,
        "conflicts": True,
        "weather": True,
    }
    if not pref or not pref.notification_preferences:
        return defaults
    merged = dict(defaults)
    merged.update(pref.notification_preferences)
    return merged

@router.put("/notifications")
async def update_notification_preferences(
    prefs: dict[str, bool],
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id, sync_version=1)
        db.add(pref)

    merged = {
        "deadlines": True,
        "budget": True,
        "habits": True,
        "conflicts": True,
        "weather": True,
    }
    if pref.notification_preferences:
        merged.update(pref.notification_preferences)
    merged.update(prefs)
    pref.notification_preferences = merged
    pref.sync_version = (pref.sync_version or 0) + 1
    await db.commit()
    await db.refresh(pref)
    return pref.notification_preferences


