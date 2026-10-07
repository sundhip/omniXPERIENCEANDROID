from typing import List, Dict, Any, Optional
from datetime import datetime

class PersonalizationService:
    """
    Deterministic Personalization Service for OmniXPERIENCE.
    Converts raw user preferences, rankings, and sliders into a structured,
    reproducible PersonalStyleProfile consumed by future AI systems (Phase 3 Face AI, etc.).
    
    NO LLMs, NO mock AI, NO random numbers. Pure transparent deterministic logic.
    """

    EXPERIMENTATION_LEVELS = [
        (0.15, "Very Safe"),
        (0.35, "Mostly Classic"),
        (0.65, "Balanced"),
        (0.85, "Somewhat Experimental"),
        (1.01, "Very Experimental"),
    ]

    @classmethod
    def get_experimentation_label(cls, score: float) -> str:
        for threshold, label in cls.EXPERIMENTATION_LEVELS:
            if score <= threshold:
                return label
        return "Balanced"

    @classmethod
    def get_comfort_appearance_label(cls, score: float) -> str:
        if score < 0.4:
            return "Comfort-focused"
        elif score <= 0.6:
            return "Balanced (Comfort & Appearance)"
        else:
            return "Appearance-focused"

    @classmethod
    def calculate_priority_weights(cls, ranked_priorities: List[str]) -> Dict[str, float]:
        """
        Converts ordered priority list into normalized weights.
        Algorithm:
        Given N ranked attributes from rank 1 (highest) to N (lowest):
        weight(r) = round(1.0 - (r - 1) * (0.8 / max(1, N - 1)), 2)
        Highest rank receives 1.0, lowest receives 0.20.
        """
        if not ranked_priorities:
            return {
                "comfort": 0.8,
                "appearance": 0.8,
                "practicality": 0.7,
                "formality": 0.5,
            }
        
        n = len(ranked_priorities)
        weights = {}
        for idx, key in enumerate(ranked_priorities):
            if n <= 1:
                weight = 1.0
            else:
                weight = 1.0 - (idx * (0.8 / (n - 1)))
            weights[key] = round(weight, 2)
        return weights

    @classmethod
    def generate_summary_text(
        cls,
        primary_style: str,
        secondary_styles: List[str],
        primary_fit: str,
        preferred_colors: List[str],
        top_occasions: List[str],
        comfort_appearance_score: float,
        experimentation_score: float,
    ) -> str:
        """
        Generates deterministic summary text directly from user profile data.
        """
        parts = []
        
        # 1. Style & Fit
        style_desc = primary_style or "Casual"
        if secondary_styles:
            style_desc += f" (with touches of {', '.join(secondary_styles[:2])})"
        fit_desc = primary_fit or "Regular"
        parts.append(f"Your profile leans toward {style_desc} with {fit_desc.lower()} fits.")
        
        # 2. Colors
        if preferred_colors:
            parts.append(f"You gravitate toward {len(preferred_colors)} preferred shades.")
        
        # 3. Comfort vs Appearance
        if comfort_appearance_score < 0.4:
            parts.append("You strongly prioritize comfort and ease of movement in daily wear.")
        elif comfort_appearance_score > 0.6:
            parts.append("You prioritize sharp visual appearance and statement styling.")
        else:
            parts.append("You maintain an equal balance between all-day comfort and sharp presentation.")
            
        # 4. Occasions
        if top_occasions:
            occasions_str = ", ".join(top_occasions[:3])
            parts.append(f"You dress most frequently for {occasions_str}.")
            
        # 5. Experimentation
        exp_label = cls.get_experimentation_label(experimentation_score)
        parts.append(f"Your styling approach is {exp_label.lower()}.")
        
        return " ".join(parts)

    @classmethod
    def build_personal_style_profile(
        cls,
        primary_style: Optional[str] = None,
        secondary_styles: Optional[List[str]] = None,
        style_preferences: Optional[List[str]] = None,
        primary_fit: Optional[str] = None,
        secondary_fit: Optional[str] = None,
        fit_preference: Optional[str] = None,
        preferred_colors: Optional[List[str]] = None,
        neutral_colors: Optional[List[str]] = None,
        disliked_colors: Optional[List[str]] = None,
        colors_to_experiment: Optional[List[str]] = None,
        color_experimentation_score: float = 0.5,
        occasions: Optional[List[str]] = None,
        top_occasions: Optional[List[str]] = None,
        occasion_frequencies: Optional[Dict[str, float]] = None,
        lifestyle: Optional[List[str]] = None,
        comfort_appearance_score: float = 0.5,
        experimentation_score: float = 0.5,
        fashion_priorities_ranked: Optional[List[str]] = None,
        priorities: Optional[Dict[str, float]] = None,
        preferred_brands: Optional[List[str]] = None,
        avoided_brands: Optional[List[str]] = None,
        budget_tier: Optional[str] = None,
        version: int = 1,
    ) -> Dict[str, Any]:
        """
        Builds the complete deterministic PersonalStyleProfile dictionary.
        """
        # Resolve Primary & Secondary Style
        p_style = primary_style
        s_styles = list(secondary_styles or [])
        if not p_style and style_preferences:
            p_style = style_preferences[0]
            s_styles = style_preferences[1:]
        elif not p_style:
            p_style = "Casual"

        # Resolve Fit
        p_fit = primary_fit or fit_preference or "Regular"
        s_fit = secondary_fit

        # Calculate Priority Weights
        ranked_keys = fashion_priorities_ranked or list((priorities or {}).keys())
        calculated_weights = cls.calculate_priority_weights(ranked_keys)
        
        # Merge any explicit priorities passed
        if priorities:
            for k, v in priorities.items():
                if k not in calculated_weights:
                    calculated_weights[k] = round(float(v), 2)

        # Top Occasions
        resolved_top_occasions = list(top_occasions or [])
        if not resolved_top_occasions and occasions:
            resolved_top_occasions = occasions[:3]

        # Occasion Frequencies
        freqs = occasion_frequencies or {
            "casual": 0.9,
            "smart_casual": 0.6,
            "formal": 0.2,
            "sportswear": 0.4,
        }

        # Deterministic text synthesis
        summary = cls.generate_summary_text(
            primary_style=p_style,
            secondary_styles=s_styles,
            primary_fit=p_fit,
            preferred_colors=preferred_colors or [],
            top_occasions=resolved_top_occasions,
            comfort_appearance_score=comfort_appearance_score,
            experimentation_score=experimentation_score,
        )

        return {
            "version": version,
            "primary_style": p_style,
            "secondary_styles": s_styles,
            "primary_fit": p_fit,
            "secondary_fit": s_fit,
            "color_profile": {
                "preferred_colors": preferred_colors or [],
                "neutral_colors": neutral_colors or [],
                "disliked_colors": disliked_colors or [],
                "colors_to_experiment": colors_to_experiment or [],
                "color_experimentation_score": color_experimentation_score,
            },
            "experimentation": {
                "score": experimentation_score,
                "label": cls.get_experimentation_label(experimentation_score),
            },
            "comfort_appearance": {
                "score": comfort_appearance_score,
                "label": cls.get_comfort_appearance_label(comfort_appearance_score),
            },
            "fashion_priority_weights": calculated_weights,
            "top_occasions": resolved_top_occasions,
            "occasion_frequencies": freqs,
            "lifestyle": lifestyle or [],
            "brand_preferences": {
                "preferred_brands": preferred_brands or [],
                "avoided_brands": avoided_brands or [],
                "budget_tier": budget_tier or "Mid-range",
            },
            "summary_text": summary,
            "calculated_at": datetime.utcnow().isoformat(),
        }

    @classmethod
    def build_connected_personal_context(
        cls,
        personal_style_profile: Dict[str, Any],
        visual_profile: Optional[Dict[str, Any]] = None,
        user_profile: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Unified Context Engine Hook for future AI modules (Phase 4 Wardrobe AI, Phase 5 Outfit AI).
        Connects Person Identity, Visual Appearance Profile, and Personalization Preferences.
        Prioritizes user-confirmed attributes over unconfirmed AI detections.
        """
        vis_context = {}
        if visual_profile:
            vis_context = {
                "face_shape": visual_profile.get("confirmed_face_shape") or visual_profile.get("detected_face_shape"),
                "skin_tone": visual_profile.get("confirmed_skin_tone") or visual_profile.get("detected_skin_tone"),
                "skin_undertone": visual_profile.get("confirmed_skin_undertone") or visual_profile.get("detected_skin_undertone"),
                "hair_length": visual_profile.get("confirmed_hair_length") or visual_profile.get("detected_hair_length"),
                "hair_texture": visual_profile.get("confirmed_hair_texture") or visual_profile.get("detected_hair_texture"),
                "confirmed_by_user": visual_profile.get("confirmed_by_user", False),
                "has_visual_profile": True
            }
        else:
            vis_context = {
                "has_visual_profile": False,
                "face_shape": None,
                "skin_tone": None,
                "skin_undertone": None,
                "hair_length": None,
                "hair_texture": None,
                "confirmed_by_user": False
            }

        return {
            "personal_identity": user_profile or {},
            "style_preferences": personal_style_profile or {},
            "visual_profile": vis_context,
            "ready_for_wardrobe_ai": True,
            "context_version": "3.0.0"
        }
