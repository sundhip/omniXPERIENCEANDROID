from datetime import datetime, date, timedelta
from typing import List, Dict, Any, Optional

from app.models.wellness import Habit, HabitLog, SkincareProfile, RoutineProduct
from app.schemas.wellness import (
    HabitResponse, RoutineStepToday, WellnessInsight, TodayWellnessResponse
)

class WellnessIntelligenceService:
    """
    Deterministic wellness and routine intelligence service.
    Computes truthful streaks, completion rates, and routines without
    speculative medical diagnostics or fake habit metrics.
    """

    @staticmethod
    def calculate_habit_metrics(
        habit: Habit,
        logs: List[HabitLog],
        reference_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Calculates current streak, longest streak, and completion rate.
        Mathematically truthful: breaks when a day is missed.
        """
        ref = reference_date or date.today()
        # Filter completed logs
        completed_dates = set()
        for log in logs:
            if log.habit_id == habit.id and log.status.lower() == "completed":
                try:
                    d = datetime.strptime(log.log_date, "%Y-%m-%d").date()
                    completed_dates.add(d)
                except ValueError:
                    pass

        # Check completed today
        completed_today = ref in completed_dates

        # Calculate current streak backwards from today or yesterday
        current_streak = 0
        check_date = ref if completed_today else (ref - timedelta(days=1))
        
        while check_date in completed_dates:
            current_streak += 1
            check_date -= timedelta(days=1)

        # Longest streak calculation
        sorted_dates = sorted(list(completed_dates))
        longest_streak = 0
        temp_streak = 0
        prev_d: Optional[date] = None

        for d in sorted_dates:
            if prev_d is None or (d - prev_d).days == 1:
                temp_streak += 1
            elif (d - prev_d).days > 1:
                temp_streak = 1
            prev_d = d
            if temp_streak > longest_streak:
                longest_streak = temp_streak

        longest_streak = max(longest_streak, current_streak)

        # Completion rate
        start_d = habit.start_date.date() if habit.start_date else (ref - timedelta(days=30))
        total_days = max(1, (ref - start_d).days + 1)
        completion_rate = round((len(completed_dates) / total_days) * 100.0, 1)
        completion_rate = min(100.0, max(0.0, completion_rate))

        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "completion_rate": completion_rate,
            "completed_today": completed_today
        }

    def compile_today_wellness(
        self,
        habits: List[Habit],
        logs: List[HabitLog],
        skincare_profile: Optional[SkincareProfile],
        routine_products: List[RoutineProduct],
        reference_date: Optional[date] = None
    ) -> TodayWellnessResponse:
        ref = reference_date or date.today()
        ref_str = ref.strftime("%Y-%m-%d")

        # Process habits
        habit_responses: List[HabitResponse] = []
        completed_today_count = 0

        for h in habits:
            metrics = self.calculate_habit_metrics(h, logs, ref)
            if metrics["completed_today"]:
                completed_today_count += 1
            
            h_resp = HabitResponse(
                id=h.id,
                user_id=h.user_id,
                name=h.name,
                description=h.description,
                frequency=h.frequency,
                target=h.target,
                unit=h.unit,
                start_date=h.start_date,
                end_date=h.end_date,
                reminder_settings=h.reminder_settings or [],
                category=h.category or "General",
                active=h.active,
                current_streak=metrics["current_streak"],
                longest_streak=metrics["longest_streak"],
                completion_rate=metrics["completion_rate"],
                completed_today=metrics["completed_today"],
                created_at=h.created_at,
                updated_at=h.updated_at
            )
            habit_responses.append(h_resp)

        # Process routines
        morning_steps: List[RoutineStepToday] = []
        evening_steps: List[RoutineStepToday] = []

        active_products = [p for p in routine_products if p.enabled]
        for p in sorted(active_products, key=lambda x: x.routine_step):
            tod = (p.time_of_day or "morning").lower()
            step_item = RoutineStepToday(
                id=p.id,
                product_name=p.product_name,
                category=p.category,
                routine_step=p.routine_step,
                time_of_day=p.time_of_day,
                completed=False
            )
            if tod in ("morning", "both"):
                morning_steps.append(step_item)
            if tod in ("evening", "both"):
                evening_steps.append(step_item)

        # Generate insights
        insights = self.generate_insights(
            habits=habit_responses,
            routine_products=active_products,
            logs=logs,
            reference_date=ref
        )

        return TodayWellnessResponse(
            date=ref_str,
            morning_routine=morning_steps,
            evening_routine=evening_steps,
            habits=habit_responses,
            total_habits_count=len(habit_responses),
            completed_habits_count=completed_today_count,
            insights=insights
        )

    def generate_insights(
        self,
        habits: List[HabitResponse],
        routine_products: List[RoutineProduct],
        logs: List[HabitLog],
        reference_date: date
    ) -> List[WellnessInsight]:
        insights: List[WellnessInsight] = []

        # 1. Habit Streaks
        for h in habits:
            if h.current_streak >= 3:
                insights.append(
                    WellnessInsight(
                        type="habit_streak",
                        title=f"{h.name} Momentum",
                        description=f"You're on a {h.current_streak}-day streak for {h.name}! Consistency is building.",
                        severity="positive",
                        supporting_data={"habit_name": h.name, "streak": h.current_streak}
                    )
                )

        # 2. 7-Day Completion Consistency
        past_7_days = [(reference_date - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(7)]
        recent_completed = [l for l in logs if l.log_date in past_7_days and l.status.lower() == "completed"]
        
        if len(recent_completed) >= 5:
            insights.append(
                WellnessInsight(
                    type="routine_consistency",
                    title="Weekly Wellness Momentum",
                    description=f"You logged {len(recent_completed)} habit completions over the last 7 days.",
                    severity="positive",
                    supporting_data={"completions_last_7_days": len(recent_completed)}
                )
            )
        elif not insights:
            insights.append(
                WellnessInsight(
                    type="info",
                    title="Wellness Insights",
                    description="Keep tracking to unlock wellness insights.",
                    severity="info",
                    supporting_data={"status": "insufficient_history"}
                )
            )

        return insights

wellness_service = WellnessIntelligenceService()
