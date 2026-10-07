import pytest
import pytest_asyncio
import uuid
from datetime import datetime, timedelta
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.models.database import engine, run_migrations
from app.core.security import create_access_token

@pytest_asyncio.fixture(scope="module", autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(run_migrations)
    yield

@pytest.fixture
def user_a_headers():
    uid = f"user_p7_a_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def user_b_headers():
    uid = f"user_p7_b_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_learning_items_crud_and_hierarchy(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Create parent subject (e.g. Data Structures)
        res_parent = await client.post("/api/v1/learning", json={
            "title": "Data Structures & Algorithms",
            "type": "subject",
            "category": "Academic",
            "priority": "High",
            "progress": 20.0
        }, headers=user_a_headers)
        assert res_parent.status_code == 201, res_parent.text
        parent = res_parent.json()
        assert parent["title"] == "Data Structures & Algorithms"

        # 2. Create child module (e.g. Trees)
        res_child = await client.post("/api/v1/learning", json={
            "title": "Trees & Binary Search Trees",
            "type": "topic",
            "category": "Academic",
            "priority": "Urgent",
            "parent_id": parent["id"],
            "progress": 50.0
        }, headers=user_a_headers)
        assert res_child.status_code == 201, res_child.text
        child = res_child.json()
        assert child["parent_id"] == parent["id"]

        # 3. List with parent filter
        res_list = await client.get(f"/api/v1/learning?parent_id={parent['id']}", headers=user_a_headers)
        assert res_list.status_code == 200
        children = res_list.json()
        assert len(children) == 1
        assert children[0]["id"] == child["id"]

        # 4. Multi-tenant isolation: User B cannot see User A's learning item (returns 404)
        res_iso = await client.get(f"/api/v1/learning/{child['id']}", headers=user_b_headers)
        assert res_iso.status_code == 404

        # 5. Update progress to 100 -> auto completes
        res_up = await client.put(f"/api/v1/learning/{child['id']}", json={
            "progress": 100.0
        }, headers=user_a_headers)
        assert res_up.status_code == 200
        assert res_up.json()["status"] == "Completed"

@pytest.mark.asyncio
async def test_goals_milestones_and_progress_calculation(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Create goal with 3 milestones
        target = (datetime.utcnow() + timedelta(days=20)).isoformat()
        res_goal = await client.post("/api/v1/goals", json={
            "title": "Build Flutter AI App",
            "category": "Project",
            "priority": "High",
            "target_date": target,
            "milestones": [
                {"title": "Design UI components", "completed": False},
                {"title": "Implement state management", "completed": False},
                {"title": "Deploy test build", "completed": False}
            ]
        }, headers=user_a_headers)
        assert res_goal.status_code == 201, res_goal.text
        goal = res_goal.json()
        assert len(goal["milestones"]) == 3
        assert goal["progress"] == 0.0

        m1_id = goal["milestones"][0]["id"]
        m2_id = goal["milestones"][1]["id"]
        m3_id = goal["milestones"][2]["id"]

        # 2. Toggle milestone 1 -> progress is 33.3%
        res_t1 = await client.post(f"/api/v1/goals/{goal['id']}/milestones/{m1_id}/toggle", headers=user_a_headers)
        assert res_t1.status_code == 200
        assert round(res_t1.json()["progress"], 1) == 33.3
        assert res_t1.json()["status"] == "Active"

        # 3. Toggle milestone 2 -> 66.7%
        res_t2 = await client.post(f"/api/v1/goals/{goal['id']}/milestones/{m2_id}/toggle", headers=user_a_headers)
        assert res_t2.status_code == 200
        assert round(res_t2.json()["progress"], 1) == 66.7

        # 4. Toggle milestone 3 -> 100% and auto-completes
        res_t3 = await client.post(f"/api/v1/goals/{goal['id']}/milestones/{m3_id}/toggle", headers=user_a_headers)
        assert res_t3.status_code == 200
        assert res_t3.json()["progress"] == 100.0
        assert res_t3.json()["status"] == "Completed"

        # 5. User B access isolation
        res_iso = await client.get(f"/api/v1/goals/{goal['id']}", headers=user_b_headers)
        assert res_iso.status_code == 404

@pytest.mark.asyncio
async def test_goal_planning_service_feasibility_and_conflicts(user_a_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Create an ambitious goal with tight deadline (3 days away)
        target = (datetime.utcnow() + timedelta(days=3)).isoformat()
        res_goal = await client.post("/api/v1/goals", json={
            "title": "Master Distributed Systems",
            "category": "Academic",
            "priority": "Urgent",
            "target_date": target,
            "progress": 0.0
        }, headers=user_a_headers)
        assert res_goal.status_code == 201
        goal = res_goal.json()

        # Call AI Goal Planner endpoint
        res_plan = await client.post(f"/api/v1/goals/{goal['id']}/plan", headers=user_a_headers)
        assert res_plan.status_code == 200
        plan = res_plan.json()
        assert plan["goal_id"] == goal["id"]
        assert plan["weekly_hours_required"] > 0
        assert len(plan["suggested_milestones"]) >= 4
        assert "recommended_next_action" in plan
        assert "rationale" in plan
        # Due to 3 days remaining and 30 estimated base hours, status should be Unrealistic (>25 hrs/wk)
        assert plan["deadline_status"] == "Unrealistic"
        assert plan["feasible"] is False

@pytest.mark.asyncio
async def test_study_sessions_and_dashboard(user_a_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Log a study session
        res_sess = await client.post("/api/v1/study-sessions", json={
            "title": "Graph Algorithms Deep Dive",
            "session_type": "Study",
            "planned_duration_minutes": 60,
            "actual_duration_minutes": 55,
            "status": "Completed",
            "notes": "Reviewed Dijkstra and Floyd-Warshall"
        }, headers=user_a_headers)
        assert res_sess.status_code == 201
        sess = res_sess.json()
        assert sess["actual_duration_minutes"] == 55

        # 2. Query Dashboard
        res_dash = await client.get("/api/v1/learning/dashboard", headers=user_a_headers)
        assert res_dash.status_code == 200
        dash = res_dash.json()
        assert "today_learning" in dash
        assert "upcoming_deadlines" in dash
        assert "insights" in dash
        assert dash["total_study_minutes_this_week"] >= 55

@pytest.mark.asyncio
async def test_knowledge_notes_and_search(user_a_headers, user_b_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Create a note
        res_note = await client.post("/api/v1/notes", json={
            "title": "Quantum Computing Basics",
            "content": "Superposition and entanglement are fundamental concepts.",
            "tags": ["physics", "computing"],
            "linked_entity_type": "general"
        }, headers=user_a_headers)
        assert res_note.status_code == 201
        note = res_note.json()

        # 2. Search note by keyword
        res_search = await client.get("/api/v1/notes?search=superposition", headers=user_a_headers)
        assert res_search.status_code == 200
        results = res_search.json()
        assert len(results) == 1
        assert results[0]["id"] == note["id"]

        # 3. User B search returns empty
        res_b = await client.get("/api/v1/notes?search=superposition", headers=user_b_headers)
        assert res_b.status_code == 200
        assert len(res_b.json()) == 0

@pytest.mark.asyncio
async def test_priority_engine_and_projects(user_a_headers):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Create a personal project
        target = (datetime.utcnow() + timedelta(days=2)).isoformat()
        res_proj = await client.post("/api/v1/projects", json={
            "title": "Autonomous Drone Platform",
            "category": "Development",
            "priority": "Urgent",
            "target_date": target,
            "progress": 10.0
        }, headers=user_a_headers)
        assert res_proj.status_code == 201
        proj = res_proj.json()

        # Calculate Priority Score
        res_prio = await client.get(f"/api/v1/projects/{proj['id']}/priority", headers=user_a_headers)
        assert res_prio.status_code == 200
        prio = res_prio.json()
        assert prio["priority_level"] in ["Urgent", "High"]
        assert prio["score"] >= 70.0
        assert "Priority Score" in prio["rationale"]
