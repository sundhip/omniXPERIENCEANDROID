from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid
from app.models.database import get_db
from app.models.user import User, Profile, Preference
from app.schemas.profile import (
    ProfileUpdate, ProfileResponse, 
    PreferenceUpdate, PreferenceResponse,
    FullProfileResponse, FullProfileUpdate
)
from app.core.security import get_current_user_id

router = APIRouter()

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
        fit_preference=pref.fit_preference or "Regular",
        preferred_colors=pref.preferred_colors or [],
        disliked_colors=pref.disliked_colors or [],
        occasions=pref.occasions or [],
        lifestyle=pref.lifestyle or [],
        priorities=pref.priorities or {},
        ai_personalization_enabled=pref.ai_personalization_enabled,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
        sync_version=profile.sync_version,
    )

@router.put("/full", response_model=FullProfileResponse)
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
    pref_fields = {"style_preferences", "fit_preference", "preferred_colors", "disliked_colors", "occasions", "lifestyle", "priorities", "ai_personalization_enabled"}

    data_dict = data.model_dump(exclude_unset=True)
    for k, v in data_dict.items():
        if k in profile_fields:
            setattr(profile, k, v)
        elif k in pref_fields:
            setattr(pref, k, v)

    profile.sync_version += 1
    pref.sync_version += 1
    await db.commit()
    await db.refresh(profile)
    await db.refresh(pref)

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
        fit_preference=pref.fit_preference or "Regular",
        preferred_colors=pref.preferred_colors or [],
        disliked_colors=pref.disliked_colors or [],
        occasions=pref.occasions or [],
        lifestyle=pref.lifestyle or [],
        priorities=pref.priorities or {},
        ai_personalization_enabled=pref.ai_personalization_enabled,
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
        profile = Profile(id=str(uuid.uuid4()), user_id=user_id, display_name="OmniPresence User")
        db.add(profile)
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(profile, key, value)
    profile.sync_version += 1
    await db.commit()
    await db.refresh(profile)
    return profile

@router.get("/preferences", response_model=PreferenceResponse)
async def get_preferences(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)
    return pref

@router.put("/preferences", response_model=PreferenceResponse)
async def update_preferences(data: PreferenceUpdate, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Preference).where(Preference.user_id == user_id))
    pref = result.scalars().first()
    if not pref:
        pref = Preference(id=str(uuid.uuid4()), user_id=user_id)
        db.add(pref)
        
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(pref, key, value)
    pref.sync_version += 1
    await db.commit()
    await db.refresh(pref)
    return pref
