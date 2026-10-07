import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.learning import StudySession
from app.schemas.learning import StudySessionCreate, StudySessionUpdate, StudySessionResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[StudySessionResponse])
async def list_study_sessions(
    learning_item_id: Optional[str] = None,
    goal_id: Optional[str] = None,
    status: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(StudySession).where(StudySession.user_id == current_user_id)
    if learning_item_id:
        query = query.where(StudySession.learning_item_id == learning_item_id)
    if goal_id:
        query = query.where(StudySession.goal_id == goal_id)
    if status:
        query = query.where(StudySession.status == status)

    query = query.order_by(StudySession.created_at.desc())
    res = await db.execute(query)
    sessions = res.scalars().all()
    return [StudySessionResponse.model_validate(s) for s in sessions]

@router.post("", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
async def create_study_session(
    payload: StudySessionCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    session = StudySession(
        id=str(uuid.uuid4()),
        user_id=current_user_id,
        title=payload.title,
        learning_item_id=payload.learning_item_id,
        goal_id=payload.goal_id,
        task_id=payload.task_id,
        event_id=payload.event_id,
        session_type=payload.session_type,
        planned_duration_minutes=payload.planned_duration_minutes,
        actual_duration_minutes=payload.actual_duration_minutes,
        start_time=payload.start_time or datetime.utcnow(),
        end_time=payload.end_time,
        status=payload.status,
        notes=payload.notes,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return StudySessionResponse.model_validate(session)

@router.get("/{id}", response_model=StudySessionResponse)
async def get_study_session(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(StudySession).where(StudySession.id == id, StudySession.user_id == current_user_id)
    res = await db.execute(query)
    session = res.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Study session not found")
    return StudySessionResponse.model_validate(session)

@router.put("/{id}", response_model=StudySessionResponse)
async def update_study_session(
    id: str,
    payload: StudySessionUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(StudySession).where(StudySession.id == id, StudySession.user_id == current_user_id)
    res = await db.execute(query)
    session = res.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Study session not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(session, field, val)
    session.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(session)
    return StudySessionResponse.model_validate(session)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_study_session(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(StudySession).where(StudySession.id == id, StudySession.user_id == current_user_id)
    res = await db.execute(query)
    session = res.scalars().first()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Study session not found")

    await db.delete(session)
    await db.commit()
    return None
