import uuid
from typing import Dict, Any, List, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.models.personal_ai import ActionProposalRecord, UserMemory
from app.models.productivity import Event, Task
from app.models.learning import LearningItem, Goal, StudySession, KnowledgeNote
from app.models.wardrobe import WardrobeItem
from app.models.finance import Expense, Budget
from app.models.wellness import Habit, SkincareProfile, RoutineProduct
from app.models.user import Profile, Preference
from app.schemas.personal_ai import ActionProposal

class PersonalAiTools:
    # ---------------- Read Tools (Safe, Non-Destructive) ----------------
    @staticmethod
    async def get_calendar(user_id: str, db: AsyncSession, days_ahead: int = 2) -> List[Dict[str, Any]]:
        now = datetime.utcnow()
        result = await db.execute(
            select(Event).where(
                Event.user_id == user_id,
                Event.status != "cancelled"
            ).order_by(Event.start_time.asc())
        )
        return [
            {
                "id": e.id, "title": e.title, "start_time": e.start_time.isoformat(),
                "end_time": e.end_time.isoformat(), "category": e.category, "location": e.location
            }
            for e in result.scalars().all()
        ]

    @staticmethod
    async def get_tasks(user_id: str, db: AsyncSession, status_filter: str = "Todo") -> List[Dict[str, Any]]:
        query = select(Task).where(Task.user_id == user_id)
        if status_filter != "all":
            query = query.where(Task.status == status_filter)
        result = await db.execute(query.order_by(Task.due_date.asc()))
        return [
            {
                "id": t.id, "title": t.title, "priority": t.priority,
                "due_date": t.due_date.isoformat() if t.due_date else None,
                "status": t.status, "duration_minutes": t.estimated_duration_minutes
            }
            for t in result.scalars().all()
        ]

    @staticmethod
    async def get_goals(user_id: str, db: AsyncSession) -> List[Dict[str, Any]]:
        result = await db.execute(
            select(Goal).where(Goal.user_id == user_id, Goal.status == "Active").order_by(Goal.target_date.asc())
        )
        return [
            {
                "id": g.id, "title": g.title, "priority": g.priority, "progress": g.progress,
                "target_date": g.target_date.isoformat() if g.target_date else None,
                "milestones": g.milestones
            }
            for g in result.scalars().all()
        ]

    @staticmethod
    async def get_learning_items(user_id: str, db: AsyncSession) -> List[Dict[str, Any]]:
        result = await db.execute(
            select(LearningItem).where(LearningItem.user_id == user_id, LearningItem.status != "Completed")
        )
        return [
            {
                "id": li.id, "title": li.title, "type": li.type, "priority": li.priority,
                "progress": li.progress, "target_date": li.target_date.isoformat() if li.target_date else None
            }
            for li in result.scalars().all()
        ]

    @staticmethod
    async def get_wardrobe(user_id: str, db: AsyncSession, category: Optional[str] = None) -> List[Dict[str, Any]]:
        query = select(WardrobeItem).where(WardrobeItem.owner_id == user_id, WardrobeItem.status == "available")
        if category:
            query = query.where(WardrobeItem.category == category)
        result = await db.execute(query)
        return [
            {
                "id": w.id, "name": w.name, "category": w.category, "subcategory": w.subcategory,
                "primary_color": w.primary_color, "formality": w.formality, "favorite": w.favorite
            }
            for w in result.scalars().all()
        ]

    @staticmethod
    async def get_expenses(user_id: str, db: AsyncSession, limit: int = 10) -> List[Dict[str, Any]]:
        result = await db.execute(
            select(Expense).where(Expense.user_id == user_id).order_by(Expense.expense_date.desc()).limit(limit)
        )
        return [
            {
                "id": e.id, "amount": float(e.amount), "category": e.category,
                "description": e.description, "date": e.expense_date.isoformat()
            }
            for e in result.scalars().all()
        ]

    @staticmethod
    async def get_budget(user_id: str, db: AsyncSession) -> Optional[Dict[str, Any]]:
        result = await db.execute(select(Budget).where(Budget.user_id == user_id, Budget.period == "monthly"))
        b = result.scalars().first()
        if not b:
            return None
        return {"id": b.id, "amount": float(b.amount), "currency": b.currency, "period": b.period}

    @staticmethod
    async def get_habits(user_id: str, db: AsyncSession) -> List[Dict[str, Any]]:
        result = await db.execute(select(Habit).where(Habit.user_id == user_id, Habit.active == True))
        return [
            {"id": h.id, "name": h.name, "category": h.category, "target": h.target, "unit": h.unit}
            for h in result.scalars().all()
        ]

    @staticmethod
    async def get_profile(user_id: str, db: AsyncSession) -> Dict[str, Any]:
        prof_res = await db.execute(select(Profile).where(Profile.user_id == user_id))
        p = prof_res.scalars().first()
        pref_res = await db.execute(select(Preference).where(Preference.user_id == user_id))
        pref = pref_res.scalars().first()
        return {
            "display_name": p.display_name if p else "User",
            "city": p.location if p else "Default City",
            "primary_style": pref.primary_style if pref else "Casual",
            "primary_fit": pref.primary_fit if pref else "Regular",
            "preferred_colors": pref.preferred_colors if pref else []
        }

    @staticmethod
    async def search_notes(user_id: str, query: str, db: AsyncSession) -> List[Dict[str, Any]]:
        search_pattern = f"%{query.strip()}%"
        result = await db.execute(
            select(KnowledgeNote).where(
                KnowledgeNote.user_id == user_id,
                KnowledgeNote.title.ilike(search_pattern) | KnowledgeNote.content.ilike(search_pattern)
            )
        )
        return [
            {"id": n.id, "title": n.title, "tags": n.tags, "summary": n.content[:150]}
            for n in result.scalars().all()
        ]

    # ---------------- Mutation Tools (Generates ActionProposal) ----------------
    @staticmethod
    async def propose_create_task(
        user_id: str,
        title: str,
        category: str = "Personal",
        priority: str = "Medium",
        due_date: Optional[str] = None,
        duration_minutes: int = 30,
        db: AsyncSession = None
    ) -> ActionProposal:
        proposal_id = f"prop_{uuid.uuid4().hex[:8]}"
        payload = {
            "title": title,
            "category": category,
            "priority": priority,
            "due_date": due_date,
            "estimated_duration_minutes": duration_minutes
        }
        record = ActionProposalRecord(
            id=proposal_id,
            user_id=user_id,
            action_type="create_task",
            title=f"Create Task: {title}",
            description=f"Add task '{title}' ({priority} priority, {duration_minutes}m duration, due {due_date or 'today'})",
            payload=payload,
            requires_confirmation=True,
            status="pending"
        )
        if db:
            db.add(record)
            await db.commit()
            await db.refresh(record)

        return ActionProposal(
            id=proposal_id,
            action_type="create_task",
            title=record.title,
            description=record.description,
            payload=payload,
            requires_confirmation=True,
            status="pending",
            created_at=record.created_at
        )

    @staticmethod
    async def propose_create_event(
        user_id: str,
        title: str,
        start_time: str,
        end_time: str,
        category: str = "Personal",
        location: Optional[str] = None,
        db: AsyncSession = None
    ) -> ActionProposal:
        proposal_id = f"prop_{uuid.uuid4().hex[:8]}"
        payload = {
            "title": title,
            "start_time": start_time,
            "end_time": end_time,
            "category": category,
            "location": location
        }
        record = ActionProposalRecord(
            id=proposal_id,
            user_id=user_id,
            action_type="create_event",
            title=f"Schedule Event: {title}",
            description=f"Schedule calendar event '{title}' from {start_time} to {end_time}",
            payload=payload,
            requires_confirmation=True,
            status="pending"
        )
        if db:
            db.add(record)
            await db.commit()
            await db.refresh(record)

        return ActionProposal(
            id=proposal_id,
            action_type="create_event",
            title=record.title,
            description=record.description,
            payload=payload,
            requires_confirmation=True,
            status="pending",
            created_at=record.created_at
        )

    @staticmethod
    async def propose_create_study_session(
        user_id: str,
        title: str,
        planned_duration_minutes: int,
        start_time: Optional[str] = None,
        learning_item_id: Optional[str] = None,
        db: AsyncSession = None
    ) -> ActionProposal:
        proposal_id = f"prop_{uuid.uuid4().hex[:8]}"
        payload = {
            "title": title,
            "planned_duration_minutes": planned_duration_minutes,
            "start_time": start_time,
            "learning_item_id": learning_item_id
        }
        record = ActionProposalRecord(
            id=proposal_id,
            user_id=user_id,
            action_type="create_study_session",
            title=f"Schedule Study Session: {title}",
            description=f"Plan a {planned_duration_minutes}m study session for '{title}' at {start_time or 'available block'}",
            payload=payload,
            requires_confirmation=True,
            status="pending"
        )
        if db:
            db.add(record)
            await db.commit()
            await db.refresh(record)

        return ActionProposal(
            id=proposal_id,
            action_type="create_study_session",
            title=record.title,
            description=record.description,
            payload=payload,
            requires_confirmation=True,
            status="pending",
            created_at=record.created_at
        )

    # ---------------- Execution of Confirmed Proposals ----------------
    @staticmethod
    async def execute_proposal(
        proposal_id: str,
        user_id: str,
        db: AsyncSession,
        confirm: bool = True
    ) -> Dict[str, Any]:
        result = await db.execute(
            select(ActionProposalRecord).where(
                ActionProposalRecord.id == proposal_id,
                ActionProposalRecord.user_id == user_id
            )
        )
        record = result.scalars().first()
        if not record:
            return {"success": False, "status": "not_found", "message": "Proposal not found or access denied."}

        if record.status == "executed":
            return {"success": False, "status": "already_executed", "message": "Action has already been executed."}

        if not confirm:
            record.status = "rejected"
            await db.commit()
            return {"success": True, "status": "rejected", "message": f"Action '{record.title}' was cancelled by user."}

        payload = record.payload or {}
        action_type = record.action_type
        created_entity_id = None

        if action_type == "create_task":
            new_task = Task(
                id=str(uuid.uuid4()),
                user_id=user_id,
                title=payload.get("title", "Untitled Task"),
                category=payload.get("category", "Personal"),
                priority=payload.get("priority", "Medium"),
                status="Todo",
                due_date=datetime.fromisoformat(payload["due_date"]) if payload.get("due_date") else None,
                estimated_duration_minutes=payload.get("estimated_duration_minutes", 30)
            )
            db.add(new_task)
            created_entity_id = new_task.id

        elif action_type == "create_event":
            start_t = datetime.fromisoformat(payload["start_time"]) if payload.get("start_time") else datetime.utcnow()
            end_t = datetime.fromisoformat(payload["end_time"]) if payload.get("end_time") else start_t
            new_event = Event(
                id=str(uuid.uuid4()),
                user_id=user_id,
                title=payload.get("title", "Untitled Event"),
                start_time=start_t,
                end_time=end_t,
                category=payload.get("category", "Personal"),
                location=payload.get("location")
            )
            db.add(new_event)
            created_entity_id = new_event.id

        elif action_type == "create_study_session":
            start_t = datetime.fromisoformat(payload["start_time"]) if payload.get("start_time") else None
            new_session = StudySession(
                id=str(uuid.uuid4()),
                user_id=user_id,
                title=payload.get("title", "Study Session"),
                planned_duration_minutes=payload.get("planned_duration_minutes", 45),
                start_time=start_t,
                learning_item_id=payload.get("learning_item_id"),
                status="Scheduled"
            )
            db.add(new_session)
            created_entity_id = new_session.id

        record.status = "executed"
        record.executed_at = datetime.utcnow()
        await db.commit()

        return {
            "success": True,
            "status": "executed",
            "created_id": created_entity_id,
            "message": f"Successfully executed: {record.title}"
        }

personal_ai_tools = PersonalAiTools()
