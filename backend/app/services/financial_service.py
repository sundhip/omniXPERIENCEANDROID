import calendar
from datetime import datetime, timedelta, date
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Dict, Any, Optional

from app.models.finance import Expense, Budget
from app.schemas.finance import (
    FinancialInsight, CategorySpending, FinancialSummaryResponse, ExpenseResponse
)

class FinancialIntelligenceService:
    """
    Deterministic financial intelligence service.
    Performs exact decimal arithmetic for totals, budgets, percentages,
    averages, and projections without floating point drift or LLM hallucination.
    """

    @staticmethod
    def round_dec(val: Decimal, places: int = 2) -> Decimal:
        return val.quantize(Decimal(10) ** -places, rounding=ROUND_HALF_UP)

    def calculate_summary(
        self,
        expenses: List[Expense],
        budgets: List[Budget],
        reference_date: Optional[datetime] = None
    ) -> FinancialSummaryResponse:
        now = reference_date or datetime.utcnow()
        today_date = now.date()
        current_year = now.year
        current_month = now.month

        # Month boundaries
        _, days_in_month = calendar.monthrange(current_year, current_month)
        days_elapsed = max(1, now.day)
        days_remaining = max(0, days_in_month - days_elapsed)

        start_of_week = today_date - timedelta(days=today_date.weekday()) # Monday

        today_spent = Decimal("0.00")
        week_spent = Decimal("0.00")
        month_spent = Decimal("0.00")
        category_totals: Dict[str, Decimal] = {}
        category_counts: Dict[str, int] = {}

        # Sift expenses
        for exp in expenses:
            exp_date = exp.expense_date.date()
            amt = Decimal(str(exp.amount))

            # Today
            if exp_date == today_date:
                today_spent += amt

            # This week (Monday to Sunday)
            if start_of_week <= exp_date <= today_date:
                week_spent += amt

            # This month
            if exp_date.year == current_year and exp_date.month == current_month:
                month_spent += amt
                cat = exp.category or "Other"
                category_totals[cat] = category_totals.get(cat, Decimal("0.00")) + amt
                category_counts[cat] = category_counts.get(cat, 0) + 1

        # Budget mapping
        overall_budget: Optional[Decimal] = None
        category_budgets: Dict[str, Decimal] = {}
        for b in budgets:
            if b.category is None or b.category.lower() in ("total", "overall", ""):
                overall_budget = Decimal(str(b.amount))
            else:
                category_budgets[b.category] = Decimal(str(b.amount))

        # Overall budget calculations
        remaining_budget = None
        budget_pct = None
        if overall_budget is not None and overall_budget > Decimal("0.00"):
            remaining_budget = overall_budget - month_spent
            budget_pct = self.round_dec((month_spent / overall_budget) * Decimal("100.00"))

        # Daily average and projections
        daily_average = self.round_dec(month_spent / Decimal(days_elapsed))
        projected_month_spent = self.round_dec(daily_average * Decimal(days_in_month))

        # Category breakdowns
        all_categories = sorted(list(set(list(category_totals.keys()) + list(category_budgets.keys()))))
        category_breakdowns: List[CategorySpending] = []
        for cat in all_categories:
            spent = category_totals.get(cat, Decimal("0.00"))
            b_amt = category_budgets.get(cat)
            pct = None
            if b_amt is not None and b_amt > Decimal("0.00"):
                pct = self.round_dec((spent / b_amt) * Decimal("100.00"))
            category_breakdowns.append(
                CategorySpending(
                    category=cat,
                    spent=spent,
                    budget=b_amt,
                    percentage_used=pct,
                    transaction_count=category_counts.get(cat, 0)
                )
            )

        # Generate deterministic insights
        insights = self.generate_insights(
            expenses=expenses,
            month_spent=month_spent,
            overall_budget=overall_budget,
            category_breakdowns=category_breakdowns,
            now=now,
            days_elapsed=days_elapsed,
            days_in_month=days_in_month
        )

        # Recent transactions (latest 10)
        sorted_recent = sorted(expenses, key=lambda x: x.expense_date, reverse=True)[:10]
        recent_responses = [ExpenseResponse.model_validate(e) for e in sorted_recent]

        return FinancialSummaryResponse(
            currency="INR",
            today_spent=self.round_dec(today_spent),
            week_spent=self.round_dec(week_spent),
            month_spent=self.round_dec(month_spent),
            total_budget=overall_budget,
            remaining_budget=remaining_budget,
            budget_used_percentage=budget_pct,
            daily_average=daily_average,
            projected_month_spent=projected_month_spent,
            days_elapsed=days_elapsed,
            days_remaining=days_remaining,
            category_breakdown=category_breakdowns,
            recent_transactions=recent_responses,
            insights=insights
        )

    def generate_insights(
        self,
        expenses: List[Expense],
        month_spent: Decimal,
        overall_budget: Optional[Decimal],
        category_breakdowns: List[CategorySpending],
        now: datetime,
        days_elapsed: int,
        days_in_month: int
    ) -> List[FinancialInsight]:
        insights: List[FinancialInsight] = []

        # 1. Budget Alerts
        if overall_budget is not None and overall_budget > Decimal("0.00"):
            pct = (month_spent / overall_budget) * Decimal("100.00")
            if month_spent > overall_budget:
                insights.append(
                    FinancialInsight(
                        type="budget_alert",
                        title="Budget Exceeded",
                        description=f"You have spent ₹{month_spent} which exceeds your monthly budget of ₹{overall_budget}.",
                        severity="critical",
                        supporting_data={
                            "month_spent": float(month_spent),
                            "budget": float(overall_budget),
                            "percentage": float(self.round_dec(pct))
                        }
                    )
                )
            elif pct >= Decimal("80.00"):
                insights.append(
                    FinancialInsight(
                        type="budget_alert",
                        title="Approaching Budget Limit",
                        description=f"You have used {self.round_dec(pct)}% of your monthly budget (₹{month_spent}/₹{overall_budget}) with {days_in_month - days_elapsed} days left.",
                        severity="warning",
                        supporting_data={
                            "month_spent": float(month_spent),
                            "budget": float(overall_budget),
                            "percentage": float(self.round_dec(pct))
                        }
                    )
                )

        # 2. Category Overspending / High Usage
        for cat_info in category_breakdowns:
            if cat_info.budget and cat_info.budget > Decimal("0.00"):
                cat_pct = (cat_info.spent / cat_info.budget) * Decimal("100.00")
                if cat_info.spent > cat_info.budget:
                    insights.append(
                        FinancialInsight(
                            type="category_trend",
                            title=f"{cat_info.category} Budget Exceeded",
                            description=f"Spending in {cat_info.category} (₹{cat_info.spent}) has exceeded your limit of ₹{cat_info.budget}.",
                            severity="warning",
                            supporting_data={
                                "category": cat_info.category,
                                "spent": float(cat_info.spent),
                                "budget": float(cat_info.budget)
                            }
                        )
                    )

        # 3. Monthly Comparison (Prior Month vs Current Month)
        prev_month = 12 if now.month == 1 else now.month - 1
        prev_year = now.year - 1 if now.month == 1 else now.year

        prev_expenses = [
            e for e in expenses
            if e.expense_date.year == prev_year and e.expense_date.month == prev_month
        ]

        if prev_expenses:
            prev_cat_totals: Dict[str, Decimal] = {}
            for e in prev_expenses:
                c = e.category or "Other"
                prev_cat_totals[c] = prev_cat_totals.get(c, Decimal("0.00")) + Decimal(str(e.amount))

            for cat_info in category_breakdowns:
                prev_amt = prev_cat_totals.get(cat_info.category, Decimal("0.00"))
                if prev_amt > Decimal("100.00") and cat_info.spent > prev_amt:
                    increase_pct = self.round_dec(((cat_info.spent - prev_amt) / prev_amt) * Decimal("100.00"))
                    if increase_pct >= Decimal("20.00"):
                        insights.append(
                            FinancialInsight(
                                type="category_trend",
                                title=f"{cat_info.category} Spending Increase",
                                description=f"{cat_info.category} is {increase_pct}% higher than your previous month.",
                                severity="info",
                                supporting_data={
                                    "category": cat_info.category,
                                    "current_spent": float(cat_info.spent),
                                    "previous_spent": float(prev_amt),
                                    "increase_pct": float(increase_pct)
                                }
                            )
                        )
        else:
            if not insights:
                insights.append(
                    FinancialInsight(
                        type="info",
                        title="Spending Trends",
                        description="Not enough history yet. Keep tracking to see spending insights.",
                        severity="info",
                        supporting_data={"status": "insufficient_history"}
                    )
                )

        # 4. Recurring Expenses Check
        recurring_active = [e for e in expenses if e.is_recurring and e.recurring_rule]
        if recurring_active:
            insights.append(
                FinancialInsight(
                    type="recurring_due",
                    title="Active Recurring Expenses",
                    description=f"You have {len(recurring_active)} recurring subscriptions/bills being tracked.",
                    severity="info",
                    supporting_data={"recurring_count": len(recurring_active)}
                )
            )

        return insights

financial_service = FinancialIntelligenceService()
