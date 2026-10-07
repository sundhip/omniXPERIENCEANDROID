import hashlib
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Tuple

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.personal_ai import ProactiveInsight, ActionProposalRecord, UserMemory
from app.schemas.personal_ai import (
    PersonalContextSnapshot,
    FilteredContext,
    EpistemicLevel,
    ActionProposal,
    AssistantMessageResponse,
    DailyPersonalBrief,
    ProactiveInsightResponse
)
from app.services.personal_context_engine import personal_context_engine
from app.services.context_relevance_engine import context_relevance_engine
from app.services.personal_ai_tools import personal_ai_tools

class PersonalIntelligenceService:

    # ---------------- 1. Cross-Domain Reasoning Modules ----------------
    def reason_event_weather_wardrobe(
        self,
        events: List[Dict[str, Any]],
        weather: Optional[Dict[str, Any]],
        wardrobe: Dict[str, Any],
        style_profile: Dict[str, Any],
        user_memories: List[Dict[str, Any]]
    ) -> Tuple[str, EpistemicLevel, List[str]]:
        citations = []
        evts = events[:2]
        evt_summary = f"{evts[0]['title']} ({evts[0].get('occasion', 'Casual')})" if evts else "casual day"
        if evts:
            citations.append(f"Calendar: {evts[0]['title']}")

        # Weather context
        is_rainy = weather.get("is_rainy", False) if weather else False
        temp_c = weather.get("temperature_c", 24.0) if weather else 24.0
        cond_text = weather.get("condition_text", "Mild") if weather else "Mild"
        if weather:
            citations.append(f"Weather: {temp_c}°C, {cond_text}")

        # Memory overrides
        avoided_colors = set(style_profile.get("disliked_colors", []))
        for mem in user_memories:
            if "color" in mem.get("key", "").lower() or "color" in mem.get("value", "").lower():
                citations.append(f"Memory: {mem['value']}")

        # Available items
        sample_items = wardrobe.get("sample_items", [])
        tops = [w for w in sample_items if w.get("category") in ["Tops", "Top"] and w.get("primary_color") not in avoided_colors]
        bottoms = [w for w in sample_items if w.get("category") in ["Bottoms", "Bottom"]]
        shoes = [w for w in sample_items if w.get("category") in ["Footwear", "Shoes"]]

        top_choice = tops[0]["name"] if tops else "clean pressed shirt"
        bottom_choice = bottoms[0]["name"] if bottoms else "tailored trousers"
        shoe_choice = shoes[0]["name"] if shoes else "comfortable footwear"

        recommendation_parts = [
            f"For your upcoming {evt_summary}, I recommend pairing your {top_choice} with {bottom_choice} and {shoe_choice}."
        ]

        if is_rainy:
            recommendation_parts.append(
                f"Rain is expected ({cond_text}), so consider bringing a water-resistant layer or an umbrella and avoid porous shoes."
            )
        elif temp_c < 18.0:
            recommendation_parts.append(
                f"Temperatures will be on the cooler side ({temp_c}°C); layer with a smart jacket or knitwear."
            )
        else:
            recommendation_parts.append(
                f"Weather is pleasant at {temp_c}°C, matching your everyday {style_profile.get('primary_style', 'Casual')} aesthetic."
            )

        citations.append("Wardrobe: Available items matched with occasion")
        return " ".join(recommendation_parts), EpistemicLevel.RECOMMENDED, citations

    def reason_calendar_tasks_learning(
        self,
        events: List[Dict[str, Any]],
        tasks: List[Dict[str, Any]],
        learning_items: List[Dict[str, Any]],
        active_goals: Optional[List[Dict[str, Any]]] = None
    ) -> Tuple[str, EpistemicLevel, List[str], Optional[Dict[str, Any]]]:
        citations = []
        high_pri_tasks = [t for t in tasks if t.get("priority") in ["Urgent", "High"]]
        active_learning = [li for li in learning_items if li.get("progress", 0) < 100]
        goals = active_goals or []

        top_learn = active_learning[0] if active_learning else None
        top_task = high_pri_tasks[0] if high_pri_tasks else (tasks[0] if tasks else None)
        top_goal = goals[0] if goals else None

        busy_events_count = len(events)
        plan_suggestion = None

        if top_task:
            citations.append(f"Task: {top_task['title']} ({top_task.get('priority', 'Medium')} priority)")
        if top_learn:
            citations.append(f"Learning: {top_learn['title']} ({top_learn.get('progress', 0):.0f}% done)")
        if top_goal:
            citations.append(f"Goal: {top_goal['title']} ({top_goal.get('progress', 0):.0f}% done)")
        if not citations:
            citations.append("Productivity & Priorities engine")

        if top_task and top_goal:
            msg = (
                f"Your primary focus should be '{top_task['title']}' ({top_task.get('priority', 'High')} priority), "
                f"which directly aligns with your active goal '{top_goal['title']}'."
            )
        elif top_task:
            msg = (
                f"Focus on '{top_task['title']}' first today as it is marked {top_task.get('priority', 'High')} priority. "
                f"Then review your secondary agenda."
            )
        elif top_learn:
            msg = f"Your main priority today is dedicated progress on '{top_learn['title']}' ({top_learn.get('progress', 0):.0f}% complete)."
        elif top_goal:
            msg = f"Dedicate your time toward advancing milestones for '{top_goal['title']}'."
        else:
            msg = "Your task and learning queue is clear. A great time to plan upcoming milestones or recharge."

        if busy_events_count >= 3:
            msg += f" Note: You have {busy_events_count} scheduled events, so protect your work blocks early."

        if top_learn:
            plan_suggestion = {
                "title": f"Study {top_learn['title']}",
                "planned_duration_minutes": top_learn.get("estimated_duration_minutes", 45),
                "learning_item_id": top_learn["id"]
            }

        return msg, EpistemicLevel.CALCULATED, citations, plan_suggestion

    def reason_expenses_goals(
        self,
        budget_state: Dict[str, Any],
        recent_expenses: List[Dict[str, Any]],
        active_goals: List[Dict[str, Any]]
    ) -> Tuple[str, EpistemicLevel, List[str]]:
        citations = []
        monthly_budget = budget_state.get("monthly_budget", 0.0)
        total_spent = budget_state.get("total_spent_this_month", 0.0)
        remaining = budget_state.get("remaining_budget", 0.0)
        financial_goals = [g for g in active_goals if g.get("financial_target_amount")]

        citations.append(f"Budget: Spent ₹{total_spent:,.0f} of ₹{monthly_budget:,.0f}")
        if financial_goals:
            fg = financial_goals[0]
            citations.append(f"Goal: {fg['title']} (Target ₹{fg['financial_target_amount']:,.0f})")

        if monthly_budget > 0 and total_spent > monthly_budget:
            msg = (
                f"You have currently spent ₹{total_spent:,.0f}, exceeding your monthly limit of ₹{monthly_budget:,.0f} "
                f"by ₹{total_spent - monthly_budget:,.0f}. "
                f"Discretionary spending should be curbed to avoid impacting your active savings targets."
            )
            level = EpistemicLevel.KNOWN
        elif monthly_budget > 0 and total_spent / monthly_budget > 0.8:
            pct = (total_spent / monthly_budget) * 100
            msg = (
                f"You have used {pct:.1f}% of your monthly budget (₹{total_spent:,.0f} spent, ₹{remaining:,.0f} remaining). "
                f"Pacing your non-essential expenses will safeguard your goal progress."
            )
            level = EpistemicLevel.CALCULATED
        else:
            msg = (
                f"Your spending is currently on track: ₹{total_spent:,.0f} spent with ₹{remaining:,.0f} remaining in your monthly budget."
            )
            level = EpistemicLevel.CALCULATED

        return msg, level, citations

    # ---------------- 2. Daily Personal Brief Generator ----------------
    async def generate_daily_brief(
        self,
        user_id: str,
        db: AsyncSession,
        lat: Optional[float] = None,
        lon: Optional[float] = None
    ) -> DailyPersonalBrief:
        snapshot = await personal_context_engine.build_context_snapshot(user_id, db, lat=lat, lon=lon)
        today_str = datetime.utcnow().strftime("%Y-%m-%d")
        user_name = snapshot.profile.get("display_name", "Alex")

        # Metrics
        events_count = len(snapshot.upcoming_events)
        priority_tasks_count = len([t for t in snapshot.today_tasks if t.get("priority") in ["Urgent", "High"]])
        deadlines_count = len(snapshot.deadlines)
        pending_habits = [h for h in snapshot.habits if not h.get("completed_today")]
        pending_habits_count = len(pending_habits)

        # Focus
        focus_task = None
        if snapshot.today_tasks:
            sorted_tasks = sorted(
                snapshot.today_tasks,
                key=lambda x: (0 if x.get("priority") == "Urgent" else (1 if x.get("priority") == "High" else 2))
            )
            focus_task = sorted_tasks[0]
            focus_text = f"Finish '{focus_task['title']}' ({focus_task.get('priority', 'Medium')} priority)."
        elif snapshot.learning_workload:
            focus_text = f"Progress on '{snapshot.learning_workload[0]['title']}'."
        else:
            focus_text = "Review week goals and plan upcoming milestones."

        # Plan
        if snapshot.learning_workload:
            plan_learn = snapshot.learning_workload[0]
            plan_text = f"Dedicate 45 minutes to {plan_learn['title']} during your primary free block."
        elif snapshot.upcoming_events:
            first_event = snapshot.upcoming_events[0]
            plan_text = f"Prepare for '{first_event['title']}' starting at {first_event['start_time'][11:16]}."
        else:
            plan_text = "Schedule a 30-minute deep-work session for high-priority tasks."

        # Prepare (Weather & Commute)
        weather = snapshot.weather
        if weather:
            if weather.get("is_rainy"):
                prep_text = f"Rain expected ({weather.get('condition_text')}); bring an umbrella and allow extra commute buffer."
            elif weather.get("temperature_c", 22) < 18:
                prep_text = f"Cooler weather ({weather.get('temperature_c')}°C); a warm layer is recommended."
            else:
                prep_text = f"Clear conditions ({weather.get('temperature_c')}°C); normal commute anticipated."
        else:
            prep_text = "No severe weather disruptions detected."

        # Wellness
        if pending_habits:
            wellness_text = f"{pending_habits_count} pending routine habits for today (including {pending_habits[0]['name']})."
        else:
            wellness_text = "All scheduled habits for today are completed! Great consistency."

        proactive_alerts = []
        if snapshot.overdue_tasks:
            proactive_alerts.append(f"{len(snapshot.overdue_tasks)} overdue tasks require immediate attention.")
        if snapshot.budget_state.get("over_budget"):
            proactive_alerts.append("Monthly budget exceeded. Watch discretionary spending.")

        return DailyPersonalBrief(
            date=today_str,
            greeting=f"Good day, {user_name}",
            user_name=user_name,
            events_count=events_count,
            priority_tasks_count=priority_tasks_count,
            approaching_deadlines_count=deadlines_count,
            pending_habits_count=pending_habits_count,
            focus=focus_text,
            plan=plan_text,
            prepare=prep_text,
            wellness=wellness_text,
            proactive_alerts=proactive_alerts
        )

    # ---------------- 3. Smart Daily Planning Engine ----------------
    def generate_day_plan(
        self,
        snapshot: PersonalContextSnapshot
    ) -> Tuple[str, Optional[ActionProposal]]:
        events = snapshot.upcoming_events
        tasks = snapshot.today_tasks + snapshot.overdue_tasks
        learn = snapshot.learning_workload

        lines = ["Here is your suggested schedule with realistic buffers:"]

        current_hr = 9
        for ev in events[:2]:
            lines.append(f"• {ev.get('start_time')[11:16]} – {ev.get('end_time')[11:16]}: {ev['title']} ({ev.get('category', 'Event')})")

        # Suggest high priority task
        top_task = tasks[0] if tasks else None
        top_learn = learn[0] if learn else None

        if top_task:
            lines.append(f"• 14:00 – 15:00: Deep Work: {top_task['title']} ({top_task.get('priority', 'High')})")
        if top_learn:
            lines.append(f"• 18:30 – 19:15: Study Block: {top_learn['title']} (45m duration)")

        lines.append("• 20:30: Evening wellness & habits reflection")
        lines.append("\nNote: Buffer periods are built in. Would you like me to schedule this study block?")

        # Prepare ActionProposal for confirmation
        proposal = None
        if top_learn:
            proposal_id = f"prop_{uuid.uuid4().hex[:8]}"
            payload = {
                "title": f"Study {top_learn['title']}",
                "planned_duration_minutes": 45,
                "learning_item_id": top_learn["id"]
            }
            proposal = ActionProposal(
                id=proposal_id,
                action_type="create_study_session",
                title=f"Schedule Study Session: {top_learn['title']}",
                description=f"Plan a 45-minute study block for '{top_learn['title']}' at 18:30 with 15m rest buffer.",
                payload=payload,
                requires_confirmation=True,
                status="pending",
                created_at=datetime.utcnow()
            )

        return "\n".join(lines), proposal

    # ---------------- 4. Proactive Insights Engine ----------------
    async def get_or_create_proactive_insights(
        self,
        user_id: str,
        db: AsyncSession
    ) -> List[ProactiveInsightResponse]:
        snapshot = await personal_context_engine.build_context_snapshot(user_id, db)
        today_date = datetime.utcnow().strftime("%Y-%m-%d")
        now = datetime.utcnow()

        generated_insights: List[Dict[str, Any]] = []

        # 1. Approaching deadlines with low progress
        for d in snapshot.deadlines:
            due_iso = d.get("due_date")
            if due_iso:
                due_dt = datetime.fromisoformat(due_iso)
                hours_left = (due_dt - now).total_seconds() / 3600
                if 0 <= hours_left <= 48:
                    dedup_key = f"{user_id}:deadline:{d['id']}:{today_date}"
                    generated_insights.append({
                        "dedup_key": dedup_key,
                        "insight_type": "deadline_approaching",
                        "severity": "urgent",
                        "title": f"Deadline in {int(hours_left)}h: {d['title']}",
                        "explanation": f"Task '{d['title']}' is due within {int(hours_left)} hours and is currently marked {d['status']}.",
                        "supporting_data": d,
                        "recommended_action": "Allocate immediate work block before deadline."
                    })

        # 2. Overloaded day check (>3 events scheduled)
        if len(snapshot.upcoming_events) >= 3:
            dedup_key = f"{user_id}:overloaded_day:{today_date}"
            generated_insights.append({
                "dedup_key": dedup_key,
                "insight_type": "overloaded_day",
                "severity": "warning",
                "title": f"High Workload: {len(snapshot.upcoming_events)} events today",
                "explanation": "Your calendar is tightly booked today. Consider pacing yourself and deferring non-urgent chores.",
                "supporting_data": {"event_count": len(snapshot.upcoming_events)},
                "recommended_action": "Protect 30 minutes of downtime."
            })

        # 3. Budget threshold warning
        b_state = snapshot.budget_state
        if b_state.get("over_budget"):
            dedup_key = f"{user_id}:over_budget:{today_date}"
            generated_insights.append({
                "dedup_key": dedup_key,
                "insight_type": "high_spending",
                "severity": "urgent",
                "title": "Monthly Budget Exceeded",
                "explanation": f"Current spending of ₹{b_state['total_spent_this_month']:,.0f} has exceeded your ₹{b_state['monthly_budget']:,.0f} budget.",
                "supporting_data": b_state,
                "recommended_action": "Halt discretionary purchases until the next billing cycle."
            })
        elif b_state.get("monthly_budget", 0) > 0 and b_state["total_spent_this_month"] / b_state["monthly_budget"] > 0.85:
            dedup_key = f"{user_id}:high_spending:{today_date}"
            generated_insights.append({
                "dedup_key": dedup_key,
                "insight_type": "high_spending",
                "severity": "warning",
                "title": "Budget Alert (85% Reached)",
                "explanation": f"You have spent 85% of your ₹{b_state['monthly_budget']:,.0f} monthly allocation.",
                "supporting_data": b_state,
                "recommended_action": "Review remaining month expenses."
            })

        # 4. Neglected active goals
        for g in snapshot.active_goals:
            if g.get("progress", 0) < 30 and g.get("milestones_count", 0) > 0 and g.get("completed_milestones", 0) == 0:
                dedup_key = f"{user_id}:neglected_goal:{g['id']}:{today_date}"
                generated_insights.append({
                    "dedup_key": dedup_key,
                    "insight_type": "neglected_goal",
                    "severity": "info",
                    "title": f"Goal Check-In: {g['title']}",
                    "explanation": f"Active goal '{g['title']}' has no completed milestones recorded yet.",
                    "supporting_data": g,
                    "recommended_action": "Break down the first milestone into manageable tasks."
                })

        # Persist and deduplicate
        responses = []
        for item in generated_insights:
            hash_val = hashlib.sha256(item["dedup_key"].encode()).hexdigest()[:32]

            existing = await db.execute(
                select(ProactiveInsight).where(
                    ProactiveInsight.user_id == user_id,
                    ProactiveInsight.dedup_hash == hash_val
                )
            )
            insight_rec = existing.scalars().first()

            if not insight_rec:
                insight_rec = ProactiveInsight(
                    id=f"ins_{uuid.uuid4().hex[:8]}",
                    user_id=user_id,
                    dedup_hash=hash_val,
                    insight_type=item["insight_type"],
                    severity=item["severity"],
                    title=item["title"],
                    explanation=item["explanation"],
                    supporting_data=item["supporting_data"],
                    recommended_action=item.get("recommended_action"),
                    dismissed=False,
                    cooldown_until=now + timedelta(hours=24),
                    expires_at=now + timedelta(days=2)
                )
                db.add(insight_rec)
                await db.commit()
                await db.refresh(insight_rec)

            if not insight_rec.dismissed:
                responses.append(ProactiveInsightResponse(
                    id=insight_rec.id,
                    insight_type=insight_rec.insight_type,
                    severity=insight_rec.severity,
                    title=insight_rec.title,
                    explanation=insight_rec.explanation,
                    supporting_data=insight_rec.supporting_data or {},
                    recommended_action=insight_rec.recommended_action,
                    dismissed=insight_rec.dismissed,
                    created_at=insight_rec.created_at
                ))

        return responses

    # ---------------- 5. Unified Assistant Query Processing ----------------
    async def process_assistant_query(
        self,
        prompt: str,
        user_id: str,
        db: AsyncSession,
        lat: Optional[float] = None,
        lon: Optional[float] = None
    ) -> AssistantMessageResponse:
        snapshot = await personal_context_engine.build_context_snapshot(user_id, db, lat=lat, lon=lon)
        filtered_ctx = context_relevance_engine.filter_context(snapshot, prompt)
        prompt_lower = prompt.lower()

        domains = filtered_ctx.selected_domains
        citations: List[str] = []
        epistemic_level = EpistemicLevel.RECOMMENDED
        action_proposal: Optional[ActionProposal] = None
        followups: List[str] = []
        response_text = ""

        # Intent 1: "What should I wear" / Wardrobe
        if any(w in prompt_lower for w in ["wear", "outfit", "cloth", "dress"]):
            response_text, epistemic_level, citations = self.reason_event_weather_wardrobe(
                events=snapshot.upcoming_events,
                weather=snapshot.weather,
                wardrobe=snapshot.wardrobe_summary,
                style_profile=snapshot.style_profile,
                user_memories=snapshot.user_memories
            )
            followups = ["Can I see an alternative outfit?", "What shoes match best?"]

        # Intent 2: "Plan my day" / "Plan tomorrow" / "Plan my evening"
        elif any(p in prompt_lower for p in ["plan my", "plan tomorrow", "plan evening"]):
            response_text, action_proposal = self.generate_day_plan(snapshot)
            epistemic_level = EpistemicLevel.RECOMMENDED
            citations = ["Calendar: Active schedule & events", "Learning: Top active subject"]
            if action_proposal:
                # Save proposal record in db so it can be confirmed later
                record = ActionProposalRecord(
                    id=action_proposal.id,
                    user_id=user_id,
                    action_type=action_proposal.action_type,
                    title=action_proposal.title,
                    description=action_proposal.description,
                    payload=action_proposal.payload,
                    requires_confirmation=True,
                    status="pending"
                )
                db.add(record)
                await db.commit()
            followups = ["Confirm this plan", "Adjust the study duration"]

        # Intent 3: "What should I focus on" / Focus & Priorities
        elif any(f in prompt_lower for f in ["focus on", "most important", "priorities", "priority"]):
            response_text, epistemic_level, citations, plan_sugg = self.reason_calendar_tasks_learning(
                events=snapshot.upcoming_events,
                tasks=snapshot.today_tasks,
                learning_items=snapshot.learning_workload,
                active_goals=snapshot.active_goals
            )
            followups = ["Plan my schedule around this", "Show my deadlines"]

        # Intent 4: "Can I finish my project" / Project Feasibility
        elif "project" in prompt_lower and any(w in prompt_lower for w in ["finish", "time", "deadline", "progress"]):
            projects = snapshot.project_workload
            if projects:
                p = projects[0]
                citations.append(f"Project: {p['title']} ({p.get('progress', 0):.0f}% complete)")
                deadlines_count = len(snapshot.deadlines)
                if p.get("progress", 0) > 70:
                    response_text = f"At your current progress of {p.get('progress', 0):.0f}%, you are well-positioned to finish '{p['title']}'. Ensure remaining tasks are completed before target date."
                    epistemic_level = EpistemicLevel.CALCULATED
                else:
                    response_text = f"Your project '{p['title']}' is currently at {p.get('progress', 0):.0f}% with {deadlines_count} approaching deadlines. The timeline is tight; allocating dedicated deep-work blocks is strongly recommended."
                    epistemic_level = EpistemicLevel.CALCULATED
            else:
                response_text = "You do not have any active project flagged in your dashboard. You can create one in the Learning & Projects module."
                epistemic_level = EpistemicLevel.KNOWN
            followups = ["Schedule project study session", "View project tasks"]

        # Intent 5: "How much did I spend" / "Am I overspending" / Finances
        elif any(w in prompt_lower for w in ["spend", "spent", "budget", "money", "overspending"]):
            response_text, epistemic_level, citations = self.reason_expenses_goals(
                budget_state=snapshot.budget_state,
                recent_expenses=snapshot.recent_expenses,
                active_goals=snapshot.active_goals
            )
            followups = ["View expense breakdown", "Check savings goals"]

        # Intent 6: Remind me / Add task / Schedule study
        elif prompt_lower.startswith("remind me") or "add task" in prompt_lower or "study dsa" in prompt_lower:
            task_title = prompt.replace("Remind me to", "").replace("remind me to", "").strip()
            if not task_title:
                task_title = "Study DSA tonight"

            action_proposal = await personal_ai_tools.propose_create_task(
                user_id=user_id,
                title=task_title,
                priority="High",
                due_date=datetime.utcnow().strftime("%Y-%m-%d"),
                db=db
            )
            response_text = f"I've prepared a high-priority task for '{task_title}'. Confirm to schedule it on your task board."
            epistemic_level = EpistemicLevel.RECOMMENDED
            citations.append("Action: Task creation proposal prepared with confirmation gate")
            followups = ["Confirm task", "Change priority to Medium"]

        # Intent 7: "What do I have tomorrow?" / Calendar & schedule query
        elif "tomorrow" in prompt_lower or "schedule" in prompt_lower:
            evs = snapshot.upcoming_events
            if evs:
                ev_list = ", ".join([f"{e['title']} at {e['start_time'][11:16]}" for e in evs])
                response_text = f"You have {len(evs)} scheduled event(s): {ev_list}. In addition, you have {len(snapshot.today_tasks)} active tasks on your agenda."
                epistemic_level = EpistemicLevel.KNOWN
                citations.append(f"Calendar: {len(evs)} events retrieved")
            else:
                response_text = f"You have no scheduled events for tomorrow. Your agenda is completely open, with {len(snapshot.today_tasks)} tasks to complete."
                epistemic_level = EpistemicLevel.KNOWN
                citations.append("Calendar: 0 events found")
            followups = ["Plan my day", "What should I wear?"]

        # Default fallback: Cross-domain daily summary
        else:
            brief = await self.generate_daily_brief(user_id, db, lat=lat, lon=lon)
            response_text = f"{brief.greeting}. Today you have {brief.events_count} event(s) and {brief.priority_tasks_count} priority task(s). Focus: {brief.focus}"
            epistemic_level = EpistemicLevel.RECOMMENDED
            citations.append("Daily Brief: Context cross-domain synthesis")
            followups = ["Plan my day", "What should I wear?", "Check budget"]

        return AssistantMessageResponse(
            id=f"msg_{uuid.uuid4().hex[:8]}",
            prompt=prompt,
            response=response_text,
            epistemic_level=epistemic_level,
            referenced_domains=domains,
            citations=citations,
            action_proposal=action_proposal,
            suggested_followups=followups,
            created_at=datetime.utcnow()
        )

personal_intelligence_service = PersonalIntelligenceService()
