import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_, func

from app.models.user import User, Profile, Preference
from app.models.personal_ai import UserMemory
from app.models.productivity import Event, Task
from app.models.finance import Expense, Budget
from app.models.wellness import Habit, HabitLog, SkincareProfile, RoutineProduct
from app.models.learning import LearningItem, Goal, StudySession, KnowledgeNote, Project
from app.models.wardrobe import WardrobeItem
from app.services.weather_service import WeatherService
from app.schemas.personal_ai import PersonalContextSnapshot

logger = logging.getLogger(__name__)

class PersonalContextEngine:
    def __init__(self):
        self.weather_service = WeatherService()

    async def build_context_snapshot(
        self,
        user_id: str,
        db: AsyncSession,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        reference_time: Optional[datetime] = None
    ) -> PersonalContextSnapshot:
        now = reference_time or datetime.utcnow()
        today_start = datetime(now.year, now.month, now.day)
        tomorrow_end = today_start + timedelta(days=2)
        month_start = datetime(now.year, now.month, 1)

        # 1. Profile & Preferences
        prof_res = await db.execute(select(Profile).where(Profile.user_id == user_id))
        profile_obj = prof_res.scalars().first()
        pref_res = await db.execute(select(Preference).where(Preference.user_id == user_id))
        pref_obj = pref_res.scalars().first()

        profile_data = {
            "display_name": profile_obj.display_name if profile_obj else "User",
            "age": profile_obj.age if profile_obj else None,
            "gender": profile_obj.gender if profile_obj else None,
            "city": profile_obj.location if profile_obj else "Default City",
            "timezone": profile_obj.timezone if profile_obj else "UTC",
        }

        style_profile_data = {
            "primary_style": pref_obj.primary_style if pref_obj else "Casual",
            "secondary_styles": pref_obj.secondary_styles if pref_obj else [],
            "primary_fit": pref_obj.primary_fit if pref_obj else "Regular",
            "preferred_colors": pref_obj.preferred_colors if pref_obj else [],
            "disliked_colors": pref_obj.disliked_colors if pref_obj else [],
            "occasions": pref_obj.occasions if pref_obj else [],
        }

        # 2. User confirmed memories
        mem_res = await db.execute(
            select(UserMemory).where(UserMemory.user_id == user_id).order_by(UserMemory.created_at.desc())
        )
        memories = [
            {"key": m.key, "value": m.value, "domain": m.domain, "source": m.source}
            for m in mem_res.scalars().all()
        ]

        # 3. Upcoming events (next 48h)
        evt_res = await db.execute(
            select(Event).where(
                Event.user_id == user_id,
                Event.start_time >= today_start,
                Event.start_time <= tomorrow_end,
                Event.status != "cancelled"
            ).order_by(Event.start_time.asc())
        )
        upcoming_events = [
            {
                "id": e.id,
                "title": e.title,
                "start_time": e.start_time.isoformat(),
                "end_time": e.end_time.isoformat(),
                "category": e.category,
                "priority": e.priority,
                "location": e.location,
                "occasion": e.occasion or e.category,
                "all_day": e.all_day
            }
            for e in evt_res.scalars().all()
        ]

        # 4. Tasks (today, overdue, upcoming deadlines)
        task_res = await db.execute(
            select(Task).where(
                Task.user_id == user_id,
                Task.status != "Completed",
                Task.status != "Cancelled"
            ).order_by(Task.due_date.asc())
        )
        all_active_tasks = task_res.scalars().all()

        today_tasks = []
        overdue_tasks = []
        deadlines = []

        for t in all_active_tasks:
            t_data = {
                "id": t.id,
                "title": t.title,
                "category": t.category,
                "priority": t.priority,
                "status": t.status,
                "due_date": t.due_date.isoformat() if t.due_date else None,
                "estimated_duration_minutes": t.estimated_duration_minutes or 30
            }
            if t.due_date:
                if t.due_date < today_start:
                    overdue_tasks.append(t_data)
                elif t.due_date <= today_start + timedelta(days=2):
                    today_tasks.append(t_data)
                deadlines.append(t_data)
            else:
                today_tasks.append(t_data)

        # 5. Active Goals
        goal_res = await db.execute(
            select(Goal).where(
                Goal.user_id == user_id,
                Goal.status != "Completed",
                Goal.status != "Cancelled"
            ).order_by(Goal.target_date.asc())
        )
        active_goals = [
            {
                "id": g.id,
                "title": g.title,
                "category": g.category,
                "priority": g.priority,
                "progress": g.progress,
                "target_date": g.target_date.isoformat() if g.target_date else None,
                "milestones_count": len(g.milestones or []),
                "completed_milestones": sum(1 for m in (g.milestones or []) if m.get("completed")),
                "financial_target_amount": g.financial_target_amount,
                "financial_saved_amount": g.financial_saved_amount
            }
            for g in goal_res.scalars().all()
        ]

        # 6. Learning items & workload
        learn_res = await db.execute(
            select(LearningItem).where(
                LearningItem.user_id == user_id,
                LearningItem.status != "Completed"
            ).order_by(LearningItem.target_date.asc())
        )
        learning_workload = [
            {
                "id": li.id,
                "title": li.title,
                "type": li.type,
                "category": li.category,
                "priority": li.priority,
                "progress": li.progress,
                "target_date": li.target_date.isoformat() if li.target_date else None,
                "estimated_duration_minutes": li.estimated_duration_minutes
            }
            for li in learn_res.scalars().all()
        ]

        # 7. Projects
        proj_res = await db.execute(
            select(Project).where(
                Project.user_id == user_id,
                Project.status != "Completed"
            )
        )
        project_workload = [
            {
                "id": p.id,
                "title": p.title,
                "category": p.category,
                "progress": p.progress,
                "target_date": p.target_date.isoformat() if p.target_date else None
            }
            for p in proj_res.scalars().all()
        ]

        # 8. Budget and recent expenses
        budget_res = await db.execute(
            select(Budget).where(Budget.user_id == user_id, Budget.period == "monthly")
        )
        budget_obj = budget_res.scalars().first()
        monthly_budget_val = float(budget_obj.amount) if budget_obj else 0.0

        exp_res = await db.execute(
            select(Expense).where(
                Expense.user_id == user_id,
                Expense.expense_date >= month_start
            ).order_by(Expense.expense_date.desc())
        )
        month_expenses = exp_res.scalars().all()
        total_spent_val = sum(float(e.amount) for e in month_expenses)
        recent_expenses = [
            {
                "id": e.id,
                "amount": float(e.amount),
                "category": e.category,
                "description": e.description,
                "expense_date": e.expense_date.isoformat()
            }
            for e in month_expenses[:5]
        ]

        budget_state = {
            "monthly_budget": monthly_budget_val,
            "total_spent_this_month": total_spent_val,
            "remaining_budget": max(0.0, monthly_budget_val - total_spent_val) if monthly_budget_val > 0 else 0.0,
            "over_budget": total_spent_val > monthly_budget_val if monthly_budget_val > 0 else False
        }

        # 9. Wellness & Habits
        habit_res = await db.execute(
            select(Habit).where(Habit.user_id == user_id, Habit.active == True)
        )
        habits_list = habit_res.scalars().all()
        today_str = today_start.strftime("%Y-%m-%d")

        log_res = await db.execute(
            select(HabitLog).where(
                HabitLog.user_id == user_id,
                HabitLog.log_date == today_str
            )
        )
        today_logs = {l.habit_id: l.status for l in log_res.scalars().all()}

        habits_data = []
        for h in habits_list:
            habits_data.append({
                "id": h.id,
                "name": h.name,
                "category": h.category,
                "target": h.target,
                "unit": h.unit,
                "completed_today": today_logs.get(h.id) == "Completed"
            })

        skin_res = await db.execute(
            select(SkincareProfile).where(SkincareProfile.user_id == user_id)
        )
        skin_obj = skin_res.scalars().first()
        wellness_state = {
            "active_habits_count": len(habits_list),
            "completed_today_count": sum(1 for h in habits_data if h["completed_today"]),
            "skin_type": skin_obj.skin_type if skin_obj else "Normal",
            "skin_concerns": skin_obj.skin_concerns if skin_obj else []
        }

        # 10. Wardrobe Summary
        ward_res = await db.execute(
            select(WardrobeItem).where(
                WardrobeItem.owner_id == user_id,
                WardrobeItem.status == "available"
            )
        )
        wardrobe_items = ward_res.scalars().all()
        wardrobe_summary = {
            "total_items": len(wardrobe_items),
            "favorites_count": sum(1 for w in wardrobe_items if w.favorite),
            "tops_count": sum(1 for w in wardrobe_items if w.category in ["Tops", "Top"]),
            "bottoms_count": sum(1 for w in wardrobe_items if w.category in ["Bottoms", "Bottom"]),
            "outerwear_count": sum(1 for w in wardrobe_items if w.category in ["Outerwear"]),
            "footwear_count": sum(1 for w in wardrobe_items if w.category in ["Footwear", "Shoes"]),
            "sample_items": [
                {
                    "id": w.id,
                    "name": w.name,
                    "category": w.category,
                    "subcategory": w.subcategory,
                    "primary_color": w.primary_color,
                    "formality": w.formality,
                    "favorite": w.favorite
                }
                for w in wardrobe_items[:10]
            ]
        }

        # 11. Relevant Notes
        notes_res = await db.execute(
            select(KnowledgeNote).where(KnowledgeNote.user_id == user_id).order_by(KnowledgeNote.updated_at.desc()).limit(5)
        )
        relevant_notes = [
            {"id": n.id, "title": n.title, "tags": n.tags, "summary": n.content[:100]}
            for n in notes_res.scalars().all()
        ]

        # 12. Weather (Graceful Fallback)
        weather_info = None
        if lat is not None and lon is not None:
            try:
                weather_resp = await self.weather_service.get_current_weather(lat=lat, lon=lon)
                if weather_resp and weather_resp.current:
                    weather_info = {
                        "temperature_c": weather_resp.current.temperature_c,
                        "apparent_temperature_c": weather_resp.current.apparent_temperature_c,
                        "condition_text": weather_resp.current.condition_text,
                        "precipitation_probability": weather_resp.current.precipitation_probability,
                        "rain_mm": weather_resp.current.rain_mm,
                        "is_rainy": weather_resp.current.rain_mm > 0.0 or "rain" in weather_resp.current.condition_text.lower()
                    }
            except Exception as e:
                logger.warning(f"Weather unavailable for ({lat}, {lon}): {e}")
                weather_info = None

        return PersonalContextSnapshot(
            user_id=user_id,
            snapshot_time=now,
            profile=profile_data,
            style_profile=style_profile_data,
            upcoming_events=upcoming_events,
            today_tasks=today_tasks,
            overdue_tasks=overdue_tasks,
            deadlines=deadlines,
            active_goals=active_goals,
            learning_workload=learning_workload,
            project_workload=project_workload,
            budget_state=budget_state,
            recent_expenses=recent_expenses,
            wellness_state=wellness_state,
            habits=habits_data,
            wardrobe_summary=wardrobe_summary,
            relevant_notes=relevant_notes,
            user_memories=memories,
            weather=weather_info
        )

personal_context_engine = PersonalContextEngine()
