from sqlalchemy import Column, String, Integer, DateTime, JSON, Text, Boolean, Numeric
from datetime import datetime
from app.models.database import Base

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    # Using Numeric(12, 2) to prevent floating-point inaccuracies
    amount = Column(Numeric(12, 2, asdecimal=True), nullable=False)
    currency = Column(String(10), default="INR")
    category = Column(String(50), default="Other", index=True) 
    # Food, Transport, Shopping, Education, Health, Fitness, Entertainment, Bills, Subscriptions, Travel, Personal Care, Clothing, Technology, Other
    description = Column(String(255), nullable=True)
    expense_date = Column(DateTime, nullable=False, index=True)
    payment_method = Column(String(50), default="UPI") # Cash, UPI, Credit Card, Debit Card, Net Banking, Other
    merchant = Column(String(100), nullable=True)
    notes = Column(Text, nullable=True)
    tags = Column(JSON, default=list)
    is_recurring = Column(Boolean, default=False)
    recurring_rule = Column(JSON, nullable=True) # {"frequency": "monthly|weekly|yearly", "day": 5, "active": true}
    source = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Budget(Base):
    __tablename__ = "budgets"

    id = Column(String(64), primary_key=True, index=True)
    user_id = Column(String(64), nullable=False, index=True)
    category = Column(String(50), nullable=True, index=True) # null or 'Total' for overall monthly budget
    period = Column(String(20), default="monthly") # monthly, weekly, yearly
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    currency = Column(String(10), default="INR")
    amount = Column(Numeric(12, 2, asdecimal=True), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
