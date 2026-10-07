from typing import List
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.database import get_db
from app.models.finance import Expense, Budget
from app.schemas.finance import FinancialSummaryResponse, FinancialInsight
from app.core.security import get_current_user_id
from app.services.financial_service import financial_service

router = APIRouter()

STANDARD_CATEGORIES = [
    "Food",
    "Transport",
    "Shopping",
    "Education",
    "Health",
    "Fitness",
    "Entertainment",
    "Bills",
    "Subscriptions",
    "Travel",
    "Personal Care",
    "Clothing",
    "Technology",
    "Other"
]

@router.get("/summary", response_model=FinancialSummaryResponse)
async def get_financial_summary(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get unified financial dashboard summary for authenticated user with
    deterministic calculations and intelligent insights.
    """
    # Fetch all user expenses
    exp_query = select(Expense).where(Expense.user_id == current_user_id)
    exp_result = await db.execute(exp_query)
    expenses = exp_result.scalars().all()

    # Fetch user budgets
    bgt_query = select(Budget).where(Budget.user_id == current_user_id)
    bgt_result = await db.execute(bgt_query)
    budgets = bgt_result.scalars().all()

    return financial_service.calculate_summary(
        expenses=list(expenses),
        budgets=list(budgets),
        reference_date=datetime.utcnow()
    )

@router.get("/categories", response_model=List[str])
async def list_categories():
    """
    Returns standard extensible expense categories.
    """
    return STANDARD_CATEGORIES

@router.get("/insights", response_model=List[FinancialInsight])
async def get_financial_insights(
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get deterministic financial insights.
    """
    summary = await get_financial_summary(current_user_id=current_user_id, db=db)
    return summary.insights
