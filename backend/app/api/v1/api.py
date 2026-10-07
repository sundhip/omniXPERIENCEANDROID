from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, profile, wardrobe, wear_events, outfits,
    recommendations, weather, sync, visual_profile,
    events, tasks, productivity,
    expenses, budgets, finance, habits, wellness
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(profile.router, prefix="/profile", tags=["Profile & Preferences"])
api_router.include_router(visual_profile.router, prefix="/profile/visual-profile", tags=["Visual Profile & Face AI"])
api_router.include_router(wardrobe.router, prefix="/wardrobe", tags=["Digital Wardrobe"])
api_router.include_router(events.router, prefix="/events", tags=["Calendar & Events"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["Tasks & Todos"])
api_router.include_router(productivity.router, prefix="/productivity", tags=["Productivity Intelligence"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["Expenses"])
api_router.include_router(budgets.router, prefix="/budgets", tags=["Budgets"])
api_router.include_router(finance.router, prefix="/finance", tags=["Financial Intelligence"])
api_router.include_router(habits.router, prefix="/habits", tags=["Habits"])
api_router.include_router(wellness.router, prefix="/wellness", tags=["Wellness & Routines"])
api_router.include_router(wear_events.router, prefix="/wear-events", tags=["Wear History"])
api_router.include_router(outfits.router, prefix="/outfits", tags=["Outfit Planning"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["AI Recommendations"])
api_router.include_router(weather.router, prefix="/weather", tags=["Weather"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync"])
