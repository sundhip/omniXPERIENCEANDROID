import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.personal_ai import UserMemory, ProactiveInsight
from app.core.security import get_current_user_id
from app.schemas.personal_ai import (
    AssistantMessageRequest,
    AssistantMessageResponse,
    ActionExecutionRequest,
    ActionExecutionResponse,
    DailyPersonalBrief,
    PersonalContextSnapshot,
    ProactiveInsightResponse,
    UserMemoryDTO,
    UserMemoryCreate
)
from app.services.personal_context_engine import personal_context_engine
from app.services.personal_intelligence_service import personal_intelligence_service
from app.services.personal_ai_tools import personal_ai_tools

router = APIRouter()

@router.post("/ask", response_model=AssistantMessageResponse)
async def ask_assistant(
    request: AssistantMessageRequest,
    lat: Optional[float] = Query(None),
    lon: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Unified Ask OmniXPERIENCE Personal AI endpoint.
    Performs context aggregation, relevance filtering, cross-domain reasoning,
    epistemic safety labeling, and generates safe action proposals where appropriate.
    """
    return await personal_intelligence_service.process_assistant_query(
        prompt=request.prompt,
        user_id=user_id,
        db=db,
        lat=lat,
        lon=lon
    )


@router.post("/actions/execute", response_model=ActionExecutionResponse)
async def execute_action(
    request: ActionExecutionRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Executes or rejects an ActionProposal that was previously prepared.
    Requires user_id match to prevent unauthorized cross-tenant execution.
    """
    result = await personal_ai_tools.execute_proposal(
        proposal_id=request.proposal_id,
        user_id=user_id,
        db=db,
        confirm=request.confirm
    )
    if result.get("status") == "not_found":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result.get("message", "Proposal not found or access denied.")
        )

    return ActionExecutionResponse(
        proposal_id=request.proposal_id,
        success=result.get("success", False),
        status=result.get("status", "unknown"),
        result=result,
        message=result.get("message", "")
    )


@router.get("/context", response_model=PersonalContextSnapshot)
async def get_personal_context(
    lat: Optional[float] = Query(None),
    lon: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns normalized PersonalContextSnapshot across all active domains.
    Strictly isolated to authenticated user.
    """
    return await personal_context_engine.build_context_snapshot(
        user_id=user_id,
        db=db,
        lat=lat,
        lon=lon
    )


@router.get("/daily-brief", response_model=DailyPersonalBrief)
async def get_daily_brief(
    lat: Optional[float] = Query(None),
    lon: Optional[float] = Query(None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Generates concise, truthful Daily Personal Brief for the Today screen.
    """
    return await personal_intelligence_service.generate_daily_brief(
        user_id=user_id,
        db=db,
        lat=lat,
        lon=lon
    )


@router.get("/insights", response_model=List[ProactiveInsightResponse])
async def get_proactive_insights(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieves active, deduplicated proactive insights for the authenticated user.
    """
    return await personal_intelligence_service.get_or_create_proactive_insights(
        user_id=user_id,
        db=db
    )


@router.post("/insights/{insight_id}/dismiss")
async def dismiss_proactive_insight(
    insight_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Dismisses a proactive insight with multi-tenant verification.
    """
    result = await db.execute(
        select(ProactiveInsight).where(
            ProactiveInsight.id == insight_id,
            ProactiveInsight.user_id == user_id
        )
    )
    insight = result.scalars().first()
    if not insight:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Insight not found.")

    insight.dismissed = True
    await db.commit()
    return {"status": "success", "message": "Insight dismissed."}


@router.get("/memories", response_model=List[UserMemoryDTO])
async def list_user_memories(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Lists persistent user-confirmed preferences and memories.
    """
    result = await db.execute(
        select(UserMemory).where(UserMemory.user_id == user_id).order_by(UserMemory.created_at.desc())
    )
    return result.scalars().all()


@router.post("/memories", response_model=UserMemoryDTO)
async def create_user_memory(
    memory_in: UserMemoryCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Stores an explicit user-confirmed preference or memory.
    """
    memory = UserMemory(
        id=f"mem_{uuid.uuid4().hex[:8]}",
        user_id=user_id,
        key=memory_in.key,
        value=memory_in.value,
        domain=memory_in.domain,
        source="user_confirmed"
    )
    db.add(memory)
    await db.commit()
    await db.refresh(memory)
    return memory


@router.delete("/memories/{memory_id}")
async def delete_user_memory(
    memory_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Deletes a user memory preference with strict ownership verification.
    """
    result = await db.execute(
        select(UserMemory).where(UserMemory.id == memory_id, UserMemory.user_id == user_id)
    )
    memory = result.scalars().first()
    if not memory:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Memory not found.")

    await db.delete(memory)
    await db.commit()
    return {"status": "success", "message": "Memory deleted."}
