from datetime import datetime
from typing import Optional
from app.schemas.learning import PriorityScoreResponse

class LearningPriorityEngine:

    @staticmethod
    def calculate_priority(
        entity_id: str,
        entity_type: str,
        title: str,
        priority_label: str = "Medium",
        target_date: Optional[datetime] = None,
        progress: float = 0.0,
        estimated_duration_minutes: int = 60
    ) -> PriorityScoreResponse:
        now = datetime.utcnow()
        
        # 1. Importance points (max 40)
        importance_map = {
            "Urgent": 40.0,
            "High": 30.0,
            "Medium": 20.0,
            "Low": 10.0
        }
        importance_pts = importance_map.get(priority_label, 20.0)

        # 2. Urgency points (max 40)
        if target_date:
            days_left = (target_date - now).total_seconds() / 86400.0
            if days_left < 0:
                urgency_pts = 40.0
                urgency_desc = "Overdue"
            elif days_left <= 2:
                urgency_pts = 35.0
                urgency_desc = f"Due in {max(0, int(days_left))}d"
            elif days_left <= 7:
                urgency_pts = 25.0
                urgency_desc = f"Due in {int(days_left)}d"
            elif days_left <= 14:
                urgency_pts = 15.0
                urgency_desc = f"Due in {int(days_left)}d"
            elif days_left <= 30:
                urgency_pts = 8.0
                urgency_desc = f"Due in {int(days_left)}d"
            else:
                urgency_pts = 5.0
                urgency_desc = f"Due in {int(days_left)}d"
        else:
            urgency_pts = 5.0
            urgency_desc = "No deadline"

        # 3. Incompletion points (max 20)
        incompletion_pct = max(0.0, 100.0 - progress)
        incompletion_pts = round(incompletion_pct * 0.20, 1)

        total_score = min(100.0, round(importance_pts + urgency_pts + incompletion_pts, 1))

        if total_score >= 75.0:
            level = "Urgent"
        elif total_score >= 55.0:
            level = "High"
        elif total_score >= 35.0:
            level = "Medium"
        else:
            level = "Low"

        rationale = (
            f"{urgency_desc} ({int(urgency_pts)} pts) + "
            f"{priority_label} importance ({int(importance_pts)} pts) + "
            f"{int(incompletion_pct)}% incomplete ({incompletion_pts} pts) = "
            f"Priority Score {total_score}/100"
        )

        return PriorityScoreResponse(
            entity_id=entity_id,
            entity_type=entity_type,
            title=title,
            priority_level=level,
            score=total_score,
            rationale=rationale
        )
