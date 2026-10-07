import pytest
import pytest_asyncio
from decimal import Decimal
from datetime import datetime, timedelta, date
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.models.database import AsyncSessionLocal, run_migrations, engine
from app.core.security import create_access_token

@pytest_asyncio.fixture(scope="module", autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(run_migrations)
    yield

import uuid

@pytest.fixture
def user_a_headers():
    uid = f"user_p6_a_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def user_b_headers():
    uid = f"user_p6_b_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_expense_crud_and_exact_math(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Add ₹100 expense
        res1 = await client.post("/api/v1/expenses", json={
            "amount": "100.00",
            "currency": "INR",
            "category": "Food",
            "description": "Lunch with team",
            "expense_date": datetime.utcnow().isoformat(),
            "payment_method": "UPI"
        }, headers=user_a_headers)
        assert res1.status_code == 201, res1.text
        exp1 = res1.json()
        assert exp1["amount"] == "100.00"

        # 2. Add ₹250 expense
        res2 = await client.post("/api/v1/expenses", json={
            "amount": "250.00",
            "currency": "INR",
            "category": "Transport",
            "description": "Cab fare",
            "expense_date": datetime.utcnow().isoformat(),
            "payment_method": "UPI"
        }, headers=user_a_headers)
        assert res2.status_code == 201, res2.text
        exp2 = res2.json()
        assert exp2["amount"] == "250.00"

        # 3. Create budget of ₹10,000 (total monthly)
        b_res = await client.post("/api/v1/budgets", json={
            "amount": "10000.00",
            "category": "Total",
            "period": "monthly",
            "currency": "INR"
        }, headers=user_a_headers)
        assert b_res.status_code == 201, b_res.text
        bgt = b_res.json()
        assert bgt["amount"] == "10000.00"

        # 4. Check Financial Summary:
        # Sum spent = 100 + 250 = 350
        # Remaining = 10000 - 350 = 9650
        # Percentage = (350 / 10000) * 100 = 3.5%
        summary_res = await client.get("/api/v1/finance/summary", headers=user_a_headers)
        assert summary_res.status_code == 200, summary_res.text
        summary = summary_res.json()
        assert Decimal(summary["today_spent"]) == Decimal("350.00")
        assert Decimal(summary["month_spent"]) == Decimal("350.00")
        assert Decimal(summary["total_budget"]) == Decimal("10000.00")
        assert Decimal(summary["remaining_budget"]) == Decimal("9650.00")
        assert Decimal(summary["budget_used_percentage"]) == Decimal("3.50")

        # 5. Verify User Isolation: User B cannot access User A's expense
        sec_res = await client.get(f"/api/v1/expenses/{exp1['id']}", headers=user_b_headers)
        assert sec_res.status_code == 404

        # User B summary has 0 spent
        b_summary = await client.get("/api/v1/finance/summary", headers=user_b_headers)
        assert b_summary.status_code == 200
        assert Decimal(b_summary.json()["month_spent"]) == Decimal("0.00")

@pytest.mark.asyncio
async def test_budget_exact_percentage_calculation():
    from app.services.financial_service import financial_service
    from app.models.finance import Expense, Budget

    # Test case from prompt:
    # ₹10,000 budget, ₹2,500 spent -> ₹7,500 remaining, 25.00%
    now = datetime(2026, 10, 15, 12, 0, 0)
    expenses = [
        Expense(
            id="exp_test_1",
            user_id="u1",
            amount=Decimal("2500.00"),
            currency="INR",
            category="Shopping",
            expense_date=now,
            payment_method="UPI",
            tags=[],
            is_recurring=False,
            created_at=now,
            updated_at=now
        )
    ]
    budgets = [
        Budget(
            id="bgt_test_1",
            user_id="u1",
            category=None, # overall
            amount=Decimal("10000.00"),
            period="monthly",
            currency="INR",
            created_at=now,
            updated_at=now
        )
    ]

    summary = financial_service.calculate_summary(expenses, budgets, reference_date=now)
    assert summary.month_spent == Decimal("2500.00")
    assert summary.total_budget == Decimal("10000.00")
    assert summary.remaining_budget == Decimal("7500.00")
    assert summary.budget_used_percentage == Decimal("25.00")

@pytest.mark.asyncio
async def test_habits_truthful_streak_and_isolation(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Create a habit "Drink water"
        res = await client.post("/api/v1/habits", json={
            "name": "Drink water",
            "description": "8 glasses of water daily",
            "frequency": "Daily",
            "target": 8,
            "unit": "glasses",
            "category": "Hydration"
        }, headers=user_a_headers)
        assert res.status_code == 201, res.text
        habit = res.json()
        assert habit["current_streak"] == 0

        # 2. Log completion for 3 consecutive days (including today)
        today = date.today()
        d0 = today.strftime("%Y-%m-%d")
        d1 = (today - timedelta(days=1)).strftime("%Y-%m-%d")
        d2 = (today - timedelta(days=2)).strftime("%Y-%m-%d")

        for d in [d2, d1, d0]:
            log_res = await client.post(f"/api/v1/habits/{habit['id']}/log", json={
                "log_date": d,
                "status": "Completed",
                "count": 8
            }, headers=user_a_headers)
            assert log_res.status_code == 200, log_res.text

        # 3. Check habit streak: should be exactly 3
        get_res = await client.get(f"/api/v1/habits/{habit['id']}", headers=user_a_headers)
        assert get_res.status_code == 200
        assert get_res.json()["current_streak"] == 3
        assert get_res.json()["completed_today"] is True

        # 4. User B cannot see or log User A's habit
        b_res = await client.get(f"/api/v1/habits/{habit['id']}", headers=user_b_headers)
        assert b_res.status_code == 404

        b_log = await client.post(f"/api/v1/habits/{habit['id']}/log", json={
            "log_date": d0,
            "status": "Completed"
        }, headers=user_b_headers)
        assert b_log.status_code == 404

@pytest.mark.asyncio
async def test_skincare_routine_and_today_wellness(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Save skincare profile
        p_res = await client.post("/api/v1/wellness/skincare-profile", json={
            "skin_type": "Combination",
            "skin_concerns": ["Hydration", "Sun Protection"],
            "sensitivity_level": "Normal",
            "routine_frequency": "Twice daily",
            "notes": "Prefers lightweight textures"
        }, headers=user_a_headers)
        assert p_res.status_code == 200, p_res.text
        profile = p_res.json()
        assert profile["skin_type"] == "Combination"

        # 2. Add morning routine steps
        s1_res = await client.post("/api/v1/wellness/routines", json={
            "product_name": "Gentle Foam Cleanser",
            "category": "Cleanser",
            "routine_step": 1,
            "time_of_day": "morning",
            "frequency": "Daily"
        }, headers=user_a_headers)
        assert s1_res.status_code == 201

        s2_res = await client.post("/api/v1/wellness/routines", json={
            "product_name": "SPF 50 Sunscreen",
            "category": "Sunscreen",
            "routine_step": 2,
            "time_of_day": "morning",
            "frequency": "Daily"
        }, headers=user_a_headers)
        assert s2_res.status_code == 201

        # 3. Add evening routine step
        s3_res = await client.post("/api/v1/wellness/routines", json={
            "product_name": "Barrier Repair Moisturizer",
            "category": "Moisturizer",
            "routine_step": 1,
            "time_of_day": "evening",
            "frequency": "Daily"
        }, headers=user_a_headers)
        assert s3_res.status_code == 201

        # 4. Fetch /wellness/today
        today_res = await client.get("/api/v1/wellness/today", headers=user_a_headers)
        assert today_res.status_code == 200, today_res.text
        wellness_data = today_res.json()
        assert len(wellness_data["morning_routine"]) == 2
        assert len(wellness_data["evening_routine"]) == 1
        assert wellness_data["morning_routine"][0]["product_name"] == "Gentle Foam Cleanser"

        # 5. Verify User Isolation on routine items
        rtn_id = s1_res.json()["id"]
        sec_r = await client.get(f"/api/v1/wellness/routines/{rtn_id}", headers=user_b_headers)
        assert sec_r.status_code == 404

@pytest.mark.asyncio
async def test_zero_budget_and_negative_amount_protection(user_a_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Negative expense amount must fail validation with 422
        bad_exp = await client.post("/api/v1/expenses", json={
            "amount": "-50.00",
            "currency": "INR",
            "category": "Food",
            "expense_date": datetime.utcnow().isoformat()
        }, headers=user_a_headers)
        assert bad_exp.status_code == 422

        # Negative budget must fail validation with 422
        bad_bgt = await client.post("/api/v1/budgets", json={
            "amount": "0.00",
            "period": "monthly"
        }, headers=user_a_headers)
        assert bad_bgt.status_code == 422

@pytest.mark.asyncio
async def test_habit_streak_broken_by_missed_day():
    from app.services.wellness_service import wellness_service
    from app.models.wellness import Habit, HabitLog

    today = date(2026, 10, 7)
    h = Habit(
        id="hbt_streak_test",
        user_id="u_streak",
        name="Study",
        frequency="Daily",
        start_date=datetime(2026, 10, 1)
    )

    # Day 0 (today): completed
    # Day 1 (yesterday, Oct 6): missed!
    # Day 2 (Oct 5): completed
    # Day 3 (Oct 4): completed
    logs = [
        HabitLog(id="l0", habit_id=h.id, user_id=h.user_id, log_date="2026-10-07", status="Completed"),
        HabitLog(id="l1", habit_id=h.id, user_id=h.user_id, log_date="2026-10-06", status="Missed"),
        HabitLog(id="l2", habit_id=h.id, user_id=h.user_id, log_date="2026-10-05", status="Completed"),
        HabitLog(id="l3", habit_id=h.id, user_id=h.user_id, log_date="2026-10-04", status="Completed"),
    ]

    metrics = wellness_service.calculate_habit_metrics(h, logs, reference_date=today)
    # Current streak must be exactly 1 because yesterday was missed (truthful calculation)
    assert metrics["current_streak"] == 1
    # Longest streak was 2 (Oct 4 and Oct 5)
    assert metrics["longest_streak"] == 2
    assert metrics["completed_today"] is True

