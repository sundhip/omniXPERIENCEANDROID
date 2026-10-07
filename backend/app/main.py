import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from contextlib import asynccontextmanager
from app.core.config import settings
from app.models.database import engine, Base, run_migrations
from app.api.v1.api import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(run_migrations)
    yield

app = FastAPI(
    title="OmniXPERIENCE API",
    version="1.0.0",
    description="OmniXPERIENCE Personal AI & Life OS - Production API",
    lifespan=lifespan
)

# Production Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    return response

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

static_path = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")

@app.get("/", response_class=HTMLResponse)
@app.get("/app", response_class=HTMLResponse)
async def serve_app():
    index_file = os.path.join(static_path, "index.html")
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse("<h1>OmniXPERIENCE API Server Running</h1><p><a href='/docs'>Swagger API Docs</a></p>")

@app.get("/privacy", response_class=HTMLResponse)
@app.get("/api/v1/privacy", response_class=HTMLResponse)
async def privacy_policy():
    return HTMLResponse("""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>OmniXPERIENCE Privacy Policy</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #222; }
            h1 { color: #111; }
            h2 { color: #333; margin-top: 28px; }
            code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; }
        </style>
    </head>
    <body>
        <h1>OmniXPERIENCE Privacy Policy</h1>
        <p><strong>Effective Date:</strong> October 2026 | <strong>Version:</strong> 1.0.0</p>
        
        <h2>1. Data Minimization & Purpose</h2>
        <p>OmniXPERIENCE operates as a personal life operating system. We collect and process user data exclusively to power on-device intelligence, schedule assistance, personal finance calculations, and style recommendations.</p>
        
        <h2>2. Visual & Computer Vision Data</h2>
        <p>Images uploaded for wardrobe and personal style analysis are securely stored in user-scoped partitions. Facial landmarks and geometry vectors are used strictly to provide personal fashion recommendations.</p>
        
        <h2>3. Financial & Health/Wellness Information</h2>
        <p>All expense logs and habit tracking records are processed with deterministic algorithms and remain strictly confidential. We never monetize, sell, or disclose personal finance or wellness data.</p>
        
        <h2>4. User Rights & Complete Account Deletion</h2>
        <p>In full compliance with Google Play Store User Data Policies, users have the absolute right to delete their account and all associated personal data permanently. This can be triggered directly in the app profile settings or programmatically via the <code>DELETE /api/v1/auth/me</code> endpoint.</p>
    </body>
    </html>
    """)

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "OmniXPERIENCE API",
        "phase": "Phase 9 - Final Intelligence & Production Hardening",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
