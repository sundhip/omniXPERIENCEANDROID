import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.database import get_db
from app.models.finance import Budget
from app.schemas.finance import BudgetCreate, BudgetUpdate, BudgetResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[BudgetResponse])
async def list_budgets(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List all budgets (overall + category-specific) for the authenticated user.
    """
    query = select(Budget).where(Budget.user_id == current_user_id).order_by(Budget.created_at.asc())
    result = await db.execute(query)
    return result.scalars().all()

@router.post("", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
async def create_or_update_budget(
    budget_in: BudgetCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a budget. If a budget for the same category (or total) already exists, update it.
    """
    cat = budget_in.category
    query = select(Budget).where(
        and_(
            Budget.user_id == current_user_id,
            Budget.category == cat,
            Budget.period == budget_in.period
        )
    )
    result = await db.execute(query)
    existing = result.scalar_one_or_none()

    if existing:
        existing.amount = budget_in.amount
        existing.currency = budget_in.currency
        existing.start_date = budget_in.start_date
        existing.end_date = budget_in.end_date
        existing.updated_at = datetime.utcnow()
        await db.commit()
        await db.refresh(existing)
        return existing

    budget_id = f"bgt_{uuid.uuid4().hex[:16]}"
    new_budget = Budget(
        id=budget_id,
        user_id=current_user_id,
        category=cat,
        period=budget_in.period,
        amount=budget_in.amount,
        currency=budget_in.currency,
        start_date=budget_in.start_date,
        end_date=budget_in.end_date,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(new_budget)
    await db.commit()
    await db.refresh(new_budget)
    return new_budget

@router.get("/{budget_id}", response_model=BudgetResponse)
async def get_budget(
    budget_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a specific budget with multi-tenant isolation.
    """
    query = select(Budget).where(
        and_(Budget.id == budget_id, Budget.user_id == current_user_id)
    )
    result = await db.execute(query)
    budget = result.scalar_one_or_none()
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found"
        )
    return budget

@router.put("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: str,
    budget_in: BudgetUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update a budget with multi-tenant isolation.
    """
    query = select(Budget).where(
        and_(Budget.id == budget_id, Budget.user_id == current_user_id)
    )
    result = await db.execute(query)
    budget = result.scalar_one_or_none()
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found"
        )

    update_data = budget_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(budget, field, value)

    budget.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(budget)
    return budget

@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_budget(
    budget_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a budget with multi-tenant isolation.
    """
    query = select(Budget).where(
        and_(Budget.id == budget_id, Budget.user_id == current_user_id)
    )
    result = await db.execute(query)
    budget = result.scalar_one_or_none()
    if not budget:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Budget not found"
        )

    await db.delete(budget)
    await db.commit()
    return None
