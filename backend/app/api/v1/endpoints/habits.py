import uuid
from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.database import get_db
from app.models.wellness import Habit, HabitLog
from app.schemas.wellness import HabitCreate, HabitUpdate, HabitResponse, HabitLogCreate, HabitLogResponse
from app.core.security import get_current_user_id
from app.services.wellness_service import wellness_service

router = APIRouter()

@router.get("", response_model=List[HabitResponse])
async def list_habits(
    active_only: bool = True,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List habits for authenticated user with dynamically computed streaks and completion rates.
    """
    query = select(Habit).where(Habit.user_id == current_user_id)
    if active_only:
        query = query.where(Habit.active == True)
    query = query.order_by(Habit.created_at.asc())
    h_result = await db.execute(query)
    habits = h_result.scalars().all()

    # Fetch logs to calculate streaks
    logs_query = select(HabitLog).where(HabitLog.user_id == current_user_id)
    l_result = await db.execute(logs_query)
    all_logs = l_result.scalars().all()

    today = date.today()
    responses: List[HabitResponse] = []
    for h in habits:
        metrics = wellness_service.calculate_habit_metrics(h, list(all_logs), today)
        responses.append(
            HabitResponse(
                id=h.id,
                user_id=h.user_id,
                name=h.name,
                description=h.description,
                frequency=h.frequency,
                target=h.target,
                unit=h.unit,
                start_date=h.start_date,
                end_date=h.end_date,
                reminder_settings=h.reminder_settings or [],
                category=h.category or "General",
                active=h.active,
                current_streak=metrics["current_streak"],
                longest_streak=metrics["longest_streak"],
                completion_rate=metrics["completion_rate"],
                completed_today=metrics["completed_today"],
                created_at=h.created_at,
                updated_at=h.updated_at
            )
        )
    return responses

@router.post("", response_model=HabitResponse, status_code=status.HTTP_201_CREATED)
async def create_habit(
    habit_in: HabitCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new habit for the authenticated user.
    """
    habit_id = f"hbt_{uuid.uuid4().hex[:16]}"
    now = datetime.utcnow()
    new_habit = Habit(
        id=habit_id,
        user_id=current_user_id,
        name=habit_in.name,
        description=habit_in.description,
        frequency=habit_in.frequency,
        target=habit_in.target,
        unit=habit_in.unit,
        start_date=habit_in.start_date or now,
        end_date=habit_in.end_date,
        reminder_settings=habit_in.reminder_settings,
        category=habit_in.category,
        active=habit_in.active,
        created_at=now,
        updated_at=now
    )
    db.add(new_habit)
    await db.commit()
    await db.refresh(new_habit)

    return HabitResponse(
        id=new_habit.id,
        user_id=new_habit.user_id,
        name=new_habit.name,
        description=new_habit.description,
        frequency=new_habit.frequency,
        target=new_habit.target,
        unit=new_habit.unit,
        start_date=new_habit.start_date,
        end_date=new_habit.end_date,
        reminder_settings=new_habit.reminder_settings or [],
        category=new_habit.category or "General",
        active=new_habit.active,
        current_streak=0,
        longest_streak=0,
        completion_rate=0.0,
        completed_today=False,
        created_at=new_habit.created_at,
        updated_at=new_habit.updated_at
    )

@router.get("/{habit_id}", response_model=HabitResponse)
async def get_habit(
    habit_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a habit with multi-tenant isolation.
    """
    query = select(Habit).where(
        and_(Habit.id == habit_id, Habit.user_id == current_user_id)
    )
    result = await db.execute(query)
    habit = result.scalar_one_or_none()
    if not habit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Habit not found"
        )

    logs_query = select(HabitLog).where(
        and_(HabitLog.habit_id == habit_id, HabitLog.user_id == current_user_id)
    )
    l_result = await db.execute(logs_query)
    logs = l_result.scalars().all()

    metrics = wellness_service.calculate_habit_metrics(habit, list(logs), date.today())
    return HabitResponse(
        id=habit.id,
        user_id=habit.user_id,
        name=habit.name,
        description=habit.description,
        frequency=habit.frequency,
        target=habit.target,
        unit=habit.unit,
        start_date=habit.start_date,
        end_date=habit.end_date,
        reminder_settings=habit.reminder_settings or [],
        category=habit.category or "General",
        active=habit.active,
        current_streak=metrics["current_streak"],
        longest_streak=metrics["longest_streak"],
        completion_rate=metrics["completion_rate"],
        completed_today=metrics["completed_today"],
        created_at=habit.created_at,
        updated_at=habit.updated_at
    )

@router.put("/{habit_id}", response_model=HabitResponse)
async def update_habit(
    habit_id: str,
    habit_in: HabitUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update habit properties with multi-tenant isolation.
    """
    query = select(Habit).where(
        and_(Habit.id == habit_id, Habit.user_id == current_user_id)
    )
    result = await db.execute(query)
    habit = result.scalar_one_or_none()
    if not habit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Habit not found"
        )

    update_data = habit_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(habit, field, value)

    habit.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(habit)

    return await get_habit(habit_id=habit_id, current_user_id=current_user_id, db=db)

@router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_habit(
    habit_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a habit with multi-tenant isolation.
    """
    query = select(Habit).where(
        and_(Habit.id == habit_id, Habit.user_id == current_user_id)
    )
    result = await db.execute(query)
    habit = result.scalar_one_or_none()
    if not habit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Habit not found"
        )

    # Delete habit and associated logs
    logs_query = select(HabitLog).where(HabitLog.habit_id == habit_id)
    l_res = await db.execute(logs_query)
    for l in l_res.scalars().all():
        await db.delete(l)

    await db.delete(habit)
    await db.commit()
    return None

@router.post("/{habit_id}/log", response_model=HabitLogResponse)
async def log_habit(
    habit_id: str,
    log_in: HabitLogCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Log habit status (Completed, Skipped, Missed) for a given date.
    Enforces strict multi-tenant authorization.
    """
    # Verify habit ownership
    h_query = select(Habit).where(
        and_(Habit.id == habit_id, Habit.user_id == current_user_id)
    )
    h_result = await db.execute(h_query)
    habit = h_result.scalar_one_or_none()
    if not habit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Habit not found"
        )

    # Check existing log for this day
    log_query = select(HabitLog).where(
        and_(
            HabitLog.habit_id == habit_id,
            HabitLog.user_id == current_user_id,
            HabitLog.log_date == log_in.log_date
        )
    )
    log_result = await db.execute(log_query)
    existing_log = log_result.scalar_one_or_none()

    if existing_log:
        existing_log.status = log_in.status
        existing_log.count = log_in.count
        existing_log.notes = log_in.notes
        await db.commit()
        await db.refresh(existing_log)
        return existing_log

    new_log = HabitLog(
        id=f"log_{uuid.uuid4().hex[:16]}",
        habit_id=habit_id,
        user_id=current_user_id,
        log_date=log_in.log_date,
        status=log_in.status,
        count=log_in.count,
        notes=log_in.notes,
        created_at=datetime.utcnow()
    )
    db.add(new_log)
    await db.commit()
    await db.refresh(new_log)
    return new_log

@router.get("/{habit_id}/logs", response_model=List[HabitLogResponse])
async def list_habit_logs(
    habit_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List history logs for a habit.
    """
    # Verify habit ownership
    h_query = select(Habit).where(
        and_(Habit.id == habit_id, Habit.user_id == current_user_id)
    )
    h_result = await db.execute(h_query)
    if not h_result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Habit not found"
        )

    query = select(HabitLog).where(
        and_(HabitLog.habit_id == habit_id, HabitLog.user_id == current_user_id)
    ).order_by(HabitLog.log_date.desc())
    result = await db.execute(query)
    return result.scalars().all()
