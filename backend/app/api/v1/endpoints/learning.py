import uuid
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.models.database import get_db
from app.models.learning import LearningItem, Goal, StudySession
from app.schemas.learning import (
    LearningItemCreate, LearningItemUpdate, LearningItemResponse,
    LearnDashboardResponse, LearningInsight, PriorityScoreResponse,
    StudySessionResponse
)
from app.services.learning_intelligence_service import LearningIntelligenceService
from app.services.learning_priority_engine import LearningPriorityEngine
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[LearningItemResponse])
async def list_learning_items(
    category: Optional[str] = None,
    type: Optional[str] = None,
    status: Optional[str] = None,
    parent_id: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(LearningItem).where(LearningItem.user_id == current_user_id)
    if category:
        query = query.where(LearningItem.category == category)
    if type:
        query = query.where(LearningItem.type == type)
    if status:
        query = query.where(LearningItem.status == status)
    if parent_id is not None:
        query = query.where(LearningItem.parent_id == parent_id)

    query = query.order_by(LearningItem.created_at.desc())
    res = await db.execute(query)
    items = res.scalars().all()

    # Populate children hierarchy if top-level items
    item_map = {item.id: item for item in items}
    responses: List[LearningItemResponse] = []
    for item in items:
        resp = LearningItemResponse.model_validate(item)
        responses.append(resp)
    return responses

@router.post("", response_model=LearningItemResponse, status_code=status.HTTP_201_CREATED)
async def create_learning_item(
    payload: LearningItemCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    item = LearningItem(
        id=str(uuid.uuid4()),
        user_id=current_user_id,
        title=payload.title,
        description=payload.description,
        type=payload.type,
        category=payload.category,
        status=payload.status,
        priority=payload.priority,
        progress=payload.progress,
        target_date=payload.target_date,
        estimated_duration_minutes=payload.estimated_duration_minutes,
        parent_id=payload.parent_id,
        tags=payload.tags,
        related_task_ids=payload.related_task_ids,
        related_goal_id=payload.related_goal_id,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return LearningItemResponse.model_validate(item)

@router.get("/dashboard", response_model=LearnDashboardResponse)
async def get_learning_dashboard(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    now = datetime.utcnow()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = now.replace(hour=23, minute=59, second=59, microsecond=0)
    week_start = now - timedelta(days=now.weekday()) # Monday

    # 1. Learning items
    learning_query = select(LearningItem).where(LearningItem.user_id == current_user_id)
    l_res = await db.execute(learning_query)
    all_learning = l_res.scalars().all()

    # 2. Goals
    goals_query = select(Goal).where(Goal.user_id == current_user_id)
    g_res = await db.execute(goals_query)
    all_goals = g_res.scalars().all()

    # 3. Sessions
    sessions_query = select(StudySession).where(StudySession.user_id == current_user_id)
    s_res = await db.execute(sessions_query)
    all_sessions = s_res.scalars().all()

    # Filter Today learning
    today_learning = [
        item for item in all_learning
        if item.status in ["In Progress", "Not Started"] and item.priority in ["High", "Urgent"]
    ][:5]

    # Filter Today milestones
    today_milestones: List[Dict[str, Any]] = []
    for g in all_goals:
        for m in (g.milestones or []):
            if not m.get("completed", False):
                t_date = m.get("target_date")
                # If target date is today or soon
                if t_date and t_date[:10] == now.strftime("%Y-%m-%d"):
                    today_milestones.append({
                        "goal_id": g.id,
                        "goal_title": g.title,
                        "milestone_id": m.get("id"),
                        "title": m.get("title"),
                        "target_date": t_date
                    })

    # Today sessions
    today_sessions = [
        s for s in all_sessions
        if s.start_time and today_start <= s.start_time <= today_end
    ]

    # Upcoming Deadlines (within 7 days)
    upcoming_deadlines: List[Dict[str, Any]] = []
    for item in all_learning:
        if item.target_date and now <= item.target_date <= now + timedelta(days=7) and item.status != "Completed":
            days_left = max(0, int((item.target_date - now).total_seconds() / 86400.0))
            upcoming_deadlines.append({
                "id": item.id,
                "title": item.title,
                "type": item.type,
                "category": item.category,
                "target_date": item.target_date.isoformat(),
                "days_left": days_left,
                "progress": item.progress
            })
    upcoming_deadlines.sort(key=lambda x: x["days_left"])

    # Overdue items
    overdue_items: List[Dict[str, Any]] = []
    for item in all_learning:
        if item.target_date and item.target_date < now and item.status != "Completed":
            overdue_items.append({
                "id": item.id,
                "title": item.title,
                "type": item.type,
                "target_date": item.target_date.isoformat(),
                "progress": item.progress
            })

    # At-risk goals (deadline in < 14 days with < 50% progress)
    at_risk_goals: List[Dict[str, Any]] = []
    for g in all_goals:
        if g.target_date and now <= g.target_date <= now + timedelta(days=14) and (g.progress or 0.0) < 50.0 and g.status == "Active":
            at_risk_goals.append({
                "id": g.id,
                "title": g.title,
                "progress": g.progress,
                "target_date": g.target_date.isoformat(),
                "reason": f"Only {int(g.progress)}% done with deadline approaching in < 14 days"
            })

    # Total study minutes this week
    this_week_sessions = [
        s for s in all_sessions
        if s.created_at and s.created_at >= week_start and s.status == "Completed"
    ]
    total_study_mins = sum(s.actual_duration_minutes or s.planned_duration_minutes for s in this_week_sessions)

    # Completed milestones count
    completed_milestones = sum(
        sum(1 for m in (g.milestones or []) if m.get("completed", False))
        for g in all_goals
    )

    # Actionable insights
    insights = await LearningIntelligenceService.get_learning_insights(db, current_user_id)

    return LearnDashboardResponse(
        today_learning=[LearningItemResponse.model_validate(i) for i in today_learning],
        today_milestones=today_milestones,
        today_sessions=[StudySessionResponse.model_validate(s) for s in today_sessions],
        upcoming_deadlines=upcoming_deadlines[:6],
        active_goals_count=len([g for g in all_goals if g.status == "Active"]),
        active_learning_count=len([i for i in all_learning if i.status in ["In Progress", "Not Started"]]),
        completed_milestones_count=completed_milestones,
        total_study_minutes_this_week=total_study_mins,
        overdue_items=overdue_items[:5],
        at_risk_goals=at_risk_goals[:5],
        insights=insights
    )

@router.get("/insights", response_model=List[LearningInsight])
async def get_learning_insights_endpoint(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    return await LearningIntelligenceService.get_learning_insights(db, current_user_id)

@router.get("/{id}", response_model=LearningItemResponse)
async def get_learning_item(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(LearningItem).where(LearningItem.id == id, LearningItem.user_id == current_user_id)
    res = await db.execute(query)
    item = res.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning item not found")
    return LearningItemResponse.model_validate(item)

@router.put("/{id}", response_model=LearningItemResponse)
async def update_learning_item(
    id: str,
    payload: LearningItemUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(LearningItem).where(LearningItem.id == id, LearningItem.user_id == current_user_id)
    res = await db.execute(query)
    item = res.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning item not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(item, field, val)
    item.updated_at = datetime.utcnow()

    # Automatically set Completed if progress reaches 100
    if item.progress is not None and item.progress >= 100.0 and item.status != "Completed":
        item.status = "Completed"

    await db.commit()
    await db.refresh(item)
    return LearningItemResponse.model_validate(item)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_learning_item(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(LearningItem).where(LearningItem.id == id, LearningItem.user_id == current_user_id)
    res = await db.execute(query)
    item = res.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning item not found")

    await db.delete(item)
    await db.commit()
    return None

@router.get("/{id}/priority", response_model=PriorityScoreResponse)
async def get_learning_item_priority(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(LearningItem).where(LearningItem.id == id, LearningItem.user_id == current_user_id)
    res = await db.execute(query)
    item = res.scalars().first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Learning item not found")

    return LearningPriorityEngine.calculate_priority(
        entity_id=item.id,
        entity_type="learning_item",
        title=item.title,
        priority_label=item.priority,
        target_date=item.target_date,
        progress=item.progress or 0.0,
        estimated_duration_minutes=item.estimated_duration_minutes or 60
    )
