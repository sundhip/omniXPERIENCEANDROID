import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.models.database import get_db
from app.models.productivity import Event
from app.schemas.productivity import EventCreate, EventUpdate, EventResponse, ScheduleConflict
from app.core.security import get_current_user_id
from app.services.productivity_service import productivity_service

router = APIRouter()

@router.get("", response_model=List[EventResponse])
async def list_events(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List events for current authenticated user with optional date range, category, status, and search filters.
    """
    query = select(Event).where(Event.user_id == current_user_id)

    if start_date:
        query = query.where(Event.end_time >= start_date)
    if end_date:
        query = query.where(Event.start_time <= end_date)
    if category:
        query = query.where(Event.category == category)
    if status:
        query = query.where(Event.status == status)
    if search:
        search_fmt = f"%{search.strip().lower()}%"
        query = query.where(
            or_(
                Event.title.ilike(search_fmt),
                Event.description.ilike(search_fmt),
                Event.location.ilike(search_fmt)
            )
        )

    query = query.order_by(Event.start_time.asc())
    result = await db.execute(query)
    return result.scalars().all()

@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
async def create_event(
    event_in: EventCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new event for current authenticated user.
    """
    if event_in.end_time < event_in.start_time:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Event end time cannot be before start time."
        )

    new_id = f"evt_{uuid.uuid4().hex[:16]}"
    event_data = event_in.model_dump()
    event_data["id"] = new_id
    event_data["user_id"] = current_user_id

    event = Event(**event_data)
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event

@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get single event by ID with strict ownership verification.
    """
    query = select(Event).where(and_(Event.id == event_id, Event.user_id == current_user_id))
    result = await db.execute(query)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found."
        )
    return event

@router.put("/{event_id}", response_model=EventResponse)
async def update_event(
    event_id: str,
    event_update: EventUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update an event with strict ownership verification.
    """
    query = select(Event).where(and_(Event.id == event_id, Event.user_id == current_user_id))
    result = await db.execute(query)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found."
        )

    update_data = event_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(event, field, value)

    if event.end_time < event.start_time:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Event end time cannot be before start time."
        )

    event.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(event)
    return event

@router.delete("/{event_id}", status_code=status.HTTP_200_OK)
async def delete_event(
    event_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete an event with strict ownership verification.
    """
    query = select(Event).where(and_(Event.id == event_id, Event.user_id == current_user_id))
    result = await db.execute(query)
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found."
        )

    await db.delete(event)
    await db.commit()
    return {"message": "Event deleted successfully.", "id": event_id}
