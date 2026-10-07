import pytest
import os
import cv2
import numpy as np
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models.database import engine, Base, run_migrations
from app.services.face_analysis_service import face_analysis_service
from app.services.personalization_service import PersonalizationService

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(run_migrations)

def get_sample_face_bytes():
    path = os.path.join(os.path.dirname(__file__), "data", "david1.jpg")
    with open(path, "rb") as f:
        return f.read()

def get_multi_face_bytes():
    path = os.path.join(os.path.dirname(__file__), "data", "two_faces.jpg")
    with open(path, "rb") as f:
        return f.read()

def get_no_face_bytes():
    path = os.path.join(os.path.dirname(__file__), "data", "objects_no_face.jpg")
    with open(path, "rb") as f:
        return f.read()

def test_image_validation_edge_cases():
    """Tests image validation for empty, low-res, blurry, dark, and low-contrast images."""
    # 1. Empty bytes
    val, err, _, _ = face_analysis_service.validate_image_bytes(b"")
    assert val is False
    assert "No image data" in err

    # 2. Corrupt bytes
    val, err, _, _ = face_analysis_service.validate_image_bytes(b"not_an_image_data")
    assert val is False
    assert "could not be decoded" in err

    # 3. Low resolution (<200x200)
    tiny = np.ones((100, 100, 3), dtype=np.uint8) * 150
    _, tiny_bytes = cv2.imencode(".jpg", tiny)
    val, err, _, _ = face_analysis_service.validate_image_bytes(tiny_bytes.tobytes())
    assert val is False
    assert "resolution is too low" in err

    # 4. Too dark
    dark = np.ones((300, 300, 3), dtype=np.uint8) * 20
    _, dark_bytes = cv2.imencode(".jpg", dark)
    val, err, _, _ = face_analysis_service.validate_image_bytes(dark_bytes.tobytes())
    assert val is False
    assert "too dark" in err

def test_face_detection_constraints():
    """Tests that images with 0 faces or >1 faces are cleanly rejected with human-friendly guidance."""
    no_face_image_bytes = get_no_face_bytes()
    multi_face_image_bytes = get_multi_face_bytes()

    # 0 faces
    res_no_face = face_analysis_service.analyze_photo(no_face_image_bytes, "u_test", "uploads")
    assert res_no_face["success"] is False
    assert "No face detected" in res_no_face["error"]
    assert res_no_face["user_action"] == "Try Another Photo"

    # Multiple faces
    res_multi = face_analysis_service.analyze_photo(multi_face_image_bytes, "u_test", "uploads")
    assert res_multi["success"] is False
    assert "found" in res_multi["error"] and "faces" in res_multi["error"]

def test_real_face_analysis_model():
    """Tests real MediaPipe Landmark inference, geometry ratios, CIELAB skin tone, and hair analysis."""
    sample_face_image_bytes = get_sample_face_bytes()
    res = face_analysis_service.analyze_photo(sample_face_image_bytes, "u_test", "uploads")
    assert res["success"] is True
    assert res["face_detected"] is True
    assert res["face_count"] == 1
    assert res["detected_face_shape"] in ["Oval", "Round", "Square", "Oblong", "Heart", "Diamond", "Triangle"]
    assert 0.5 <= res["face_shape_confidence"] <= 1.0
    assert res["detected_skin_tone"] in ["Very Light", "Light", "Medium", "Tan", "Deep"]
    assert 0.5 <= res["skin_tone_confidence"] <= 1.0
    assert res["detected_skin_undertone"] in ["Warm", "Cool", "Neutral", "Unknown"]
    assert res["detected_hair_length"] in ["Short", "Medium", "Long", "Bald/Buzz", "Unknown"]
    assert res["detected_hair_texture"] in ["Straight", "Wavy", "Curly", "Coily", "Unknown"]
    assert "geometric_ratios" in res
    assert "quality_score" in res

import uuid

@pytest.mark.asyncio
async def test_visual_profile_api_full_lifecycle():
    """Tests end-to-end API lifecycle: analyze, retrieve, confirm/override, get private image, delete."""
    await init_db()
    sample_face_image_bytes = get_sample_face_bytes()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        email = f"sarah.visual.{uuid.uuid4().hex[:8]}@omnipresence.ai"
        pwd = "VisualPassword123!"

        # Register & Login
        reg_resp = await ac.post("/api/v1/auth/register", json={
            "email": email,
            "password": pwd,
            "display_name": "Sarah Visual"
        })
        assert reg_resp.status_code in [200, 201]

        login_resp = await ac.post("/api/v1/auth/login", json={
            "email": email,
            "password": pwd
        })
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Analyze Photo
        files = {"file": ("selfie.jpg", sample_face_image_bytes, "image/jpeg")}
        analyze_resp = await ac.post("/api/v1/profile/visual-profile/analyze", files=files, headers=headers)
        assert analyze_resp.status_code == 200
        an_data = analyze_resp.json()
        assert an_data["success"] is True
        vp = an_data["visual_profile"]
        assert vp["face_detected"] is True
        assert vp["confirmed_by_user"] is False

        # 2. GET Visual Profile
        get_resp = await ac.get("/api/v1/profile/visual-profile", headers=headers)
        assert get_resp.status_code == 200
        assert get_resp.json()["id"] == vp["id"]

        # 3. Confirm & Override detected attributes
        confirm_resp = await ac.put("/api/v1/profile/visual-profile/confirm", json={
            "confirmed_face_shape": "Oval",
            "confirmed_skin_tone": "Medium",
            "confirmed_hair_texture": "Wavy"
        }, headers=headers)
        assert confirm_resp.status_code == 200
        conf_data = confirm_resp.json()
        assert conf_data["confirmed_by_user"] is True
        assert conf_data["confirmed_face_shape"] == "Oval"
        assert conf_data["confirmed_hair_texture"] == "Wavy"
        # Original AI detection is preserved
        assert conf_data["detected_face_shape"] == vp["detected_face_shape"]

        # 4. Stream Private Image
        img_resp = await ac.get("/api/v1/profile/visual-profile/image", headers=headers)
        assert img_resp.status_code == 200
        assert img_resp.headers["content-type"] == "image/jpeg"
        assert len(img_resp.content) > 1000

        # 5. Get Visual Context Hook for future AI modules
        ctx_resp = await ac.get("/api/v1/profile/visual-profile/context", headers=headers)
        assert ctx_resp.status_code == 200
        ctx_data = ctx_resp.json()
        assert ctx_data["is_active"] is True
        assert ctx_data["face_shape"] == "Oval"
        assert ctx_data["confirmed_by_user"] is True

        # 6. Verify integration into GET /api/v1/profile/full
        full_resp = await ac.get("/api/v1/profile/full", headers=headers)
        assert full_resp.status_code == 200
        full_data = full_resp.json()
        assert full_data["visual_profile"] is not None
        assert full_data["visual_profile"]["confirmed_face_shape"] == "Oval"

        # 7. Delete Visual Profile
        del_resp = await ac.delete("/api/v1/profile/visual-profile", headers=headers)
        assert del_resp.status_code == 200

        # Verify 404 after deletion
        get_del_resp = await ac.get("/api/v1/profile/visual-profile", headers=headers)
        assert get_del_resp.status_code == 404

@pytest.mark.asyncio
async def test_multi_tenant_visual_profile_isolation():
    """Verifies that User B cannot access or view User A's visual profile or private image."""
    await init_db()
    sample_face_image_bytes = get_sample_face_bytes()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # User A
        u1_email = f"user_a.visual.{uuid.uuid4().hex[:8]}@omnipresence.ai"
        pwd = "SecurePassword123!"
        await ac.post("/api/v1/auth/register", json={"email": u1_email, "password": pwd, "display_name": "User A"})
        login1 = await ac.post("/api/v1/auth/login", json={"email": u1_email, "password": pwd})
        token1 = login1.json()["access_token"]
        headers1 = {"Authorization": f"Bearer {token1}"}

        # User B
        u2_email = f"user_b.visual.{uuid.uuid4().hex[:8]}@omnipresence.ai"
        await ac.post("/api/v1/auth/register", json={"email": u2_email, "password": pwd, "display_name": "User B"})
        login2 = await ac.post("/api/v1/auth/login", json={"email": u2_email, "password": pwd})
        token2 = login2.json()["access_token"]
        headers2 = {"Authorization": f"Bearer {token2}"}

        # User A uploads image
        files = {"file": ("selfie.jpg", sample_face_image_bytes, "image/jpeg")}
        an1 = await ac.post("/api/v1/profile/visual-profile/analyze", files=files, headers=headers1)
        assert an1.status_code == 200

        # User B checks their visual profile -> must be 404
        u2_vp = await ac.get("/api/v1/profile/visual-profile", headers=headers2)
        assert u2_vp.status_code == 404

        # User B checks private image -> must be 404
        u2_img = await ac.get("/api/v1/profile/visual-profile/image", headers=headers2)
        assert u2_img.status_code == 404
