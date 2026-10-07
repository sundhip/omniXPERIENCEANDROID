import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.learning import Project
from app.schemas.learning import ProjectCreate, ProjectUpdate, ProjectResponse, PriorityScoreResponse
from app.services.learning_priority_engine import LearningPriorityEngine
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[ProjectResponse])
async def list_projects(
    category: Optional[str] = None,
    status: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Project).where(Project.user_id == current_user_id)
    if category:
        query = query.where(Project.category == category)
    if status:
        query = query.where(Project.status == status)

    query = query.order_by(Project.created_at.desc())
    res = await db.execute(query)
    projects = res.scalars().all()
    return [ProjectResponse.model_validate(p) for p in projects]

@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    payload: ProjectCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    project = Project(
        id=str(uuid.uuid4()),
        user_id=current_user_id,
        title=payload.title,
        description=payload.description,
        category=payload.category,
        status=payload.status,
        priority=payload.priority,
        target_date=payload.target_date,
        progress=payload.progress,
        related_goal_id=payload.related_goal_id,
        related_task_ids=payload.related_task_ids,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return ProjectResponse.model_validate(project)

@router.get("/{id}", response_model=ProjectResponse)
async def get_project(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Project).where(Project.id == id, Project.user_id == current_user_id)
    res = await db.execute(query)
    project = res.scalars().first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return ProjectResponse.model_validate(project)

@router.put("/{id}", response_model=ProjectResponse)
async def update_project(
    id: str,
    payload: ProjectUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Project).where(Project.id == id, Project.user_id == current_user_id)
    res = await db.execute(query)
    project = res.scalars().first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(project, field, val)
    project.updated_at = datetime.utcnow()

    if project.progress is not None and project.progress >= 100.0 and project.status != "Completed":
        project.status = "Completed"

    await db.commit()
    await db.refresh(project)
    return ProjectResponse.model_validate(project)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Project).where(Project.id == id, Project.user_id == current_user_id)
    res = await db.execute(query)
    project = res.scalars().first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

    await db.delete(project)
    await db.commit()
    return None

@router.get("/{id}/priority", response_model=PriorityScoreResponse)
async def get_project_priority(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(Project).where(Project.id == id, Project.user_id == current_user_id)
    res = await db.execute(query)
    project = res.scalars().first()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

    return LearningPriorityEngine.calculate_priority(
        entity_id=project.id,
        entity_type="project",
        title=project.title,
        priority_label=project.priority,
        target_date=project.target_date,
        progress=project.progress or 0.0,
        estimated_duration_minutes=180
    )
