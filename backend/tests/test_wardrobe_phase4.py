import pytest
import uuid
import os
import cv2
import numpy as np
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.models.database import engine, Base, run_migrations
from app.services.clothing_ai_service import clothing_ai_service

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(run_migrations)

def create_synthetic_garment_image(color=(30, 40, 180), pattern="solid", width=300, height=360):
    """Generates synthetic clothing photo with realistic garment ROI and background."""
    img = np.ones((height, width, 3), dtype=np.uint8) * 235 # Light grey studio background
    
    # Draw garment torso / clothing region
    pts = np.array([
        [int(width * 0.2), int(height * 0.2)],
        [int(width * 0.8), int(height * 0.2)],
        [int(width * 0.88), int(height * 0.85)],
        [int(width * 0.12), int(height * 0.85)],
    ], np.int32)
    cv2.fillPoly(img, [pts], color)
    
    if pattern == "striped":
        for y in range(int(height * 0.25), int(height * 0.8), 20):
            cv2.line(img, (int(width * 0.15), y), (int(width * 0.85), y), (255, 255, 255), 4)

    _, encoded = cv2.imencode(".jpg", img)
    return encoded.tobytes()

@pytest.mark.asyncio
async def test_clothing_ai_service_unit():
    """Validates real computer vision analysis directly on service."""
    # Test valid image (Navy Blue T-Shirt)
    blue_bytes = create_synthetic_garment_image(color=(160, 50, 20), pattern="solid") # BGR -> Blue
    val, err, _, stats = clothing_ai_service.validate_image(blue_bytes)
    assert val is True
    assert err is None
    assert stats["width"] == 300
    assert stats["height"] == 360

    # Test invalid blurry/dark image
    dark_arr = np.zeros((200, 200, 3), dtype=np.uint8)
    _, dark_encoded = cv2.imencode(".jpg", dark_arr)
    val_dark, err_dark, guidance, _ = clothing_ai_service.validate_image(dark_encoded.tobytes())
    assert val_dark is False
    assert "dark" in err_dark.lower()
    assert guidance is not None

    # Test corrupted bytes
    val_corrupt, err_corrupt, _, _ = clothing_ai_service.validate_image(b"not_an_image")
    assert val_corrupt is False

@pytest.mark.asyncio
async def test_wardrobe_categories_endpoint():
    await init_db()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        res = await ac.get("/api/v1/wardrobe/categories")
        assert res.status_code == 200
        data = res.json()
        assert "categories" in data
        assert "Tops" in data["categories"]
        assert "Bottoms" in data["categories"]
        assert "formalities" in data
        assert "colors" in data
        assert "patterns" in data

@pytest.mark.asyncio
async def test_wardrobe_crud_and_multi_tenant_isolation():
    await init_db()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Register User A
        email_a = f"wardrobe_a_{uuid.uuid4().hex[:6]}@example.com"
        res_a = await ac.post("/api/v1/auth/register", json={
            "email": email_a,
            "password": "Password123!",
            "display_name": "Alice Wardrobe"
        })
        token_a = res_a.json()["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # Register User B
        email_b = f"wardrobe_b_{uuid.uuid4().hex[:6]}@example.com"
        res_b = await ac.post("/api/v1/auth/register", json={
            "email": email_b,
            "password": "Password123!",
            "display_name": "Bob Wardrobe"
        })
        token_b = res_b.json()["access_token"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # 1. User A adds Item A1
        item_a1_payload = {
            "name": "Navy Oxford Shirt",
            "category": "Tops",
            "subcategory": "Shirt",
            "primary_color": "Navy",
            "secondary_colors": ["White"],
            "pattern": "Solid",
            "formality": "Smart Casual",
            "fit": "Regular",
            "brand": "Brooks Brothers",
            "purchase_price": 95.0,
            "currency": "USD",
            "season_tags": ["Spring", "Fall"],
            "occasion_tags": ["Office", "Dinner"],
            "favorite": True,
            "ai_analyzed": True,
            "ai_confidence": 0.94
        }
        create_res_a = await ac.post("/api/v1/wardrobe", json=item_a1_payload, headers=headers_a)
        assert create_res_a.status_code == 200
        item_a1 = create_res_a.json()
        item_a1_id = item_a1["id"]
        assert item_a1["name"] == "Navy Oxford Shirt"
        assert item_a1["favorite"] is True
        assert item_a1["primary_color"] == "Navy"

        # 2. User B adds Item B1
        item_b1_payload = {
            "name": "Black Denim Jeans",
            "category": "Bottoms",
            "subcategory": "Jeans",
            "primary_color": "Black",
            "secondary_colors": [],
            "pattern": "Solid",
            "formality": "Casual",
            "purchase_price": 75.0,
            "favorite": False
        }
        create_res_b = await ac.post("/api/v1/wardrobe", json=item_b1_payload, headers=headers_b)
        assert create_res_b.status_code == 200
        item_b1_id = create_res_b.json()["id"]

        # 3. User A lists wardrobe -> sees only Item A1, NOT Item B1
        list_a = await ac.get("/api/v1/wardrobe", headers=headers_a)
        assert list_a.status_code == 200
        items_a = list_a.json()
        assert len(items_a) == 1
        assert items_a[0]["id"] == item_a1_id

        # 4. User B lists wardrobe -> sees only Item B1, NOT Item A1
        list_b = await ac.get("/api/v1/wardrobe", headers=headers_b)
        assert list_b.status_code == 200
        items_b = list_b.json()
        assert len(items_b) == 1
        assert items_b[0]["id"] == item_b1_id

        # 5. User B tries to view User A's item -> 404 forbidden/not found
        sec_get = await ac.get(f"/api/v1/wardrobe/{item_a1_id}", headers=headers_b)
        assert sec_get.status_code == 404

        # 6. User B tries to update User A's item -> 404
        sec_put = await ac.put(f"/api/v1/wardrobe/{item_a1_id}", json={"name": "Hacked Shirt"}, headers=headers_b)
        assert sec_put.status_code == 404

        # 7. User B tries to toggle favorite on User A's item -> 404
        sec_fav = await ac.post(f"/api/v1/wardrobe/{item_a1_id}/favorite", headers=headers_b)
        assert sec_fav.status_code == 404

        # 8. User B tries to delete User A's item -> 404
        sec_del = await ac.delete(f"/api/v1/wardrobe/{item_a1_id}", headers=headers_b)
        assert sec_del.status_code == 404

        # 9. User A toggles favorite on their own item
        fav_res = await ac.post(f"/api/v1/wardrobe/{item_a1_id}/favorite", headers=headers_a)
        assert fav_res.status_code == 200
        assert fav_res.json()["favorite"] is False

        # 10. User A filters by category and search
        search_res = await ac.get("/api/v1/wardrobe?search=Oxford", headers=headers_a)
        assert search_res.status_code == 200
        assert len(search_res.json()) == 1

        search_empty = await ac.get("/api/v1/wardrobe?search=Jeans", headers=headers_a)
        assert search_empty.status_code == 200
        assert len(search_empty.json()) == 0

        # 11. User A deletes their own item
        del_res = await ac.delete(f"/api/v1/wardrobe/{item_a1_id}?permanent=true", headers=headers_a)
        assert del_res.status_code == 200
        check_del = await ac.get(f"/api/v1/wardrobe/{item_a1_id}", headers=headers_a)
        assert check_del.status_code == 404

@pytest.mark.asyncio
async def test_clothing_ai_photo_analysis_api():
    await init_db()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        email = f"ai_user_{uuid.uuid4().hex[:6]}@example.com"
        reg = await ac.post("/api/v1/auth/register", json={
            "email": email,
            "password": "Password123!",
            "display_name": "AI Wardrobe User"
        })
        token = reg.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Create valid garment image (Red Shirt)
        # BGR (30, 30, 210) -> Red
        red_img_bytes = create_synthetic_garment_image(color=(30, 30, 210), pattern="solid", width=320, height=380)

        # Send to /api/v1/wardrobe/analyze
        files = {"file": ("shirt.jpg", red_img_bytes, "image/jpeg")}
        data = {"context_hint": "Casual red summer tee", "user_size": "L"}

        analyze_res = await ac.post("/api/v1/wardrobe/analyze", files=files, data=data, headers=headers)
        assert analyze_res.status_code == 200
        res_json = analyze_res.json()
        assert res_json["success"] is True
        assert res_json["primary_color"] == "Red"
        assert res_json["category"] in ["Tops", "Outerwear"]
        assert res_json["confidence"] > 0.70
        assert "image_url" in res_json
        assert "thumbnail_url" in res_json
        assert res_json["ai_model"] == "OmniVision-Fashion-CV"
        assert res_json["pattern"] == "Solid"

        # Check that generated media is streamable by authenticated user
        media_url = res_json["image_url"]
        media_res = await ac.get(media_url, headers=headers)
        assert media_res.status_code == 200
        assert media_res.headers["content-type"] == "image/jpeg"
