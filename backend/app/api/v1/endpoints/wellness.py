import uuid
from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.database import get_db
from app.models.wellness import Habit, HabitLog, SkincareProfile, RoutineProduct
from app.schemas.wellness import (
    SkincareProfileCreate, SkincareProfileUpdate, SkincareProfileResponse,
    RoutineProductCreate, RoutineProductUpdate, RoutineProductResponse,
    TodayWellnessResponse, WellnessInsight
)
from app.core.security import get_current_user_id
from app.services.wellness_service import wellness_service

router = APIRouter()

@router.get("/today", response_model=TodayWellnessResponse)
async def get_today_wellness(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get consolidated Today's Wellness dashboard: morning and evening skincare steps,
    today's habits, completion status, and truthful streak insights.
    """
    # Fetch active habits
    h_query = select(Habit).where(
        and_(Habit.user_id == current_user_id, Habit.active == True)
    )
    h_result = await db.execute(h_query)
    habits = h_result.scalars().all()

    # Fetch logs
    l_query = select(HabitLog).where(HabitLog.user_id == current_user_id)
    l_result = await db.execute(l_query)
    logs = l_result.scalars().all()

    # Fetch skincare profile
    p_query = select(SkincareProfile).where(SkincareProfile.user_id == current_user_id)
    p_result = await db.execute(p_query)
    skincare_profile = p_result.scalar_one_or_none()

    # Fetch routine products
    r_query = select(RoutineProduct).where(RoutineProduct.user_id == current_user_id)
    r_result = await db.execute(r_query)
    routine_products = r_result.scalars().all()

    return wellness_service.compile_today_wellness(
        habits=list(habits),
        logs=list(logs),
        skincare_profile=skincare_profile,
        routine_products=list(routine_products),
        reference_date=date.today()
    )

@router.get("/insights", response_model=List[WellnessInsight])
async def get_wellness_insights(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get deterministic wellness insights.
    """
    today_res = await get_today_wellness(current_user_id=current_user_id, db=db)
    return today_res.insights

# --- Skincare Profile ---

@router.get("/skincare-profile", response_model=Optional[SkincareProfileResponse])
async def get_skincare_profile(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get current user's skincare profile.
    """
    query = select(SkincareProfile).where(SkincareProfile.user_id == current_user_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()

@router.post("/skincare-profile", response_model=SkincareProfileResponse)
async def create_or_update_skincare_profile(
    profile_in: SkincareProfileCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create or update current user's skincare profile.
    """
    query = select(SkincareProfile).where(SkincareProfile.user_id == current_user_id)
    result = await db.execute(query)
    existing = result.scalar_one_or_none()

    now = datetime.utcnow()
    if existing:
        existing.skin_type = profile_in.skin_type
        existing.skin_concerns = profile_in.skin_concerns
        existing.sensitivity_level = profile_in.sensitivity_level
        existing.routine_frequency = profile_in.routine_frequency
        existing.notes = profile_in.notes
        existing.updated_at = now
        await db.commit()
        await db.refresh(existing)
        return existing

    new_profile = SkincareProfile(
        id=f"skp_{uuid.uuid4().hex[:16]}",
        user_id=current_user_id,
        skin_type=profile_in.skin_type,
        skin_concerns=profile_in.skin_concerns,
        sensitivity_level=profile_in.sensitivity_level,
        routine_frequency=profile_in.routine_frequency,
        notes=profile_in.notes,
        created_at=now,
        updated_at=now
    )
    db.add(new_profile)
    await db.commit()
    await db.refresh(new_profile)
    return new_profile

# --- Routine Products / Steps ---

@router.get("/routines", response_model=List[RoutineProductResponse])
async def list_routine_products(
    time_of_day: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List routine products/steps for the user.
    """
    query = select(RoutineProduct).where(RoutineProduct.user_id == current_user_id)
    if time_of_day:
        query = query.where(RoutineProduct.time_of_day == time_of_day)
    query = query.order_by(RoutineProduct.routine_step.asc())
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/routines", response_model=RoutineProductResponse, status_code=status.HTTP_201_CREATED)
async def create_routine_product(
    product_in: RoutineProductCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Add a skincare or self-care routine product step.
    """
    now = datetime.utcnow()
    new_product = RoutineProduct(
        id=f"rtn_{uuid.uuid4().hex[:16]}",
        user_id=current_user_id,
        product_name=product_in.product_name,
        category=product_in.category,
        brand=product_in.brand,
        active_ingredients=product_in.active_ingredients,
        routine_step=product_in.routine_step,
        time_of_day=product_in.time_of_day,
        frequency=product_in.frequency,
        notes=product_in.notes,
        enabled=product_in.enabled,
        created_at=now,
        updated_at=now
    )
    db.add(new_product)
    await db.commit()
    await db.refresh(new_product)
    return new_product

@router.get("/routines/{product_id}", response_model=RoutineProductResponse)
async def get_routine_product(
    product_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get routine product with multi-tenant isolation.
    """
    query = select(RoutineProduct).where(
        and_(RoutineProduct.id == product_id, RoutineProduct.user_id == current_user_id)
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Routine step not found"
        )
    return product

@router.put("/routines/{product_id}", response_model=RoutineProductResponse)
async def update_routine_product(
    product_id: str,
    product_in: RoutineProductUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update routine step with multi-tenant isolation.
    """
    query = select(RoutineProduct).where(
        and_(RoutineProduct.id == product_id, RoutineProduct.user_id == current_user_id)
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Routine step not found"
        )

    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)

    product.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(product)
    return product

@router.delete("/routines/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_routine_product(
    product_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete routine step with multi-tenant isolation.
    """
    query = select(RoutineProduct).where(
        and_(RoutineProduct.id == product_id, RoutineProduct.user_id == current_user_id)
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Routine step not found"
        )

    await db.delete(product)
    await db.commit()
    return None

@router.post("/routines/{product_id}/toggle", response_model=RoutineProductResponse)
async def toggle_routine_product(
    product_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggle enabled state of routine product.
    """
    query = select(RoutineProduct).where(
        and_(RoutineProduct.id == product_id, RoutineProduct.user_id == current_user_id)
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Routine step not found"
        )

    product.enabled = not product.enabled
    product.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(product)
    return product
