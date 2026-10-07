import re
from typing import List, Dict, Any, Set
from app.schemas.personal_ai import PersonalContextSnapshot, FilteredContext

DOMAIN_KEYWORDS: Dict[str, List[str]] = {
    "wardrobe": [
        "wear", "cloth", "outfit", "shirt", "pant", "trousers", "jacket", "shoes", "sneaker",
        "dress", "style", "wardrobe", "fashion", "look", "attire", "formal", "casual"
    ],
    "productivity": [
        "calendar", "event", "schedule", "tomorrow", "today", "tonight", "evening", "morning",
        "busy", "free", "task", "todo", "meeting", "presentation", "lecture", "time", "plan"
    ],
    "learning": [
        "study", "exam", "course", "subject", "topic", "dsa", "assignment", "certification",
        "learn", "revision", "session", "lecture", "homework"
    ],
    "project": [
        "project", "finish", "progress", "milestone", "code", "repo", "build", "deliverable"
    ],
    "finance": [
        "spend", "spent", "budget", "cost", "money", "expense", "overspend", "saving",
        "rupee", "inr", "purchase", "afford", "financial"
    ],
    "wellness": [
        "habit", "routine", "workout", "skincare", "skin", "health", "sleep", "water",
        "drink", "streak", "walk", "gym", "wellness"
    ],
    "goals": [
        "goal", "target", "milestone", "achieve", "objective", "deadline", "priority"
    ],
    "weather": [
        "weather", "rain", "rainy", "temperature", "temp", "cold", "hot", "sunny", "umbrella", "forecast"
    ],
    "notes": [
        "note", "notes", "remember", "knowledge", "summary", "doc"
    ]
}

class ContextRelevanceEngine:
    def classify_domains(self, prompt: str) -> List[str]:
        prompt_lower = prompt.lower()
        selected: Set[str] = set()

        for domain, keywords in DOMAIN_KEYWORDS.items():
            for kw in keywords:
                if re.search(r'\b' + re.escape(kw), prompt_lower):
                    selected.add(domain)
                    break

        # Comprehensive / cross-domain prompts:
        if any(p in prompt_lower for p in ["plan my", "focus on", "what should i do", "daily brief", "overview", "summary", "how is my day", "prepare"]):
            selected.update(["productivity", "learning", "goals", "wellness", "weather"])
            if "wear" in prompt_lower or "outfit" in prompt_lower:
                selected.add("wardrobe")

        # Contextual synergy rules:
        if "wardrobe" in selected:
            # Weather and tomorrow's events are directly relevant to outfit selection
            selected.add("weather")
            selected.add("productivity")

        if "project" in selected:
            selected.add("productivity")
            selected.add("goals")

        # Fallback if nothing matched: general overview
        if not selected:
            selected = {"productivity", "goals", "wellness"}

        return sorted(list(selected))

    def filter_context(self, snapshot: PersonalContextSnapshot, prompt: str) -> FilteredContext:
        domains = self.classify_domains(prompt)
        filtered_data: Dict[str, Any] = {
            "profile": {
                "display_name": snapshot.profile.get("display_name", "User"),
                "city": snapshot.profile.get("city", "Default City")
            }
        }

        # Epistemic grounding labels for context components
        epistemic: Dict[str, str] = {
            "profile": "KNOWN (Direct User Profile)"
        }

        if "productivity" in domains:
            filtered_data["upcoming_events"] = snapshot.upcoming_events
            filtered_data["today_tasks"] = snapshot.today_tasks
            filtered_data["overdue_tasks"] = snapshot.overdue_tasks
            epistemic["upcoming_events"] = "KNOWN (Calendar Events)"
            epistemic["today_tasks"] = "KNOWN (Tasks Data)"

        if "learning" in domains:
            filtered_data["learning_workload"] = snapshot.learning_workload
            epistemic["learning_workload"] = "KNOWN (Learning Repository)"

        if "project" in domains:
            filtered_data["project_workload"] = snapshot.project_workload
            filtered_data["deadlines"] = snapshot.deadlines
            epistemic["project_workload"] = "KNOWN (Projects & Deadlines)"

        if "goals" in domains:
            filtered_data["active_goals"] = snapshot.active_goals
            epistemic["active_goals"] = "KNOWN (Goals & Milestones)"

        if "finance" in domains:
            filtered_data["budget_state"] = snapshot.budget_state
            filtered_data["recent_expenses"] = snapshot.recent_expenses
            epistemic["budget_state"] = "CALCULATED (Financial Engine)"
            epistemic["recent_expenses"] = "KNOWN (Logged Expenses)"

        if "wellness" in domains:
            filtered_data["wellness_state"] = snapshot.wellness_state
            filtered_data["habits"] = snapshot.habits
            epistemic["habits"] = "KNOWN (Logged Habits & Routines)"

        if "wardrobe" in domains:
            filtered_data["wardrobe_summary"] = snapshot.wardrobe_summary
            filtered_data["style_profile"] = snapshot.style_profile
            epistemic["wardrobe_summary"] = "KNOWN (Digital Closet)"
            epistemic["style_profile"] = "KNOWN (Confirmed Style Preferences)"

        if "weather" in domains and snapshot.weather:
            filtered_data["weather"] = snapshot.weather
            epistemic["weather"] = "KNOWN (Environmental Weather API)"

        if "notes" in domains:
            filtered_data["relevant_notes"] = snapshot.relevant_notes
            epistemic["relevant_notes"] = "KNOWN (Knowledge Notes)"

        # Persistent user memories relevant to the domain
        filtered_memories = [
            m for m in snapshot.user_memories
            if m.get("domain") in domains or m.get("domain") == "general"
        ]
        if filtered_memories:
            filtered_data["user_memories"] = filtered_memories
            epistemic["user_memories"] = "KNOWN (User-Confirmed Preferences)"

        return FilteredContext(
            selected_domains=domains,
            context_data=filtered_data,
            epistemic_context=epistemic
        )

context_relevance_engine = ContextRelevanceEngine()
