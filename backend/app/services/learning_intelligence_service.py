from datetime import datetime, timedelta
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.learning import LearningItem, Goal, StudySession
from app.models.productivity import Event
from app.models.wellness import Habit, RoutineProduct
from app.schemas.learning import LearningInsight

class LearningIntelligenceService:

    @staticmethod
    async def get_learning_insights(
        db: AsyncSession,
        user_id: str
    ) -> List[LearningInsight]:
        insights: List[LearningInsight] = []
        now = datetime.utcnow()
        week_ahead = now + timedelta(days=7)
        two_weeks_ago = now - timedelta(days=14)
        one_week_ago = now - timedelta(days=7)

        # 1. Query Learning Items
        learning_stmt = select(LearningItem).where(LearningItem.user_id == user_id)
        learning_res = await db.execute(learning_stmt)
        learning_items = learning_res.scalars().all()

        # 2. Query Goals
        goals_stmt = select(Goal).where(Goal.user_id == user_id)
        goals_res = await db.execute(goals_stmt)
        goals = goals_res.scalars().all()

        # 3. Query Recent Study Sessions
        sessions_stmt = select(StudySession).where(
            StudySession.user_id == user_id,
            StudySession.created_at >= two_weeks_ago
        )
        sessions_res = await db.execute(sessions_stmt)
        recent_sessions = sessions_res.scalars().all()

        # --- Rule 1: Approaching Deadlines (Exams / Assignments / Items) ---
        urgent_items = [
            item for item in learning_items
            if item.target_date and now <= item.target_date <= week_ahead and (item.progress or 0.0) < 100.0 and item.status != "Completed"
        ]
        if urgent_items:
            # Sort by target_date ascending
            urgent_items.sort(key=lambda x: x.target_date) # type: ignore
            nearest = urgent_items[0]
            days_left = max(0, int((nearest.target_date - now).total_seconds() / 86400.0)) # type: ignore
            insights.append(
                LearningInsight(
                    type="approaching_deadline",
                    title=f"Upcoming Deadline: {nearest.title}",
                    description=f"{len(urgent_items)} learning item(s) due within 7 days. '{nearest.title}' is due in {days_left} day(s) at {int(nearest.progress)}% completion.",
                    severity="critical" if days_left <= 2 else "warning",
                    actionable_recommendation=f"Prioritize '{nearest.title}' first to prevent last-minute cramming.",
                    supporting_data={
                        "urgent_item_count": len(urgent_items),
                        "nearest_id": nearest.id,
                        "nearest_title": nearest.title,
                        "days_remaining": days_left
                    }
                )
            )

        # --- Rule 2: Neglected Learning Topics ---
        active_items = [i for i in learning_items if i.status == "In Progress" and (i.progress or 0.0) < 100.0]
        recent_session_item_ids = {s.learning_item_id for s in recent_sessions if s.learning_item_id}
        neglected = [
            i for i in active_items
            if i.id not in recent_session_item_ids and i.updated_at and i.updated_at < one_week_ago
        ]
        if neglected:
            sample = neglected[0]
            insights.append(
                LearningInsight(
                    type="neglected_item",
                    title=f"Neglected Topic: {sample.title}",
                    description=f"You started '{sample.title}' but have not logged a study session or progress in over a week.",
                    severity="info",
                    actionable_recommendation=f"Review '{sample.title}' with a quick 20-minute refresher session or pause it if priorities shifted.",
                    supporting_data={
                        "neglected_count": len(neglected),
                        "item_id": sample.id,
                        "item_title": sample.title
                    }
                )
            )

        # --- Rule 3: Workload Imbalance ---
        if len(recent_sessions) >= 4:
            session_counts: Dict[str, int] = {}
            for s in recent_sessions:
                key = s.learning_item_id or s.title
                session_counts[key] = session_counts.get(key, 0) + 1
            
            dominant_item_count = max(session_counts.values())
            total_sessions = len(recent_sessions)
            dominance_ratio = dominant_item_count / total_sessions
            
            if dominance_ratio >= 0.75 and len(active_items) >= 2:
                dominant_key = [k for k, v in session_counts.items() if v == dominant_item_count][0]
                insights.append(
                    LearningInsight(
                        type="workload_imbalance",
                        title="Workload Concentration Detected",
                        description=f"{int(dominance_ratio * 100)}% of your recent study sessions concentrated on one focus area while {len(active_items) - 1} other items are in progress.",
                        severity="info",
                        actionable_recommendation="Balance your schedule by allocating at least one session to your other active goals or coursework.",
                        supporting_data={"dominant_ratio": dominance_ratio, "total_sessions": total_sessions}
                    )
                )

        # --- Rule 4: Phase 6 Wellness Overload Check ---
        # Check planned sessions + events for tomorrow
        tomorrow_start = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        tomorrow_end = (now + timedelta(days=1)).replace(hour=23, minute=59, second=59, microsecond=0)

        events_stmt = select(Event).where(
            Event.user_id == user_id,
            Event.start_time >= tomorrow_start,
            Event.start_time <= tomorrow_end
        )
        events_res = await db.execute(events_stmt)
        tomorrow_events = events_res.scalars().all()
        tomorrow_event_hours = sum(
            max(0, int((e.end_time - e.start_time).total_seconds() / 3600))
            for e in tomorrow_events if e.end_time and e.start_time
        )

        planned_study_hours = sum(
            s.planned_duration_minutes / 60.0
            for s in recent_sessions if s.status == "Scheduled"
        )
        total_tomorrow_hours = tomorrow_event_hours + planned_study_hours

        # Query active wellness routines/habits
        habits_stmt = select(Habit).where(Habit.user_id == user_id)
        habits_res = await db.execute(habits_stmt)
        user_habits = habits_res.scalars().all()

        if total_tomorrow_hours >= 7.0 and len(user_habits) >= 2:
            insights.append(
                LearningInsight(
                    type="wellness_overload",
                    title="Potential Schedule Overload Tomorrow",
                    description=f"You have ~{round(total_tomorrow_hours, 1)} hours of planned work/events tomorrow alongside {len(user_habits)} active daily wellness habits.",
                    severity="warning",
                    actionable_recommendation="Ensure you take structured 10-minute breaks between deep work sessions and maintain your hydration and evening routine.",
                    supporting_data={
                        "planned_hours": total_tomorrow_hours,
                        "habit_count": len(user_habits)
                    }
                )
            )

        # --- Rule 5: Momentum ---
        completed_sessions = [s for s in recent_sessions if s.status == "Completed"]
        if len(completed_sessions) >= 3:
            total_minutes = sum(s.actual_duration_minutes or s.planned_duration_minutes for s in completed_sessions)
            insights.append(
                LearningInsight(
                    type="momentum",
                    title="Strong Learning Momentum",
                    description=f"You completed {len(completed_sessions)} study sessions ({total_minutes} mins) in the last two weeks.",
                    severity="info",
                    actionable_recommendation="Maintain this cadence! Consistent 30-45 minute blocks yield the highest long-term retention.",
                    supporting_data={"completed_sessions": len(completed_sessions), "total_minutes": total_minutes}
                )
            )

        return insights
