"""Emotion routes:
- GET /emotion : Unified emotion endpoint returning current or queried emotional signal.
Normalizes whichever source is active to the fixed 6-label set.
"""

from typing import Optional
from fastapi import APIRouter, Query
from app.schemas.emotion_schemas import EmotionResponse
from app.services.emotion_service import EmotionService

router = APIRouter()
emotion_svc = EmotionService()


@router.get("/emotion", response_model=EmotionResponse)
async def get_current_emotion(
    transcript: Optional[str] = Query(None, description="Optional current speech segment to analyze"),
    wpm: Optional[float] = Query(135.0, description="Estimated words per minute"),
    prosody_variance: Optional[float] = Query(0.50, description="Acoustic prosody variance"),
    filler_rate: Optional[float] = Query(2.0, description="Percentage filler rate"),
):
    """Unified emotion endpoint.

    Transparently resolves Hume AI EVI primary or local prosody fallback.
    Always maps to fixed 6-label vocabulary: Confident, Nervous, Bored, Excited, Monotone, Calm.
    """
    features = {
        "wpm": wpm,
        "prosody_variance": prosody_variance,
        "filler_rate": filler_rate,
        "rms_loudness": 0.12,
    }

    result = await emotion_svc.get_emotion(
        audio_bytes=None,
        features=features,
        transcript=transcript or "",
    )

    return EmotionResponse(
        emotion=result["emotion"],
        flutter_label=result["flutter_label"],
        confidence=result["confidence"],
        source=result["source"],
        raw_scores=result["raw_scores"],
        disclaimer=result.get("disclaimer"),
    )
