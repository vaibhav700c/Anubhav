"""Unit tests for EmotionService (normalization to 6 labels, fallback mechanism)."""

import pytest
from app.services.emotion_service import EmotionService, UNIFIED_EMOTIONS, FLUTTER_THEME_MAP


@pytest.mark.asyncio
async def test_emotion_normalized_vocabulary():
    svc = EmotionService()
    # Test confident speech cues
    res = await svc.get_emotion(
        features={"wpm": 140.0, "prosody_variance": 0.52, "filler_rate": 0.8},
        transcript="I am confident that this solution will deliver exceptional performance.",
    )
    assert res["emotion"] in UNIFIED_EMOTIONS
    assert res["flutter_label"] in FLUTTER_THEME_MAP.values()
    assert "disclaimer" in res


@pytest.mark.asyncio
async def test_emotion_nervous_cues():
    svc = EmotionService()
    res = await svc.get_emotion(
        features={"wpm": 175.0, "prosody_variance": 0.70, "filler_rate": 6.5},
        transcript="I am uncertain and not sure maybe we made a mistake.",
    )
    assert res["emotion"] in UNIFIED_EMOTIONS
    assert res["emotion"] == "Nervous"
    assert res["flutter_label"] == "nervous"


@pytest.mark.asyncio
async def test_emotion_monotone_cues():
    svc = EmotionService()
    res = await svc.get_emotion(
        features={"wpm": 120.0, "prosody_variance": 0.18, "filler_rate": 1.0},
        transcript="System operates normally within standard parameters.",
    )
    assert res["emotion"] in UNIFIED_EMOTIONS
    assert res["emotion"] in ["Monotone", "Bored"]
    assert res["flutter_label"] == "neutral"
