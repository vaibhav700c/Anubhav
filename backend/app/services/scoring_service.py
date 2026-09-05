"""Scoring Service:
Computes the Speech Fluency Score and Vocal Arousal Index (speaker baseline delta).
Labels all derived metrics with standard model-derived proxy disclaimers.
"""

from typing import Dict, Any, Tuple, Optional
from app.config import settings


class ScoringService:
    """Computes Speech Fluency Score and baseline-relative Vocal Arousal Index."""

    def __init__(
        self,
        weight_continuity: Optional[float] = None,
        weight_pause_control: Optional[float] = None,
        weight_filler_rate: Optional[float] = None,
        weight_repetition_rate: Optional[float] = None,
        weight_self_correction: Optional[float] = None,
    ):
        self.w_cont = weight_continuity if weight_continuity is not None else settings.WEIGHT_CONTINUITY
        self.w_pause = weight_pause_control if weight_pause_control is not None else settings.WEIGHT_PAUSE_CONTROL
        self.w_filler = weight_filler_rate if weight_filler_rate is not None else settings.WEIGHT_FILLER_RATE
        self.w_rep = weight_repetition_rate if weight_repetition_rate is not None else settings.WEIGHT_REPETITION_RATE
        self.w_corr = weight_self_correction if weight_self_correction is not None else settings.WEIGHT_SELF_CORRECTION

    def compute_fluency_score(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Compute Speech Fluency Score (0 - 100) using configurable weights."""
        wpm = float(features.get("wpm", 130.0))
        pause_count = int(features.get("pause_count", 2))
        total_pause_duration = float(features.get("total_pause_duration", 1.5))
        filler_rate = float(features.get("filler_rate", 2.0))
        repetition_count = int(features.get("repetition_count", 0))
        self_correction_count = int(features.get("self_correction_count", 0))

        # 1. Continuity Sub-score (Ideal WPM ~ 130 - 155)
        if 130 <= wpm <= 155:
            s_cont = 100.0
        elif 100 <= wpm < 130:
            s_cont = 70.0 + (wpm - 100.0)
        elif 155 < wpm <= 185:
            s_cont = 100.0 - (wpm - 155.0)
        elif wpm < 100:
            s_cont = max(40.0, 70.0 - (100.0 - wpm) * 0.7)
        else:
            s_cont = max(35.0, 70.0 - (wpm - 185.0) * 0.8)

        # 2. Pause Control Sub-score (Reward natural pauses, penalize dead air)
        avg_pause = (total_pause_duration / max(pause_count, 1)) if pause_count > 0 else 0.0
        if 0.4 <= avg_pause <= 1.2:
            s_pause = 95.0
        elif avg_pause < 0.4:
            s_pause = 80.0  # Rushed, not enough pauses
        else:
            s_pause = max(30.0, 95.0 - (avg_pause - 1.2) * 25.0)

        # 3. Filler Rate Sub-score (Ideal < 1.5%, heavily penalized above 5%)
        if filler_rate <= 1.0:
            s_filler = 100.0
        elif filler_rate <= 3.0:
            s_filler = 100.0 - (filler_rate - 1.0) * 12.0
        elif filler_rate <= 6.0:
            s_filler = 76.0 - (filler_rate - 3.0) * 15.0
        else:
            s_filler = max(20.0, 31.0 - (filler_rate - 6.0) * 5.0)

        # 4. Repetition Sub-score
        s_rep = max(20.0, 100.0 - (repetition_count * 12.0))

        # 5. Self-Correction Sub-score
        s_corr = max(25.0, 100.0 - (self_correction_count * 15.0))

        # Weighted combination
        raw_score = (
            (self.w_cont * s_cont)
            + (self.w_pause * s_pause)
            + (self.w_filler * s_filler)
            + (self.w_rep * s_rep)
            + (self.w_corr * s_corr)
        )

        overall_score = round(min(max(raw_score, 10.0), 100.0), 1)

        return {
            "overall_score": int(round(overall_score)),
            "raw_score": overall_score,
            "components": {
                "continuity": round(s_cont, 1),
                "pause_control": round(s_pause, 1),
                "filler_control": round(s_filler, 1),
                "repetition_control": round(s_rep, 1),
                "self_correction_control": round(s_corr, 1),
            },
            "disclaimer": settings.DISCLAIMER,
        }

    def compute_vocal_arousal_index(
        self,
        current_raw_arousal: float,
        speaker_baseline: Optional[float] = None,
    ) -> Tuple[float, Optional[float], str]:
        """Compute Vocal Arousal Index as a delta from the speaker's own baseline.

        Never compared against a fixed population threshold.

        Returns:
            (arousal_delta, new_baseline, interpretation)
        """
        if speaker_baseline is None:
            # First session: establish current as baseline, delta is 0.0
            return 0.0, round(current_raw_arousal, 3), "Baseline Session (Neutral Reference)"

        # Session 2 onward: compute delta from speaker's established baseline
        delta = round(current_raw_arousal - speaker_baseline, 3)

        if delta > 0.15:
            interpretation = "Elevated Vocal Arousal (+delta above your personal baseline)"
        elif delta < -0.15:
            interpretation = "Subdued Vocal Arousal (-delta below your personal baseline)"
        else:
            interpretation = "Stable Vocal Arousal (Consistent with your personal baseline)"

        return delta, speaker_baseline, interpretation
