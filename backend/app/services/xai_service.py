"""Explainable AI (XAI) Service:
Loads the trained scoring model artifact and uses SHAP TreeExplainer to attribute
the speech score to individual delivery features (pace, fillers, pauses, pitch variability).
Matches Flutter app contract: [{"feature": ..., "contribution": ..., "explanation": ...}].
"""

import os
import logging
from typing import Dict, Any, List, Optional
import numpy as np
from app.config import settings

logger = logging.getLogger("xai_service")

FEATURE_NAMES = [
    "wpm",
    "filler_rate",
    "pause_count",
    "total_pause_duration",
    "rms_loudness",
    "prosody_variance",
    "repetition_count",
    "self_correction_count",
]

FRIENDLY_FEATURE_NAMES = {
    "wpm": "Speaking Pace (WPM)",
    "filler_rate": "Filler Words",
    "pause_count": "Pause Frequency",
    "total_pause_duration": "Pause Duration",
    "rms_loudness": "Vocal Projection",
    "prosody_variance": "Pitch Modulation",
    "repetition_count": "Word Repetitions",
    "self_correction_count": "False Starts",
}


class XAIService:
    """Computes SHAP explanations over the Speech Fluency scoring model."""

    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "ml",
            "scorer.pkl",
        )
        self.model = None
        self.explainer = None
        self.base_value = 75.0
        self._load_model()

    def _load_model(self):
        """Attempt to load the serialized scorer and initialize SHAP TreeExplainer."""
        if not os.path.exists(self.model_path):
            logger.info(f"Scorer artifact not found at {self.model_path}. Will use analytical XAI fallback.")
            return

        try:
            import joblib
            import shap

            data = joblib.load(self.model_path)
            self.model = data.get("model")
            if self.model is not None:
                self.explainer = shap.TreeExplainer(self.model)
                # Base expected value
                expected_val = self.explainer.expected_value
                if isinstance(expected_val, (list, np.ndarray)):
                    self.base_value = float(expected_val[0])
                else:
                    self.base_value = float(expected_val)
                logger.info(f"SHAP TreeExplainer initialized with base value: {self.base_value:.2f}")
        except Exception as e:
            logger.warning(f"Could not initialize SHAP explainer: {e}. Analytical fallback active.")

    def explain_delivery(
        self,
        features: Dict[str, Any],
        score: Optional[float] = None,
        top_k: int = 3,
    ) -> Dict[str, Any]:
        """Compute SHAP contributions and generate human-readable explanations.

        Returns:
            {
                "base_value": float,
                "shap_breakdown": List[{"feature": ..., "contribution": ..., "explanation": ...}],
                "top_factors": List[str],
                "disclaimer": str
            }
        """
        wpm = float(features.get("wpm", 135.0))
        filler_rate = float(features.get("filler_rate", 2.0))
        pause_count = int(features.get("pause_count", 3))
        pause_dur = float(features.get("total_pause_duration", 1.8))
        rms = float(features.get("rms_loudness", 0.12))
        prosody = float(features.get("prosody_variance", 0.50))
        rep = int(features.get("repetition_count", 0))
        corr = int(features.get("self_correction_count", 0))

        feat_vector = np.array([[wpm, filler_rate, pause_count, pause_dur, rms, prosody, rep, corr]])

        # 1. SHAP TreeExplainer path
        contributions = {}
        if self.explainer is not None and self.model is not None:
            try:
                shap_values = self.explainer.shap_values(feat_vector)
                # shap_values is an array of shape (1, n_features)
                vals = shap_values[0]
                for idx, fname in enumerate(FEATURE_NAMES):
                    contributions[fname] = float(vals[idx])
            except Exception as e:
                logger.warning(f"SHAP evaluation error: {e}. Using rule-based contributions.")
                contributions = self._analytical_contributions(features)
        else:
            contributions = self._analytical_contributions(features)

        # Sort by absolute impact
        sorted_feats = sorted(contributions.items(), key=lambda x: abs(x[1]), reverse=True)

        breakdown = []
        top_factors = []
        for fname, val in sorted_feats[:top_k]:
            explanation = self._generate_explanation(fname, val, features)
            friendly_name = FRIENDLY_FEATURE_NAMES.get(fname, fname)
            breakdown.append({
                "feature": friendly_name,
                "contribution": round(val, 1),
                "explanation": explanation,
            })
            top_factors.append(f"{friendly_name}: {'+' if val > 0 else ''}{val:.1f} pts")

        return {
            "base_value": round(self.base_value, 1),
            "shap_breakdown": breakdown,
            "top_factors": top_factors,
            "disclaimer": settings.DISCLAIMER,
        }

    def _analytical_contributions(self, feats: Dict[str, Any]) -> Dict[str, float]:
        """Analytical feature attributions when SHAP explainer is offline."""
        wpm = float(feats.get("wpm", 135.0))
        filler_rate = float(feats.get("filler_rate", 2.0))
        pause_dur = float(feats.get("total_pause_duration", 1.8))
        rep = int(feats.get("repetition_count", 0))
        corr = int(feats.get("self_correction_count", 0))
        prosody = float(feats.get("prosody_variance", 0.50))

        # Attributions relative to neutral speech
        pace_contrib = 6.2 if (130 <= wpm <= 155) else (-0.4 * abs(wpm - 142.0))
        filler_contrib = 4.0 if (filler_rate <= 1.0) else (-3.0 * (filler_rate - 1.0))
        pause_contrib = -2.5 * max(0.0, pause_dur - 3.0) + (1.5 if (1.0 <= pause_dur <= 3.0) else -1.0)
        rep_contrib = -4.5 * rep
        corr_contrib = -5.0 * corr
        prosody_contrib = 5.0 * (prosody - 0.4)

        return {
            "wpm": pace_contrib,
            "filler_rate": filler_contrib,
            "pause_count": 0.5,
            "total_pause_duration": pause_contrib,
            "rms_loudness": 1.2,
            "prosody_variance": prosody_contrib,
            "repetition_count": rep_contrib,
            "self_correction_count": corr_contrib,
        }

    def _generate_explanation(self, feature: str, contribution: float, feats: Dict[str, Any]) -> str:
        """Create precise, judge-ready natural language explanations."""
        sign = "boosted" if contribution >= 0 else "lowered"
        points = f"{abs(contribution):.1f} points"

        if feature == "wpm":
            wpm = feats.get("wpm", 135)
            if contribution >= 0:
                return f"Ideal cadence ({wpm} WPM) maintained audience engagement and {sign} your score by {points}."
            return f"Speaking pace of {wpm} WPM was too {'fast' if wpm > 155 else 'slow'}, {sign} your score by {points}."

        if feature == "filler_rate":
            rate = feats.get("filler_rate", 0.0)
            if contribution >= 0:
                return f"Minimal filler usage ({rate}%) kept your articulation clear (+{points})."
            return f"High filler density ({rate}% fillers like 'um'/'like') {sign} your score by {points}."

        if feature == "total_pause_duration":
            dur = feats.get("total_pause_duration", 0.0)
            if contribution >= 0:
                return f"Deliberate pause placement ({dur}s total) gave key arguments time to sink in (+{points})."
            return f"Extended silence ({dur}s total) disrupted audience momentum, {sign} score by {points}."

        if feature == "repetition_count":
            rep = feats.get("repetition_count", 0)
            return f"Frequent phrase repetitions ({rep} times) interrupted speech continuity, {sign} score by {points}."

        if feature == "self_correction_count":
            corr = feats.get("self_correction_count", 0)
            return f"False starts and restarts ({corr} times) weakened delivery certainty, {sign} score by {points}."

        if feature == "prosody_variance":
            if contribution >= 0:
                return f"Dynamic pitch variation added expressive range, {sign} score by {points}."
            return f"Flat vocal pitch variation caused delivery to sound monotone, {sign} score by {points}."

        return f"{FRIENDLY_FEATURE_NAMES.get(feature, feature)} {sign} your overall score by {points}."
