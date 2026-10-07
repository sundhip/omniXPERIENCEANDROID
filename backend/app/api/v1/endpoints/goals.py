import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.learning import Goal
from app.schemas.learning import GoalCreate, GoalUpdate, GoalResponse, GoalPlanResponse, PriorityScoreResponse
from app.services.goal_planning_service import GoalPlanningService
from app.services.learning_priority_engine import LearningPriorityEngine
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[GoalResponse])
async def list_goals(
    category: Optional[str] = None,
    status: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.user_id == current_user_id)
    if category:
        query = query.where(Goal.category == category)
    if status:
        query = query.where(Goal.status == status)

    query = query.order_by(Goal.created_at.desc())
    res = await db.execute(query)
    goals = res.scalars().all()
    return [GoalResponse.model_validate(g) for g in goals]

@router.post("", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    payload: GoalCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    # Ensure all milestones have an id
    milestones = []
    for idx, m in enumerate(payload.milestones):
        m_dict = dict(m)
        if not m_dict.get("id"):
            m_dict["id"] = str(uuid.uuid4())
        if not m_dict.get("order"):
            m_dict["order"] = idx + 1
        milestones.append(m_dict)

    goal = Goal(
        id=str(uuid.uuid4()),
        user_id=current_user_id,
        title=payload.title,
        description=payload.description,
        category=payload.category,
        priority=payload.priority,
        status=payload.status,
        target_date=payload.target_date,
        progress=payload.progress,
        milestones=milestones,
        related_task_ids=payload.related_task_ids,
        financial_target_amount=payload.financial_target_amount,
        financial_saved_amount=payload.financial_saved_amount or 0.0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(goal)
    await db.commit()
    await db.refresh(goal)
    return GoalResponse.model_validate(goal)

@router.get("/{id}", response_model=GoalResponse)
async def get_goal(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    return GoalResponse.model_validate(goal)

@router.put("/{id}", response_model=GoalResponse)
async def update_goal(
    id: str,
    payload: GoalUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(goal, field, val)
    goal.updated_at = datetime.utcnow()

    # Auto complete if progress reaches 100
    if goal.progress is not None and goal.progress >= 100.0 and goal.status != "Completed":
        goal.status = "Completed"

    await db.commit()
    await db.refresh(goal)
    return GoalResponse.model_validate(goal)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    await db.delete(goal)
    await db.commit()
    return None

@router.post("/{id}/milestones/{milestone_id}/toggle", response_model=GoalResponse)
async def toggle_goal_milestone(
    id: str,
    milestone_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    from sqlalchemy.orm.attributes import flag_modified
    milestones = [dict(m) for m in (goal.milestones or [])]
    found = False
    for m in milestones:
        if m.get("id") == milestone_id:
            m["completed"] = not m.get("completed", False)
            found = True
            break

    if not found:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Milestone not found")

    goal.milestones = milestones
    flag_modified(goal, "milestones")

    # Deterministically calculate progress based on completed milestones
    if milestones:
        completed_count = sum(1 for m in milestones if m.get("completed", False))
        goal.progress = round((completed_count / len(milestones)) * 100.0, 1)
        if goal.progress >= 100.0:
            goal.status = "Completed"
        elif goal.status == "Completed" and goal.progress < 100.0:
            goal.status = "Active"

    goal.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(goal)
    return GoalResponse.model_validate(goal)

@router.post("/{id}/plan", response_model=GoalPlanResponse)
async def plan_goal_endpoint(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    return await GoalPlanningService.plan_goal(db, current_user_id, goal)

@router.get("/{id}/priority", response_model=PriorityScoreResponse)
async def get_goal_priority(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Goal).where(Goal.id == id, Goal.user_id == current_user_id)
    res = await db.execute(query)
    goal = res.scalars().first()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    return LearningPriorityEngine.calculate_priority(
        entity_id=goal.id,
        entity_type="goal",
        title=goal.title,
        priority_label=goal.priority,
        target_date=goal.target_date,
        progress=goal.progress or 0.0,
        estimated_duration_minutes=120
    )
