import uuid
import pytest
import pytest_asyncio
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
def auth_headers():
    uid = f"user_p9_{uuid.uuid4().hex[:8]}"
    token = create_access_token(subject=uid)
    return uid, {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_health_check_phase9():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] in ["healthy", "ok"]
        assert "Phase 9" in data["phase"]
        assert data["service"] == "OmniXPERIENCE API"

@pytest.mark.asyncio
async def test_privacy_policy_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Public /privacy endpoint
        resp = await client.get("/privacy")
        assert resp.status_code == 200
        assert "text/html" in resp.headers["content-type"]
        assert "OmniXPERIENCE Privacy Policy" in resp.text
        assert "Account Deletion" in resp.text

        # API /api/v1/privacy endpoint
        resp_api = await client.get("/api/v1/privacy")
        assert resp_api.status_code == 200
        assert "text/html" in resp_api.headers["content-type"]
        assert "OmniXPERIENCE Privacy Policy" in resp_api.text

@pytest.mark.asyncio
async def test_notification_preferences_flow(auth_headers):
    uid, headers = auth_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Get default notification preferences
        get_res = await client.get("/api/v1/profile/notifications", headers=headers)
        assert get_res.status_code == 200
        prefs = get_res.json()
        assert prefs.get("deadlines") is True
        assert prefs.get("budget") is True
        assert prefs.get("habits") is True
        assert prefs.get("conflicts") is True
        assert prefs.get("weather") is True

        # 2. Update notification preferences
        update_res = await client.put(
            "/api/v1/profile/notifications",
            headers=headers,
            json={"deadlines": False, "weather": False}
        )
        assert update_res.status_code == 200
        updated = update_res.json()
        assert updated["deadlines"] is False
        assert updated["weather"] is False
        assert updated["budget"] is True

        # 3. Verify persistence
        verify_res = await client.get("/api/v1/profile/notifications", headers=headers)
        assert verify_res.status_code == 200
        v_data = verify_res.json()
        assert v_data["deadlines"] is False
        assert v_data["weather"] is False
        assert v_data["conflicts"] is True

@pytest.mark.asyncio
async def test_account_cascade_deletion(auth_headers):
    uid, headers = auth_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Seed some user data: profile, a task, an expense
        prof_res = await client.put(
            "/api/v1/profile",
            headers=headers,
            json={"display_name": "Test User To Delete", "age": 28}
        )
        assert prof_res.status_code == 200

        task_res = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Temporary Task", "priority": "High"}
        )
        assert task_res.status_code in [200, 201]

        expense_res = await client.post(
            "/api/v1/expenses",
            headers=headers,
            json={
                "amount": "250.00",
                "currency": "INR",
                "category": "Food",
                "description": "Lunch",
                "expense_date": "2026-10-07T12:00:00"
            }
        )
        assert expense_res.status_code in [200, 201]

        # Verify task is present
        tasks_list = await client.get("/api/v1/tasks", headers=headers)
        assert len(tasks_list.json()) >= 1

        # 2. Perform complete account cascade deletion
        del_res = await client.delete("/api/v1/auth/me", headers=headers)
        assert del_res.status_code == 200
        del_data = del_res.json()
        assert del_data["status"] == "success"
        assert "permanently deleted" in del_data["message"]

        # 3. Subsequent get_me should return 404 (user does not exist)
        me_res = await client.get("/api/v1/auth/me", headers=headers)
        assert me_res.status_code == 404

        # 4. Subsequent queries should show zero data for this user
        tasks_after = await client.get("/api/v1/tasks", headers=headers)
        assert len(tasks_after.json()) == 0

        exp_after = await client.get("/api/v1/expenses", headers=headers)
        assert len(exp_after.json()) == 0
