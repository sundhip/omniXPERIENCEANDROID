from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

Base = declarative_base()

def run_migrations(sync_conn):
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
            ("primary_style", "VARCHAR(50)"),
            ("secondary_styles", "JSON"),
            ("primary_fit", "VARCHAR(50)"),
            ("secondary_fit", "VARCHAR(50)"),
            ("neutral_colors", "JSON"),
            ("colors_to_experiment", "JSON"),
            ("color_experimentation_score", "FLOAT DEFAULT 0.5"),
            ("experimentation_score", "FLOAT DEFAULT 0.5"),
            ("comfort_appearance_score", "FLOAT DEFAULT 0.5"),
            ("top_occasions", "JSON"),
            ("occasion_frequencies", "JSON"),
            ("fashion_priorities_ranked", "JSON"),
            ("fashion_priority_weights", "JSON"),
            ("preferred_brands", "JSON"),
            ("avoided_brands", "JSON"),
            ("budget_tier", "VARCHAR(50)"),
            ("personal_style_profile", "JSON"),
            ("personalization_version", "INTEGER DEFAULT 1"),
        ]
        for col_name, col_type in new_pref_cols:
            if col_name not in pref_cols:
                try:
                    sync_conn.execute(sa.text(f"ALTER TABLE preferences ADD COLUMN {col_name} {col_type}"))
                except Exception:
                    pass

    # Ensure any new tables like visual_profiles are created
    Base.metadata.create_all(bind=sync_conn)

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
