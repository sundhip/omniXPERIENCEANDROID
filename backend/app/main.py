import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from contextlib import asynccontextmanager
from app.core.config import settings
from app.models.database import engine, Base
from app.api.v1.api import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
        # Safe migration for existing SQLite/Postgres tables
        def _migrate(sync_conn):
            import sqlalchemy as sa
            inspector = sa.inspect(sync_conn)
            tables = inspector.get_table_names()
            if "profiles" in tables:
                profile_cols = {c["name"] for c in inspector.get_columns("profiles")}
                new_profile_cols = [
                    ("age", "INTEGER"),
                    ("gender", "VARCHAR(50)"),
                    ("location", "VARCHAR(100)"),
                    ("height_cm", "FLOAT"),
                    ("weight_kg", "FLOAT"),
                    ("body_type", "VARCHAR(50)"),
                    ("onboarding_completed", "BOOLEAN DEFAULT 0"),
                ]
                for col_name, col_type in new_profile_cols:
                    if col_name not in profile_cols:
                        try:
                            sync_conn.execute(sa.text(f"ALTER TABLE profiles ADD COLUMN {col_name} {col_type}"))
                        except Exception:
                            pass
            
            if "preferences" in tables:
                pref_cols = {c["name"] for c in inspector.get_columns("preferences")}
                new_pref_cols = [
                    ("occasions", "JSON"),
                    ("lifestyle", "JSON"),
                    ("priorities", "JSON"),
                ]
                for col_name, col_type in new_pref_cols:
                    if col_name not in pref_cols:
                        try:
                            sync_conn.execute(sa.text(f"ALTER TABLE preferences ADD COLUMN {col_name} {col_type}"))
                        except Exception:
                            pass

        await conn.run_sync(_migrate)
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="OmniPresence Intelligent Presence Layer - Phase 1 Core API",
    lifespan=lifespan
)

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
    return HTMLResponse("<h1>OmniPresence API Server Running</h1><p><a href='/docs'>Swagger API Docs</a></p>")

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "OmniPresence API",
        "phase": "Phase 1 - Core Experience",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
