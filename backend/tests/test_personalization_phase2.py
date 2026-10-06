import pytest
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models.database import engine, Base, run_migrations
from app.services.personalization_service import PersonalizationService

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(run_migrations)

@pytest.mark.asyncio
async def test_personalization_service_math_and_weights():
    await init_db()
    # 1. Priority weights calculation
    priorities = ["comfort", "appearance", "practicality", "trendiness"]
    weights = PersonalizationService.calculate_priority_weights(priorities)
    assert weights["comfort"] == 1.0
    assert weights["appearance"] < 1.0
    assert weights["trendiness"] == 0.20
    assert weights["practicality"] > weights["trendiness"]

    # 2. Experimentation labels
    assert PersonalizationService.get_experimentation_label(0.1) == "Very Safe"
    assert PersonalizationService.get_experimentation_label(0.25) == "Mostly Classic"
    assert PersonalizationService.get_experimentation_label(0.5) == "Balanced"
    assert PersonalizationService.get_experimentation_label(0.75) == "Somewhat Experimental"
    assert PersonalizationService.get_experimentation_label(1.0) == "Very Experimental"

    # 3. Comfort vs Appearance labels
    assert PersonalizationService.get_comfort_appearance_label(0.2) == "Comfort-focused"
    assert PersonalizationService.get_comfort_appearance_label(0.5) == "Balanced (Comfort & Appearance)"
    assert PersonalizationService.get_comfort_appearance_label(0.9) == "Appearance-focused"

    # 4. Deterministic summary text
    summary = PersonalizationService.generate_summary_text(
        primary_style="Smart Casual",
        secondary_styles=["Minimal", "Classic"],
        primary_fit="Relaxed",
        preferred_colors=["#1E3A8A", "#FFFFFF"],
        top_occasions=["Office", "Presentations"],
        comfort_appearance_score=0.3,
        experimentation_score=0.75,
    )
    assert "Smart Casual" in summary
    assert "relaxed" in summary.lower()
    assert "comfort" in summary.lower()
    assert "somewhat experimental" in summary.lower()

@pytest.mark.asyncio
async def test_full_personalization_lifecycle():
    await init_db()
    email = f"personalization_{uuid.uuid4().hex[:6]}@example.com"
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register user
        reg_res = await client.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "display_name": "Personalization Tester"
        })
        assert reg_res.status_code in [200, 201]
        token = reg_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Update full profile with Phase 2 personalization
        payload = {
            "display_name": "Personalization Tester",
            "primary_style": "Smart Casual",
            "secondary_styles": ["Minimal", "Classic"],
            "primary_fit": "Relaxed",
            "secondary_fit": "Regular",
            "preferred_colors": ["#1E3A8A", "#FFFFFF", "#000000"],
            "neutral_colors": ["#6B7280", "#E5E7EB"],
            "disliked_colors": ["#F59E0B"],
            "colors_to_experiment": ["#881337"],
            "color_experimentation_score": 0.65,
            "experimentation_score": 0.75,
            "comfort_appearance_score": 0.40,
            "occasions": ["Office", "College", "Party", "Date"],
            "top_occasions": ["Office", "College", "Party"],
            "occasion_frequencies": {
                "formal": 0.25,
                "casual": 0.90,
                "smart_casual": 0.75,
                "sportswear": 0.50
            },
            "lifestyle": ["Work", "Gym", "Travel"],
            "fashion_priorities_ranked": ["comfort", "appearance", "practicality", "trendiness"],
            "preferred_brands": ["Uniqlo", "Zara"],
            "budget_tier": "Mid-range",
            "onboarding_completed": True
        }

        put_res = await client.put("/api/v1/profile/full", json=payload, headers=headers)
        assert put_res.status_code == 200
        data = put_res.json()

        assert data["primary_style"] == "Smart Casual"
        assert data["primary_fit"] == "Relaxed"
        assert data["secondary_fit"] == "Regular"
        assert data["experimentation_score"] == 0.75
        assert data["comfort_appearance_score"] == 0.40
        assert data["onboarding_completed"] is True
        
        # Verify deterministic personal_style_profile
        psp = data["personal_style_profile"]
        assert psp is not None
        assert psp["version"] == 1
        assert psp["primary_style"] == "Smart Casual"
        assert psp["experimentation"]["label"] == "Somewhat Experimental"
        assert psp["fashion_priority_weights"]["comfort"] == 1.0
        assert "summary_text" in psp
        assert len(psp["summary_text"]) > 20

        # Verify persistence via GET /api/v1/profile/full
        get_res = await client.get("/api/v1/profile/full", headers=headers)
        assert get_res.status_code == 200
        get_data = get_res.json()
        assert get_data["primary_style"] == "Smart Casual"
        assert get_data["personal_style_profile"]["summary_text"] == psp["summary_text"]

@pytest.mark.asyncio
async def test_multi_tenant_personalization_isolation():
    await init_db()
    email_a = f"userA_{uuid.uuid4().hex[:6]}@example.com"
    email_b = f"userB_{uuid.uuid4().hex[:6]}@example.com"
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Register User A
        reg_a = await client.post("/api/v1/auth/register", json={
            "email": email_a,
            "password": "Password123!",
            "display_name": "User Alpha"
        })
        token_a = reg_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # Register User B
        reg_b = await client.post("/api/v1/auth/register", json={
            "email": email_b,
            "password": "Password123!",
            "display_name": "User Beta"
        })
        token_b = reg_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # User A updates
        await client.put("/api/v1/profile/full", json={
            "display_name": "Alpha",
            "primary_style": "Minimal",
            "primary_fit": "Slim"
        }, headers=headers_a)

        # User B updates
        await client.put("/api/v1/profile/full", json={
            "display_name": "Beta",
            "primary_style": "Streetwear",
            "primary_fit": "Oversized"
        }, headers=headers_b)

        # Verify Alpha
        res_a = await client.get("/api/v1/profile/full", headers=headers_a)
        assert res_a.json()["primary_style"] == "Minimal"
        assert res_a.json()["primary_fit"] == "Slim"

        # Verify Beta
        res_b = await client.get("/api/v1/profile/full", headers=headers_b)
        assert res_b.json()["primary_style"] == "Streetwear"
        assert res_b.json()["primary_fit"] == "Oversized"
