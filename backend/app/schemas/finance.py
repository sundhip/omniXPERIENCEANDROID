from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime
from decimal import Decimal

class RecurringRule(BaseModel):
    frequency: str = "monthly" # daily, weekly, monthly, yearly
    day_of_month: Optional[int] = None
    day_of_week: Optional[int] = None
    active: bool = True

class ExpenseBase(BaseModel):
    amount: Decimal = Field(..., gt=0, description="Expense amount (must be positive)")
    currency: str = Field(default="INR", max_length=10)
    category: str = Field(default="Other", max_length=50)
    description: Optional[str] = Field(default=None, max_length=255)
    expense_date: datetime
    payment_method: str = Field(default="UPI", max_length=50)
    merchant: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    is_recurring: bool = False
    recurring_rule: Optional[Dict[str, Any]] = None
    source: Optional[str] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseUpdate(BaseModel):
    amount: Optional[Decimal] = Field(default=None, gt=0)
    currency: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    expense_date: Optional[datetime] = None
    payment_method: Optional[str] = None
    merchant: Optional[str] = None
    notes: Optional[str] = None
    tags: Optional[List[str]] = None
    is_recurring: Optional[bool] = None
    recurring_rule: Optional[Dict[str, Any]] = None

class ExpenseResponse(ExpenseBase):
    id: str
    user_id: str
    tags: List[str] = Field(default_factory=list)
    is_recurring: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(from_attributes=True)

class BudgetBase(BaseModel):
    amount: Decimal = Field(..., gt=0, description="Budget amount")
    category: Optional[str] = Field(default=None, max_length=50) # None or "Total"
    period: str = Field(default="monthly", max_length=20)
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    currency: str = Field(default="INR", max_length=10)

class BudgetCreate(BudgetBase):
    pass

class BudgetUpdate(BaseModel):
    amount: Optional[Decimal] = Field(default=None, gt=0)
    category: Optional[str] = None
    period: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    currency: Optional[str] = None

class BudgetResponse(BudgetBase):
    id: str
    user_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(from_attributes=True)

class CategorySpending(BaseModel):
    category: str
    spent: Decimal
    budget: Optional[Decimal] = None
    percentage_used: Optional[Decimal] = None
    transaction_count: int

class FinancialInsight(BaseModel):
    type: str # 'budget_alert' | 'category_trend' | 'recurring_due' | 'unusual_spending' | 'info'
    title: str
    description: str
    severity: str # 'info' | 'warning' | 'critical'
    supporting_data: Dict[str, Any] = Field(default_factory=dict)

class FinancialSummaryResponse(BaseModel):
    currency: str = "INR"
    today_spent: Decimal
    week_spent: Decimal
    month_spent: Decimal
    total_budget: Optional[Decimal] = None
    remaining_budget: Optional[Decimal] = None
    budget_used_percentage: Optional[Decimal] = None
    daily_average: Decimal
    projected_month_spent: Decimal
    days_elapsed: int
    days_remaining: int
    category_breakdown: List[CategorySpending] = Field(default_factory=list)
    recent_transactions: List[ExpenseResponse] = Field(default_factory=list)
    insights: List[FinancialInsight] = Field(default_factory=list)
