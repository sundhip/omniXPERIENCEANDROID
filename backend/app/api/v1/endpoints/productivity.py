from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.productivity import Event, Task
from app.schemas.productivity import (
    TodayProductivityResponse,
    ScheduleConflict,
    PriorityAssessment,
    ProductivityCategory
)
from app.core.security import get_current_user_id
from app.services.productivity_service import productivity_service

router = APIRouter()

@router.get("/categories", response_model=List[str])
async def get_categories():
    """
    Returns standard categories for productivity events and tasks.
    """
    return [c.value for c in ProductivityCategory]

@router.get("/today", response_model=TodayProductivityResponse)
async def get_today_dashboard(
    target_date: Optional[date] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns unified Today Productivity Intelligence:
    events, tasks, overdue items, upcoming deadlines, schedule conflicts,
    free time windows, and recommended task slot suggestions.
    """
    # Fetch all user's events and tasks
    ev_stmt = select(Event).where(Event.user_id == current_user_id)
    ev_res = await db.execute(ev_stmt)
    events = ev_res.scalars().all()

    tsk_stmt = select(Task).where(Task.user_id == current_user_id)
    tsk_res = await db.execute(tsk_stmt)
    tasks = tsk_res.scalars().all()

    return productivity_service.compile_today_dashboard(
        events=events,
        tasks=tasks,
        target_date=target_date,
        now=datetime.utcnow()
    )

@router.get("/conflicts", response_model=List[ScheduleConflict])
async def get_schedule_conflicts(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Detects overlapping events for the user in the specified date range.
    """
    stmt = select(Event).where(Event.user_id == current_user_id)
    if start_date:
        stmt = stmt.where(Event.end_time >= start_date)
    if end_date:
        stmt = stmt.where(Event.start_time <= end_date)

    res = await db.execute(stmt)
    events = res.scalars().all()
    return productivity_service.detect_conflicts(events)

@router.get("/priority-assessment", response_model=List[PriorityAssessment])
async def get_task_priority_assessment(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Evaluates urgency scores, dependency blockers, and suggested priority
    for all active tasks using the deterministic ProductivityPriorityEngine.
    """
    stmt = select(Task).where(Task.user_id == current_user_id)
    res = await db.execute(stmt)
    tasks = res.scalars().all()

    now = datetime.utcnow()
    assessments = [
        productivity_service.calculate_task_priority(t, tasks, current_time=now)
        for t in tasks
        if t.status != "Completed"
    ]
    # Sort descending by urgency score
    assessments.sort(key=lambda a: a.urgency_score, reverse=True)
    return assessments
