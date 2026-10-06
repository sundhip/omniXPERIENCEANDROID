import pytest
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models.database import engine, Base

@pytest.mark.asyncio
async def test_profile_phase1_full_flow_and_isolation():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Register User A
        email_a = f"user_a_{uuid.uuid4().hex[:6]}@example.com"
        res_a = await ac.post("/api/v1/auth/register", json={
            "email": email_a,
            "password": "Password123!",
            "display_name": "Alice User"
        })
        assert res_a.status_code == 200
        token_a = res_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # 2. Register User B
        email_b = f"user_b_{uuid.uuid4().hex[:6]}@example.com"
        res_b = await ac.post("/api/v1/auth/register", json={
            "email": email_b,
            "password": "Password123!",
            "display_name": "Bob User"
        })
        assert res_b.status_code == 200
        token_b = res_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # 3. User A gets initial full profile
        prof_a_res = await ac.get("/api/v1/profile/full", headers=headers_a)
        assert prof_a_res.status_code == 200
        prof_a_data = prof_a_res.json()
        assert prof_a_data["display_name"] == "Alice User"
        assert prof_a_data["email"] == email_a
        assert prof_a_data["onboarding_completed"] is False

        # 4. User A updates full profile with all Phase 1 attributes
        update_payload_a = {
            "display_name": "Alice Designer",
            "age": 28,
            "gender": "Female",
            "location": "San Francisco, CA",
            "height_cm": 168.0,
            "weight_kg": 58.5,
            "body_type": "athletic",
            "onboarding_completed": True,
            "style_preferences": ["Minimal", "Smart Casual", "Classic"],
            "fit_preference": "Relaxed",
            "preferred_colors": ["#1E3A8A", "#FFFFFF", "#000000"],
            "disliked_colors": ["#FFFF00"],
            "occasions": ["office", "casual_outing", "dinner"],
            "lifestyle": ["work", "gym", "travel"],
            "priorities": {
                "comfort": 0.8,
                "appearance": 0.9,
                "practicality": 0.7,
                "formality": 0.5
            },
            "ai_personalization_enabled": True
        }
        update_res_a = await ac.put("/api/v1/profile/full", headers=headers_a, json=update_payload_a)
        assert update_res_a.status_code == 200
        updated_a = update_res_a.json()
        assert updated_a["display_name"] == "Alice Designer"
        assert updated_a["age"] == 28
        assert updated_a["height_cm"] == 168.0
        assert updated_a["weight_kg"] == 58.5
        assert updated_a["body_type"] == "athletic"
        assert updated_a["onboarding_completed"] is True
        assert "Classic" in updated_a["style_preferences"]
        assert updated_a["fit_preference"] == "Relaxed"
        assert "#1E3A8A" in updated_a["preferred_colors"]
        assert "#FFFF00" in updated_a["disliked_colors"]
        assert "office" in updated_a["occasions"]
        assert "travel" in updated_a["lifestyle"]
        assert updated_a["priorities"]["appearance"] == 0.9

        # 5. Fetch User A profile again to ensure database persistence
        fetch_a = await ac.get("/api/v1/profile/full", headers=headers_a)
        assert fetch_a.status_code == 200
        assert fetch_a.json()["display_name"] == "Alice Designer"
        assert fetch_a.json()["priorities"]["comfort"] == 0.8

        # 6. Strict Data Isolation: User B requests profile
        prof_b_res = await ac.get("/api/v1/profile/full", headers=headers_b)
        assert prof_b_res.status_code == 200
        prof_b_data = prof_b_res.json()
        # User B must NOT have Alice's data
        assert prof_b_data["display_name"] == "Bob User"
        assert prof_b_data["email"] == email_b
        assert prof_b_data["age"] is None
        assert prof_b_data["height_cm"] is None
        assert prof_b_data["onboarding_completed"] is False
        assert prof_b_data["user_id"] != updated_a["user_id"]

        # 7. User B updates their own profile
        update_b = await ac.put("/api/v1/profile/full", headers=headers_b, json={
            "display_name": "Bob Builder",
            "age": 35,
            "body_type": "broad",
            "style_preferences": ["Streetwear"],
            "fit_preference": "Oversized"
        })
        assert update_b.status_code == 200
        assert update_b.json()["display_name"] == "Bob Builder"
        assert update_b.json()["body_type"] == "broad"

        # 8. Verify Alice's profile was completely unaffected
        verify_a = await ac.get("/api/v1/profile/full", headers=headers_a)
        assert verify_a.status_code == 200
        assert verify_a.json()["display_name"] == "Alice Designer"
        assert verify_a.json()["body_type"] == "athletic"
        assert verify_a.json()["fit_preference"] == "Relaxed"
