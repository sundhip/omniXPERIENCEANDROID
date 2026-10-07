import math
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.learning import Goal, LearningItem, StudySession
from app.models.productivity import Event, Task
from app.schemas.learning import GoalPlanResponse, MilestonePlanSuggestion

class GoalPlanningService:

    @staticmethod
    async def plan_goal(
        db: AsyncSession,
        user_id: str,
        goal: Goal
    ) -> GoalPlanResponse:
        now = datetime.utcnow()
        
        # 1. Evaluate target date & timeline
        target_date = goal.target_date or (now + timedelta(days=30))
        days_remaining = (target_date - now).total_seconds() / 86400.0
        
        # 2. Estimate effort conservatively
        existing_milestones = goal.milestones or []
        uncompleted_milestones = [m for m in existing_milestones if not m.get("completed", False)]
        
        # Base hours by category
        category_weights = {
            "Academic": 30.0,
            "Career": 40.0,
            "Financial": 10.0,
            "Fitness": 20.0,
            "Personal": 15.0,
            "Project": 35.0,
            "Learning": 25.0
        }
        base_hours = category_weights.get(goal.category, 25.0)
        
        if existing_milestones:
            # Average 6 hours per uncompleted milestone
            remaining_hours = max(2.0, len(uncompleted_milestones) * 6.0)
            total_estimated_hours = max(remaining_hours, len(existing_milestones) * 6.0)
        else:
            remaining_ratio = max(0.05, (100.0 - (goal.progress or 0.0)) / 100.0)
            total_estimated_hours = base_hours
            remaining_hours = base_hours * remaining_ratio

        # 3. Weekly hours required
        if days_remaining <= 0:
            weeks_remaining = 0.0
            weekly_hours_required = remaining_hours
            deadline_status = "Passed"
            feasible = False
        else:
            weeks_remaining = max(0.14, days_remaining / 7.0) # at least 1 day fraction
            weekly_hours_required = round(remaining_hours / weeks_remaining, 1)
            
            if weekly_hours_required > 25.0:
                deadline_status = "Unrealistic"
                feasible = False
            elif weekly_hours_required > 12.0:
                deadline_status = "Tight"
                feasible = True
            else:
                deadline_status = "On Track"
                feasible = True

        # 4. Check conflicts with existing Phase 5 events & tasks (next 7 days)
        detected_conflicts: List[str] = []
        next_week = now + timedelta(days=7)
        
        # Query events in next 7 days
        events_stmt = select(Event).where(
            Event.user_id == user_id,
            Event.start_time >= now,
            Event.start_time <= next_week
        )
        events_res = await db.execute(events_stmt)
        week_events = events_res.scalars().all()
        
        total_event_minutes = sum(
            max(0, int((e.end_time - e.start_time).total_seconds() / 60))
            for e in week_events if e.end_time and e.start_time
        )
        total_event_hours = total_event_minutes / 60.0

        # Query pending tasks
        tasks_stmt = select(Task).where(
            Task.user_id == user_id,
            Task.status != "Completed"
        )
        tasks_res = await db.execute(tasks_stmt)
        pending_tasks = tasks_res.scalars().all()
        total_task_hours = sum((t.estimated_duration_minutes or 30) for t in pending_tasks) / 60.0

        total_commitments_hours = total_event_hours + total_task_hours
        if total_commitments_hours > 30.0 and weekly_hours_required > 8.0:
            detected_conflicts.append(
                f"High upcoming workload: {round(total_commitments_hours, 1)} hrs committed across calendar and tasks this week."
            )
        if len(week_events) >= 15:
            detected_conflicts.append(
                f"Busy schedule: {len(week_events)} calendar events scheduled in the next 7 days."
            )

        # 5. Suggest milestones
        suggested_milestones: List[MilestonePlanSuggestion] = []
        if existing_milestones:
            for idx, m in enumerate(existing_milestones):
                suggested_milestones.append(
                    MilestonePlanSuggestion(
                        title=m.get("title", f"Milestone {idx + 1}"),
                        target_date=m.get("target_date") or (now + timedelta(days=int((idx + 1) * (days_remaining / max(1, len(existing_milestones)))))).strftime("%Y-%m-%d"),
                        estimated_hours=round(total_estimated_hours / len(existing_milestones), 1),
                        order=m.get("order", idx + 1)
                    )
                )
        else:
            # Generate 4 staged milestones
            stages = [
                ("Foundation & Scope Definition", 0.25),
                ("Core Knowledge & Implementation", 0.50),
                ("Applied Practice & Validation", 0.75),
                ("Review, Polish & Final Completion", 1.0)
            ]
            for idx, (stage_name, ratio) in enumerate(stages):
                m_date = (now + timedelta(days=max(1, int(days_remaining * ratio)))).strftime("%Y-%m-%d")
                suggested_milestones.append(
                    MilestonePlanSuggestion(
                        title=f"{stage_name} for '{goal.title}'",
                        target_date=m_date,
                        estimated_hours=round(total_estimated_hours / 4.0, 1),
                        order=idx + 1
                    )
                )

        # 6. Recommended next action & rationale
        first_pending = next((m.title for m in suggested_milestones if m.order == 1), goal.title)
        if uncompleted_milestones:
            first_pending = uncompleted_milestones[0].get("title", first_pending)

        recommended_next_action = f"Schedule two 90-minute focused sessions this week for '{first_pending}'."

        rationale_parts = [
            f"Goal '{goal.title}' requires ~{round(remaining_hours, 1)} remaining hours of effort over {max(1, int(days_remaining))} days.",
            f"Weekly workload: {weekly_hours_required} hrs/week ({deadline_status})."
        ]
        if detected_conflicts:
            rationale_parts.append(f"Caution: {detected_conflicts[0]}")

        return GoalPlanResponse(
            goal_id=goal.id,
            goal_title=goal.title,
            feasible=feasible,
            total_estimated_hours=round(total_estimated_hours, 1),
            weekly_hours_required=weekly_hours_required,
            deadline_status=deadline_status,
            suggested_milestones=suggested_milestones,
            recommended_next_action=recommended_next_action,
            detected_conflicts=detected_conflicts,
            rationale=" ".join(rationale_parts)
        )
