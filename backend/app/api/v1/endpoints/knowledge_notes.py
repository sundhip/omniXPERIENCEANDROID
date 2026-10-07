import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from app.models.database import get_db
from app.models.learning import KnowledgeNote
from app.schemas.learning import KnowledgeNoteCreate, KnowledgeNoteUpdate, KnowledgeNoteResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[KnowledgeNoteResponse])
async def list_knowledge_notes(
    search: Optional[str] = None,
    linked_entity_type: Optional[str] = None,
    linked_entity_id: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(KnowledgeNote).where(KnowledgeNote.user_id == current_user_id)
    if linked_entity_type:
        query = query.where(KnowledgeNote.linked_entity_type == linked_entity_type)
    if linked_entity_id:
        query = query.where(KnowledgeNote.linked_entity_id == linked_entity_id)
    if search:
        search_filter = or_(
            KnowledgeNote.title.ilike(f"%{search}%"),
            KnowledgeNote.content.ilike(f"%{search}%")
        )
        query = query.where(search_filter)

    query = query.order_by(KnowledgeNote.updated_at.desc())
    res = await db.execute(query)
    notes = res.scalars().all()
    return [KnowledgeNoteResponse.model_validate(n) for n in notes]

@router.post("", response_model=KnowledgeNoteResponse, status_code=status.HTTP_201_CREATED)
async def create_knowledge_note(
    payload: KnowledgeNoteCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    note = KnowledgeNote(
        id=str(uuid.uuid4()),
        user_id=current_user_id,
        title=payload.title,
        content=payload.content,
        tags=payload.tags,
        linked_entity_type=payload.linked_entity_type,
        linked_entity_id=payload.linked_entity_id,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return KnowledgeNoteResponse.model_validate(note)

@router.get("/{id}", response_model=KnowledgeNoteResponse)
async def get_knowledge_note(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(KnowledgeNote).where(KnowledgeNote.id == id, KnowledgeNote.user_id == current_user_id)
    res = await db.execute(query)
    note = res.scalars().first()
    if not note:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Knowledge note not found")
    return KnowledgeNoteResponse.model_validate(note)

@router.put("/{id}", response_model=KnowledgeNoteResponse)
async def update_knowledge_note(
    id: str,
    payload: KnowledgeNoteUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(KnowledgeNote).where(KnowledgeNote.id == id, KnowledgeNote.user_id == current_user_id)
    res = await db.execute(query)
    note = res.scalars().first()
    if not note:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Knowledge note not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(note, field, val)
    note.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(note)
    return KnowledgeNoteResponse.model_validate(note)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_knowledge_note(
    id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    query = select(KnowledgeNote).where(KnowledgeNote.id == id, KnowledgeNote.user_id == current_user_id)
    res = await db.execute(query)
    note = res.scalars().first()
    if not note:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Knowledge note not found")

    await db.delete(note)
    await db.commit()
    return None
