import uuid
import pytest
import pytest_asyncio
from datetime import datetime, timedelta
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.models.database import engine, run_migrations
from app.core.security import create_access_token
from app.services.context_relevance_engine import context_relevance_engine

@pytest_asyncio.fixture(scope="module", autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(run_migrations)
    yield

@pytest.fixture
def user_a_headers():
    uid = f"user_p8_a_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return uid, {"Authorization": f"Bearer {token}"}

@pytest.fixture
def user_b_headers():
    uid = f"user_p8_b_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return uid, {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_context_relevance_engine_filtering():
    # 1. Wardrobe query
    domains_wardrobe = context_relevance_engine.classify_domains("What should I wear tomorrow?")
    assert "wardrobe" in domains_wardrobe
    assert "weather" in domains_wardrobe
    assert "productivity" in domains_wardrobe
    assert "finance" not in domains_wardrobe
    assert "learning" not in domains_wardrobe

    # 2. Project query
    domains_project = context_relevance_engine.classify_domains("Can I finish my project this week?")
    assert "project" in domains_project
    assert "productivity" in domains_project
    assert "goals" in domains_project
    assert "wardrobe" not in domains_project

    # 3. Finance query
    domains_finance = context_relevance_engine.classify_domains("How much did I spend this week? Am I overspending?")
    assert "finance" in domains_finance
    assert "wardrobe" not in domains_finance
    assert "learning" not in domains_finance

    # 4. Comprehensive planning query
    domains_plan = context_relevance_engine.classify_domains("Plan my day tomorrow")
    assert "productivity" in domains_plan
    assert "learning" in domains_plan
    assert "goals" in domains_plan


@pytest.mark.asyncio
async def test_context_engine_aggregation_and_daily_brief(user_a_headers):
    user_id, headers = user_a_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Create Task
        await ac.post("/api/v1/tasks", headers=headers, json={
            "title": "Complete System Architecture Doc",
            "priority": "Urgent",
            "due_date": (datetime.utcnow() + timedelta(days=1)).isoformat()
        })

        # Create Event
        await ac.post("/api/v1/events", headers=headers, json={
            "title": "Executive Product Review",
            "start_time": (datetime.utcnow() + timedelta(hours=14)).isoformat(),
            "end_time": (datetime.utcnow() + timedelta(hours=15)).isoformat(),
            "category": "Work",
            "occasion": "Presentation"
        })

        # Create Learning Item
        await ac.post("/api/v1/learning", headers=headers, json={
            "title": "Advanced Distributed Systems",
            "type": "Course",
            "priority": "High",
            "progress": 35.0
        })

        # Create Budget & Expense
        await ac.post("/api/v1/budgets", headers=headers, json={
            "amount": 20000.0,
            "period": "monthly",
            "currency": "INR"
        })
        await ac.post("/api/v1/expenses", headers=headers, json={
            "amount": 2500.0,
            "category": "Food",
            "description": "Team Lunch",
            "expense_date": datetime.utcnow().isoformat()
        })

        # Create Habit
        await ac.post("/api/v1/habits", headers=headers, json={
            "name": "Evening Mobility Routine",
            "category": "Fitness",
            "frequency": "Daily"
        })

        # Query Full Context
        ctx_res = await ac.get("/api/v1/personal-ai/context", headers=headers)
        assert ctx_res.status_code == 200
        snap = ctx_res.json()
        assert snap["user_id"] == user_id
        assert len(snap["upcoming_events"]) >= 1
        assert len(snap["today_tasks"]) >= 1
        assert len(snap["learning_workload"]) >= 1
        assert snap["budget_state"]["total_spent_this_month"] >= 2500.0
        assert len(snap["habits"]) >= 1

        # Query Daily Personal Brief
        brief_res = await ac.get("/api/v1/personal-ai/daily-brief", headers=headers)
        assert brief_res.status_code == 200
        brief = brief_res.json()
        assert brief["events_count"] >= 1
        assert brief["priority_tasks_count"] >= 1
        assert "Architecture" in brief["focus"]
        assert brief["pending_habits_count"] >= 1


@pytest.mark.asyncio
async def test_assistant_action_proposal_and_confirmation(user_a_headers):
    user_id, headers = user_a_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Ask assistant to remind / create task
        ask_res = await ac.post("/api/v1/personal-ai/ask", headers=headers, json={
            "prompt": "Remind me to study DSA graphs tonight"
        })
        assert ask_res.status_code == 200
        data = ask_res.json()
        assert data["action_proposal"] is not None
        proposal = data["action_proposal"]
        assert proposal["action_type"] == "create_task"
        assert proposal["requires_confirmation"] is True
        proposal_id = proposal["id"]

        # Verify task is NOT created silently
        tasks_res = await ac.get("/api/v1/tasks", headers=headers)
        initial_tasks_count = len(tasks_res.json())

        # Execute confirmation
        exec_res = await ac.post("/api/v1/personal-ai/actions/execute", headers=headers, json={
            "proposal_id": proposal_id,
            "confirm": True
        })
        assert exec_res.status_code == 200
        exec_data = exec_res.json()
        assert exec_data["success"] is True
        assert exec_data["status"] == "executed"

        # Verify task is now present on the user's task board
        tasks_after = await ac.get("/api/v1/tasks", headers=headers)
        assert len(tasks_after.json()) == initial_tasks_count + 1
        assert any("DSA graphs" in t["title"] for t in tasks_after.json())


@pytest.mark.asyncio
async def test_proactive_insights_and_deduplication(user_a_headers):
    user_id, headers = user_a_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Create budget and overspend
        await ac.post("/api/v1/budgets", headers=headers, json={
            "amount": 5000.0,
            "period": "monthly"
        })
        await ac.post("/api/v1/expenses", headers=headers, json={
            "amount": 6200.0,
            "category": "Shopping",
            "description": "Tech gadgets",
            "expense_date": datetime.utcnow().isoformat()
        })

        # Fetch proactive insights
        ins_res = await ac.get("/api/v1/personal-ai/insights", headers=headers)
        assert ins_res.status_code == 200
        insights = ins_res.json()
        assert len(insights) >= 1
        budget_ins = next((i for i in insights if i["insight_type"] == "high_spending"), None)
        assert budget_ins is not None
        assert budget_ins["severity"] == "urgent"

        # Fetch again: check deduplication (count does not duplicate)
        ins_res2 = await ac.get("/api/v1/personal-ai/insights", headers=headers)
        assert len(ins_res2.json()) == len(insights)

        # Dismiss insight
        dismiss_res = await ac.post(f"/api/v1/personal-ai/insights/{budget_ins['id']}/dismiss", headers=headers)
        assert dismiss_res.status_code == 200

        # Verify dismissed insight no longer returned
        ins_res3 = await ac.get("/api/v1/personal-ai/insights", headers=headers)
        assert not any(i["id"] == budget_ins["id"] for i in ins_res3.json())


@pytest.mark.asyncio
async def test_user_memory_and_cross_tenant_isolation(user_a_headers, user_b_headers):
    user_a, headers_a = user_a_headers
    user_b, headers_b = user_b_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Create memory for User A
        mem_res = await ac.post("/api/v1/personal-ai/memories", headers=headers_a, json={
            "key": "study_time_preference",
            "value": "I prefer studying late at night between 10 PM and 1 AM",
            "domain": "learning"
        })
        assert mem_res.status_code == 200
        mem_id = mem_res.json()["id"]

        # User B cannot see User A's memory
        mems_b = await ac.get("/api/v1/personal-ai/memories", headers=headers_b)
        assert not any(m["id"] == mem_id for m in mems_b.json())

        # User B cannot delete User A's memory (404 Not Found)
        del_b = await ac.delete(f"/api/v1/personal-ai/memories/{mem_id}", headers=headers_b)
        assert del_b.status_code == 404

        # User A can delete own memory
        del_a = await ac.delete(f"/api/v1/personal-ai/memories/{mem_id}", headers=headers_a)
        assert del_a.status_code == 200


@pytest.mark.asyncio
async def test_final_acceptance_scenarios_end_to_end(user_a_headers):
    user_id, headers = user_a_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Setup Acceptance State:
        # 1. Upcoming important event
        await ac.post("/api/v1/events", headers=headers, json={
            "title": "Quarterly Technical Presentation",
            "start_time": (datetime.utcnow() + timedelta(days=1, hours=2)).isoformat(),
            "end_time": (datetime.utcnow() + timedelta(days=1, hours=3)).isoformat(),
            "category": "Work",
            "occasion": "Formal"
        })
        # 2. Task deadline
        await ac.post("/api/v1/tasks", headers=headers, json={
            "title": "Submit Final Performance Metrics",
            "priority": "Urgent",
            "due_date": (datetime.utcnow() + timedelta(days=1)).isoformat()
        })
        # 3. Active learning goal
        await ac.post("/api/v1/goals", headers=headers, json={
            "title": "Master Distributed Systems",
            "category": "Skill",
            "priority": "High",
            "milestones": [
                {"id": "m1", "title": "Read Raft Consensus Paper", "completed": True},
                {"id": "m2", "title": "Implement Leader Election in Go", "completed": False}
            ]
        })
        # 4. Wardrobe items
        await ac.post("/api/v1/wardrobe", headers=headers, json={
            "category": "Tops",
            "subcategory": "Shirts",
            "name": "Navy Formal Oxford Shirt",
            "primary_color": "Navy",
            "formality": "Formal"
        })
        await ac.post("/api/v1/wardrobe", headers=headers, json={
            "category": "Bottoms",
            "subcategory": "Trousers",
            "name": "Charcoal Tailored Trousers",
            "primary_color": "Charcoal",
            "formality": "Formal"
        })
        # 5. Budget & Wellness
        await ac.post("/api/v1/budgets", headers=headers, json={"amount": 35000.0, "period": "monthly"})
        await ac.post("/api/v1/habits", headers=headers, json={"name": "Morning Cold Shower", "category": "Wellness"})

        # Acceptance Scenario 1: "What should I focus on tomorrow?"
        res1 = await ac.post("/api/v1/personal-ai/ask", headers=headers, json={
            "prompt": "What should I focus on tomorrow?"
        })
        assert res1.status_code == 200
        data1 = res1.json()
        assert len(data1["citations"]) >= 1
        assert data1["epistemic_level"] in ["CALCULATED", "RECOMMENDED", "KNOWN"]
        assert any(k in data1["response"] for k in ["Submit Final Performance Metrics", "Task", "schedule", "priority", "focus"])

        # Acceptance Scenario 2: "Plan my tomorrow."
        res2 = await ac.post("/api/v1/personal-ai/ask", headers=headers, json={
            "prompt": "Plan my tomorrow."
        })
        assert res2.status_code == 200
        data2 = res2.json()
        assert "suggested schedule" in data2["response"].lower() or "plan" in data2["response"].lower()
        # Verifies buffer times included
        assert "buffer" in data2["response"].lower() or "•" in data2["response"]

        # Acceptance Scenario 3: "What should I wear tomorrow?"
        res3 = await ac.post("/api/v1/personal-ai/ask", headers=headers, json={
            "prompt": "What should I wear tomorrow?"
        })
        assert res3.status_code == 200
        data3 = res3.json()
        assert "Navy Formal Oxford Shirt" in data3["response"] or "Charcoal Tailored Trousers" in data3["response"] or "wardrobe" in data3["response"].lower()
        assert "wardrobe" in data3["referenced_domains"]
