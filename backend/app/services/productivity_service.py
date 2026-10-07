from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, date, time, timedelta
from app.models.productivity import Event, Task
from app.schemas.productivity import (
    ScheduleConflict,
    TimeBlock,
    TaskSlotSuggestion,
    PriorityAssessment,
    TodayProductivityResponse,
    EventResponse,
    TaskResponse
)

class ProductivityService:
    """
    Deterministic Productivity Intelligence Engine.
    Zero hallucination or arbitrary randomness.
    Respects user authority and delivers clear human-readable explanations.
    """

    @staticmethod
    def detect_conflicts(events: List[Event]) -> List[ScheduleConflict]:
        """
        Detects pairwise overlapping events in a collection without altering events.
        Overlap condition: max(A.start, B.start) < min(A.end, B.end).
        """
        conflicts: List[ScheduleConflict] = []
        active_events = [e for e in events if e.status != "cancelled" and not e.all_day]
        n = len(active_events)

        for i in range(n):
            for j in range(i + 1, n):
                e1 = active_events[i]
                e2 = active_events[j]

                overlap_start = max(e1.start_time, e2.start_time)
                overlap_end = min(e1.end_time, e2.end_time)

                if overlap_start < overlap_end:
                    msg = (
                        f"Schedule conflict: '{e1.title}' and '{e2.title}' overlap "
                        f"from {overlap_start.strftime('%H:%M')} to {overlap_end.strftime('%H:%M')}."
                    )
                    conflicts.append(ScheduleConflict(
                        event_a_id=e1.id,
                        event_a_title=e1.title,
                        event_b_id=e2.id,
                        event_b_title=e2.title,
                        overlap_start=overlap_start,
                        overlap_end=overlap_end,
                        message=msg
                    ))
        return conflicts

    @staticmethod
    def calculate_task_priority(
        task: Task,
        all_tasks: List[Task],
        current_time: Optional[datetime] = None
    ) -> PriorityAssessment:
        """
        Calculates task urgency, checks blocking dependencies, and suggests priority
        while keeping the user's explicit priority authoritative.
        """
        now = current_time or datetime.utcnow()
        task_map = {t.id: t for t in all_tasks}

        # Check dependency blockage
        blocking_ids: List[str] = []
        is_blocked = False
        for dep_id in (task.dependency_task_ids or []):
            dep_task = task_map.get(dep_id)
            if dep_task and dep_task.status != "Completed":
                is_blocked = True
                blocking_ids.append(dep_id)

        # Explicit user priority weighting
        p_weights = {"Urgent": 1.0, "High": 0.8, "Medium": 0.5, "Low": 0.2}
        user_weight = p_weights.get(task.priority, 0.5)

        # Due date urgency weighting
        due_weight = 0.2
        due_status_text = "No deadline set"

        if task.due_date:
            delta = task.due_date - now
            if delta.total_seconds() < 0:
                # Overdue
                due_weight = 1.0
                hours_ago = abs(int(delta.total_seconds() // 3600))
                due_status_text = f"Overdue by {hours_ago}h" if hours_ago > 0 else "Overdue"
            elif delta <= timedelta(hours=12):
                due_weight = 0.95
                due_status_text = f"Due in {int(delta.total_seconds() // 3600)}h"
            elif delta <= timedelta(hours=24):
                due_weight = 0.85
                due_status_text = "Due today"
            elif delta <= timedelta(hours=48):
                due_weight = 0.70
                due_status_text = "Due tomorrow"
            elif delta <= timedelta(days=7):
                due_weight = 0.45
                due_status_text = f"Due in {delta.days} days"
            else:
                due_weight = 0.25
                due_status_text = f"Due in {delta.days} days"

        # Combine urgency score
        if is_blocked:
            urgency_score = min(0.3, user_weight * 0.5)
            suggested_priority = "Low"
            blocking_titles = [task_map[d].title for d in blocking_ids if d in task_map]
            explanation = f"Blocked by incomplete dependency: {', '.join(blocking_titles) if blocking_titles else 'prerequisite task'}."
        elif due_weight >= 0.95:
            urgency_score = max(user_weight, 0.95)
            suggested_priority = "Urgent"
            explanation = f"{due_status_text}. Requires immediate action."
        elif due_weight >= 0.70:
            urgency_score = (user_weight * 0.4) + (due_weight * 0.6)
            suggested_priority = "High" if urgency_score > 0.65 else "Medium"
            explanation = f"{due_status_text} with {task.priority} user priority → High urgency."
        else:
            urgency_score = (user_weight * 0.6) + (due_weight * 0.4)
            suggested_priority = task.priority
            explanation = f"{due_status_text} with {task.priority} priority."

        urgency_score = round(min(1.0, max(0.0, urgency_score)), 2)

        return PriorityAssessment(
            task_id=task.id,
            title=task.title,
            explicit_priority=task.priority,
            calculated_priority=suggested_priority,
            urgency_score=urgency_score,
            is_blocked=is_blocked,
            blocking_task_ids=blocking_ids,
            explanation=explanation
        )

    @staticmethod
    def identify_free_blocks(
        events: List[Event],
        day_start: datetime,
        day_end: datetime,
        min_duration_minutes: int = 15
    ) -> List[TimeBlock]:
        """
        Finds free time slots in a given time span (e.g. 08:00 to 21:00).
        """
        active_events = sorted(
            [e for e in events if e.status != "cancelled" and not e.all_day and e.end_time > day_start and e.start_time < day_end],
            key=lambda e: e.start_time
        )

        free_blocks: List[TimeBlock] = []
        current_cursor = day_start

        for e in active_events:
            e_start = max(current_cursor, e.start_time)
            if e_start > current_cursor:
                gap_minutes = int((e_start - current_cursor).total_seconds() // 60)
                if gap_minutes >= min_duration_minutes:
                    free_blocks.append(TimeBlock(
                        start_time=current_cursor,
                        end_time=e_start,
                        duration_minutes=gap_minutes,
                        is_free=True
                    ))
            if e.end_time > current_cursor:
                current_cursor = e.end_time

        if current_cursor < day_end:
            gap_minutes = int((day_end - current_cursor).total_seconds() // 60)
            if gap_minutes >= min_duration_minutes:
                free_blocks.append(TimeBlock(
                    start_time=current_cursor,
                    end_time=day_end,
                    duration_minutes=gap_minutes,
                    is_free=True
                ))

        return free_blocks

    @staticmethod
    def suggest_task_slots(
        free_blocks: List[TimeBlock],
        uncompleted_tasks: List[Task]
    ) -> List[TaskSlotSuggestion]:
        """
        Suggests free blocks for high-priority or upcoming uncompleted tasks.
        Never modifies user calendar automatically.
        """
        suggestions: List[TaskSlotSuggestion] = []
        # Sort tasks by priority
        p_ranks = {"Urgent": 0, "High": 1, "Medium": 2, "Low": 3}
        sorted_tasks = sorted(
            [t for t in uncompleted_tasks if t.status in ["Todo", "In Progress"]],
            key=lambda t: (p_ranks.get(t.priority, 2), t.due_date or datetime.max)
        )

        remaining_blocks = [
            {"start": b.start_time, "end": b.end_time, "duration": b.duration_minutes}
            for b in free_blocks
        ]

        for t in sorted_tasks:
            est = max(15, t.estimated_duration_minutes or 30)
            for block in remaining_blocks:
                if block["duration"] >= est:
                    suggested_start = block["start"]
                    suggested_end = suggested_start + timedelta(minutes=est)
                    reason = f"Fits '{t.title}' ({est} mins) into {block['duration']} min free window."
                    suggestions.append(TaskSlotSuggestion(
                        task_id=t.id,
                        task_title=t.title,
                        suggested_start=suggested_start,
                        suggested_end=suggested_end,
                        duration_minutes=est,
                        reason=reason
                    ))
                    # Shrink remaining block
                    block["start"] = suggested_end
                    block["duration"] -= est
                    break # One suggestion per task

            if len(suggestions) >= 4:
                break # Limit top suggestions to avoid clutter

        return suggestions

    @classmethod
    def compile_today_dashboard(
        cls,
        events: List[Event],
        tasks: List[Task],
        target_date: Optional[date] = None,
        now: Optional[datetime] = None
    ) -> TodayProductivityResponse:
        """
        Builds unified today intelligence response.
        """
        current_dt = now or datetime.utcnow()
        t_date = target_date or current_dt.date()
        date_str = t_date.strftime("%Y-%m-%d")

        # Today boundaries (00:00 to 23:59:59)
        day_start = datetime.combine(t_date, time(0, 0, 0))
        day_end = datetime.combine(t_date, time(23, 59, 59))

        # Filter events active today
        today_events = [
            e for e in events
            if (e.start_time <= day_end and e.end_time >= day_start)
        ]
        today_events.sort(key=lambda e: e.start_time)

        # Filter tasks
        today_tasks: List[Task] = []
        overdue_tasks: List[Task] = []
        upcoming_deadlines: List[Task] = []
        completed_count = 0

        for t in tasks:
            if t.status == "Completed":
                completed_count += 1
                # Include completed tasks if completed today
                if t.completed_at and t.completed_at.date() == t_date:
                    today_tasks.append(t)
                continue

            # Uncompleted task
            is_today = False
            if t.due_date:
                t_due_date = t.due_date.date()
                if t.due_date < current_dt and t_due_date < t_date:
                    overdue_tasks.append(t)
                elif t_due_date == t_date:
                    is_today = True
                    today_tasks.append(t)
                elif 0 < (t.due_date - current_dt).total_seconds() <= 86400 * 2:
                    upcoming_deadlines.append(t)

            if not is_today and t.priority in ["High", "Urgent"] and t not in overdue_tasks:
                today_tasks.append(t)

        # Conflicts
        conflicts = cls.detect_conflicts(today_events)

        # Free blocks during working hours (08:00 to 21:00)
        work_start = datetime.combine(t_date, time(8, 0, 0))
        work_end = datetime.combine(t_date, time(21, 0, 0))
        free_blocks = cls.identify_free_blocks(today_events, work_start, work_end)

        # Suggested task slots
        suggested_slots = cls.suggest_task_slots(free_blocks, today_tasks + overdue_tasks)

        # Natural summary message
        summary_parts = []
        if today_events:
            summary_parts.append(f"{len(today_events)} event{'s' if len(today_events) > 1 else ''}")
        if today_tasks:
            summary_parts.append(f"{len(today_tasks)} task{'s' if len(today_tasks) > 1 else ''}")
        if overdue_tasks:
            summary_parts.append(f"{len(overdue_tasks)} overdue")
        if conflicts:
            summary_parts.append(f"{len(conflicts)} conflict detected")

        if summary_parts:
            summary_msg = f"Today's schedule: {', '.join(summary_parts)}."
        else:
            summary_msg = "Your day is clear. You have no scheduled events or pending tasks."

        return TodayProductivityResponse(
            date=date_str,
            total_events=len(today_events),
            total_tasks=len(today_tasks),
            completed_tasks=completed_count,
            overdue_tasks=[TaskResponse.model_validate(t) for t in overdue_tasks],
            upcoming_deadlines=[TaskResponse.model_validate(t) for t in upcoming_deadlines],
            events=[EventResponse.model_validate(e) for e in today_events],
            tasks=[TaskResponse.model_validate(t) for t in today_tasks],
            conflicts=conflicts,
            free_blocks=free_blocks,
            suggested_slots=suggested_slots,
            summary_message=summary_msg
        )

productivity_service = ProductivityService()
