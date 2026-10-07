import pytest
import uuid
from datetime import datetime, timedelta
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models.database import engine, Base, run_migrations

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(run_migrations)

async def create_test_user(client: AsyncClient, prefix: str):
    email = f"{prefix}_{uuid.uuid4().hex[:6]}@example.com"
    res = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": "Password123!",
        "display_name": f"{prefix.capitalize()} User"
    })
    token = res.json()["access_token"]
    user_id = res.json()["user_id"]
    return token, user_id, {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_event_crud_and_validation():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        token, user_id, headers = await create_test_user(client, "evt")

        # Invalid time: end_time before start_time -> 400
        invalid_payload = {
            "title": "Invalid Event",
            "start_time": (datetime.utcnow() + timedelta(hours=2)).isoformat(),
            "end_time": (datetime.utcnow() + timedelta(hours=1)).isoformat(),
            "category": "College",
            "priority": "High"
        }
        res_inv = await client.post("/api/v1/events", json=invalid_payload, headers=headers)
        assert res_inv.status_code == 400

        # Create valid event
        now = datetime.utcnow()
        valid_payload = {
            "title": "DBMS Lecture",
            "description": "Relational algebra and indexing",
            "start_time": (now + timedelta(hours=1)).isoformat(),
            "end_time": (now + timedelta(hours=2)).isoformat(),
            "location": "Auditorium A",
            "category": "College",
            "priority": "High",
            "occasion": "Lecture"
        }
        res_create = await client.post("/api/v1/events", json=valid_payload, headers=headers)
        assert res_create.status_code == 201
        created_event = res_create.json()
        event_id = created_event["id"]
        assert created_event["title"] == "DBMS Lecture"
        assert created_event["user_id"] == user_id

        # Read single
        res_get = await client.get(f"/api/v1/events/{event_id}", headers=headers)
        assert res_get.status_code == 200
        assert res_get.json()["id"] == event_id

        # Update event
        res_upd = await client.put(f"/api/v1/events/{event_id}", json={"location": "Auditorium B"}, headers=headers)
        assert res_upd.status_code == 200
        assert res_upd.json()["location"] == "Auditorium B"

        # List events
        res_list = await client.get("/api/v1/events?category=College", headers=headers)
        assert res_list.status_code == 200
        assert len(res_list.json()) >= 1

        # Delete event
        res_del = await client.delete(f"/api/v1/events/{event_id}", headers=headers)
        assert res_del.status_code == 200

        # Verify 404 after deletion
        res_404 = await client.get(f"/api/v1/events/{event_id}", headers=headers)
        assert res_404.status_code == 404

@pytest.mark.asyncio
async def test_task_crud_and_completion():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        token, user_id, headers = await create_test_user(client, "tsk")

        # Create Task
        due = (datetime.utcnow() + timedelta(days=1)).isoformat()
        task_payload = {
            "title": "Finish Project Report",
            "description": "Include diagrams and metrics",
            "priority": "Urgent",
            "category": "Projects",
            "due_date": due,
            "estimated_duration_minutes": 60
        }
        res_create = await client.post("/api/v1/tasks", json=task_payload, headers=headers)
        assert res_create.status_code == 201
        task_data = res_create.json()
        task_id = task_data["id"]
        assert task_data["status"] == "Todo"
        assert task_data["completed_at"] is None

        # Toggle completion -> Completed
        res_comp = await client.post(f"/api/v1/tasks/{task_id}/complete", headers=headers)
        assert res_comp.status_code == 200
        assert res_comp.json()["status"] == "Completed"
        assert res_comp.json()["completed_at"] is not None

        # Toggle completion -> Revert to Todo
        res_uncomp = await client.post(f"/api/v1/tasks/{task_id}/complete", headers=headers)
        assert res_uncomp.status_code == 200
        assert res_uncomp.json()["status"] == "Todo"
        assert res_uncomp.json()["completed_at"] is None

        # Delete task
        res_del = await client.delete(f"/api/v1/tasks/{task_id}", headers=headers)
        assert res_del.status_code == 200

@pytest.mark.asyncio
async def test_multi_tenant_authorization():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        token_a, user_a, headers_a = await create_test_user(client, "usr_a")
        token_b, user_b, headers_b = await create_test_user(client, "usr_b")

        # User A creates event and task
        ev_payload = {
            "title": "User A Private Event",
            "start_time": (datetime.utcnow() + timedelta(hours=3)).isoformat(),
            "end_time": (datetime.utcnow() + timedelta(hours=4)).isoformat()
        }
        ev_res = await client.post("/api/v1/events", json=ev_payload, headers=headers_a)
        ev_id = ev_res.json()["id"]

        tsk_payload = {
            "title": "User A Private Task",
            "priority": "High"
        }
        tsk_res = await client.post("/api/v1/tasks", json=tsk_payload, headers=headers_a)
        tsk_id = tsk_res.json()["id"]

        # User B attempts to access User A's event -> 404
        assert (await client.get(f"/api/v1/events/{ev_id}", headers=headers_b)).status_code == 404
        assert (await client.put(f"/api/v1/events/{ev_id}", json={"title": "Hacked"}, headers=headers_b)).status_code == 404
        assert (await client.delete(f"/api/v1/events/{ev_id}", headers=headers_b)).status_code == 404

        # User B attempts to access User A's task -> 404
        assert (await client.get(f"/api/v1/tasks/{tsk_id}", headers=headers_b)).status_code == 404
        assert (await client.post(f"/api/v1/tasks/{tsk_id}/complete", headers=headers_b)).status_code == 404
        assert (await client.delete(f"/api/v1/tasks/{tsk_id}", headers=headers_b)).status_code == 404

@pytest.mark.asyncio
async def test_productivity_intelligence_conflicts_and_today():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        token, user_id, headers = await create_test_user(client, "intel")

        now = datetime.utcnow()
        # Create two overlapping events: 10:00-11:30 and 11:00-12:00
        ev1 = {
            "title": "Project Meeting",
            "start_time": (now + timedelta(hours=1)).isoformat(),
            "end_time": (now + timedelta(hours=2, minutes=30)).isoformat(),
            "category": "Work"
        }
        ev2 = {
            "title": "Advisor Discussion",
            "start_time": (now + timedelta(hours=2)).isoformat(),
            "end_time": (now + timedelta(hours=3)).isoformat(),
            "category": "College"
        }
        await client.post("/api/v1/events", json=ev1, headers=headers)
        await client.post("/api/v1/events", json=ev2, headers=headers)

        # Check conflicts endpoint
        res_conf = await client.get("/api/v1/productivity/conflicts", headers=headers)
        assert res_conf.status_code == 200
        conflicts = res_conf.json()
        assert len(conflicts) >= 1
        assert "Schedule conflict" in conflicts[0]["message"]

        # Create Task A and Task B where B depends on A
        res_ta = await client.post("/api/v1/tasks", json={"title": "Primary Research", "priority": "High"}, headers=headers)
        task_a_id = res_ta.json()["id"]

        res_tb = await client.post("/api/v1/tasks", json={
            "title": "Write Conclusion",
            "priority": "High",
            "dependency_task_ids": [task_a_id],
            "estimated_duration_minutes": 45
        }, headers=headers)
        task_b_id = res_tb.json()["id"]

        # Check priority assessment
        res_assess = await client.get("/api/v1/productivity/priority-assessment", headers=headers)
        assert res_assess.status_code == 200
        assess_list = res_assess.json()
        b_assess = next((a for a in assess_list if a["task_id"] == task_b_id), None)
        assert b_assess is not None
        assert b_assess["is_blocked"] is True
        assert task_a_id in b_assess["blocking_task_ids"]

        # Check unified today dashboard
        res_today = await client.get("/api/v1/productivity/today", headers=headers)
        assert res_today.status_code == 200
        today_data = res_today.json()
        assert today_data["total_events"] >= 2
        assert len(today_data["conflicts"]) >= 1
        assert len(today_data["free_blocks"]) >= 1
        assert len(today_data["summary_message"]) > 0
