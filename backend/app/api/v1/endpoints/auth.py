from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
import uuid
from datetime import datetime

from app.models.database import get_db
from app.models.user import User, Profile, Preference, VisualProfile
from app.models.wardrobe import WardrobeItem
from app.models.wear_event import WearEvent
from app.models.outfit import Outfit, CalendarEvent
from app.models.productivity import Event, Task
from app.models.finance import Expense, Budget
from app.models.wellness import Habit, HabitLog, SkincareProfile, RoutineProduct
from app.models.learning import LearningItem, Goal, StudySession, KnowledgeNote, Project
from app.models.personal_ai import UserMemory, ProactiveInsight, ActionProposalRecord
from app.schemas.auth import UserCreate, UserLogin, Token, UserResponse
from app.core.security import get_password_hash, verify_password, create_access_token, get_current_user_id

router = APIRouter()

@router.post("/register", response_model=Token)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
    
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        email=data.email,
        hashed_password=get_password_hash(data.password)
    )
    profile = Profile(
        id=str(uuid.uuid4()),
        user_id=user_id,
        display_name=data.display_name or data.email.split("@")[0]
    )
    preference = Preference(
        id=str(uuid.uuid4()),
        user_id=user_id,
        style_preferences=["Casual", "Minimal"]
    )
    
    db.add(user)
    db.add(profile)
    db.add(preference)
    await db.commit()
    
    token = create_access_token(user_id)
    return Token(access_token=token, token_type="bearer", user_id=user_id, email=user.email)


@router.post("/login", response_model=Token)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalars().first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    token = create_access_token(user.id)
    return Token(access_token=token, token_type="bearer", user_id=user.id, email=user.email)


@router.get("/me", response_model=UserResponse)
async def get_me(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User account not found")
    return user


@router.delete("/me")
async def delete_my_account(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Permanently deletes the authenticated user's account and all associated data
    across all domains in compliance with Google Play Store data safety requirements.
    """
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()

    # Cascade delete all domain models for user_id
    await db.execute(delete(Event).where(Event.user_id == user_id))
    await db.execute(delete(Task).where(Task.user_id == user_id))
    await db.execute(delete(Expense).where(Expense.user_id == user_id))
    await db.execute(delete(Budget).where(Budget.user_id == user_id))
    await db.execute(delete(HabitLog).where(HabitLog.user_id == user_id))
    await db.execute(delete(Habit).where(Habit.user_id == user_id))
    await db.execute(delete(RoutineProduct).where(RoutineProduct.user_id == user_id))
    await db.execute(delete(SkincareProfile).where(SkincareProfile.user_id == user_id))
    await db.execute(delete(LearningItem).where(LearningItem.user_id == user_id))
    await db.execute(delete(Goal).where(Goal.user_id == user_id))
    await db.execute(delete(StudySession).where(StudySession.user_id == user_id))
    await db.execute(delete(KnowledgeNote).where(KnowledgeNote.user_id == user_id))
    await db.execute(delete(Project).where(Project.user_id == user_id))
    await db.execute(delete(UserMemory).where(UserMemory.user_id == user_id))
    await db.execute(delete(ProactiveInsight).where(ProactiveInsight.user_id == user_id))
    await db.execute(delete(ActionProposalRecord).where(ActionProposalRecord.user_id == user_id))
    await db.execute(delete(WardrobeItem).where(WardrobeItem.owner_id == user_id))
    await db.execute(delete(WearEvent).where(WearEvent.user_id == user_id))
    await db.execute(delete(Outfit).where(Outfit.user_id == user_id))
    await db.execute(delete(VisualProfile).where(VisualProfile.user_id == user_id))
    await db.execute(delete(Preference).where(Preference.user_id == user_id))
    await db.execute(delete(Profile).where(Profile.user_id == user_id))
    if user:
        await db.delete(user)

    await db.commit()
    return {
        "status": "success",
        "message": "Account and all associated personal data permanently deleted."
    }
