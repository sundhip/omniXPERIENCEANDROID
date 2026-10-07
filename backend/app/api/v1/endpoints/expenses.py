import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.models.database import get_db
from app.models.finance import Expense
from app.schemas.finance import ExpenseCreate, ExpenseUpdate, ExpenseResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[ExpenseResponse])
async def list_expenses(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category: Optional[str] = None,
    payment_method: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(default=100, le=500),
    offset: int = Query(default=0, ge=0),
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List expenses for the authenticated user with optional filters.
    """
    query = select(Expense).where(Expense.user_id == current_user_id)

    if start_date:
        query = query.where(Expense.expense_date >= start_date)
    if end_date:
        query = query.where(Expense.expense_date <= end_date)
    if category:
        query = query.where(Expense.category == category)
    if payment_method:
        query = query.where(Expense.payment_method == payment_method)
    if search:
        search_fmt = f"%{search.strip().lower()}%"
        query = query.where(
            or_(
                Expense.description.ilike(search_fmt),
                Expense.merchant.ilike(search_fmt),
                Expense.notes.ilike(search_fmt)
            )
        )

    query = query.order_by(Expense.expense_date.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()

@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    expense_in: ExpenseCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new expense for the authenticated user.
    """
    expense_id = f"exp_{uuid.uuid4().hex[:16]}"
    new_expense = Expense(
        id=expense_id,
        user_id=current_user_id,
        amount=expense_in.amount,
        currency=expense_in.currency,
        category=expense_in.category,
        description=expense_in.description,
        expense_date=expense_in.expense_date,
        payment_method=expense_in.payment_method,
        merchant=expense_in.merchant,
        notes=expense_in.notes,
        tags=expense_in.tags,
        is_recurring=expense_in.is_recurring,
        recurring_rule=expense_in.recurring_rule,
        source=expense_in.source,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )

    db.add(new_expense)
    await db.commit()
    await db.refresh(new_expense)
    return new_expense

@router.get("/recurring", response_model=List[ExpenseResponse])
async def list_recurring_expenses(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List active recurring expenses for the authenticated user.
    """
    query = select(Expense).where(
        and_(
            Expense.user_id == current_user_id,
            Expense.is_recurring == True
        )
    ).order_by(Expense.expense_date.desc())
    result = await db.execute(query)
    return result.scalars().all()

@router.get("/{expense_id}", response_model=ExpenseResponse)
async def get_expense(
    expense_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a single expense. Enforces strict user isolation.
    """
    query = select(Expense).where(
        and_(Expense.id == expense_id, Expense.user_id == current_user_id)
    )
    result = await db.execute(query)
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )
    return expense

@router.put("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: str,
    expense_in: ExpenseUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update an expense. Enforces strict user isolation.
    """
    query = select(Expense).where(
        and_(Expense.id == expense_id, Expense.user_id == current_user_id)
    )
    result = await db.execute(query)
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )

    update_data = expense_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(expense, field, value)

    expense.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(expense)
    return expense

@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(
    expense_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete an expense. Enforces strict user isolation.
    """
    query = select(Expense).where(
        and_(Expense.id == expense_id, Expense.user_id == current_user_id)
    )
    result = await db.execute(query)
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expense not found"
        )

    await db.delete(expense)
    await db.commit()
    return None
