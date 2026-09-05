"""Unit tests for ScoringService and XAIService."""

import pytest
from app.services.scoring_service import ScoringService
from app.services.xai_service import XAIService


def test_scoring_fluency():
    svc = ScoringService()
    good_features = {
        "wpm": 140.0,
        "pause_count": 3,
        "total_pause_duration": 2.1,
        "filler_rate": 0.5,
        "repetition_count": 0,
        "self_correction_count": 0,
    }
    score_res = svc.compute_fluency_score(good_features)
    assert score_res["overall_score"] >= 80
    assert "disclaimer" in score_res

    poor_features = {
        "wpm": 85.0,
        "pause_count": 8,
        "total_pause_duration": 12.0,
        "filler_rate": 8.5,
        "repetition_count": 3,
        "self_correction_count": 3,
    }
    poor_res = svc.compute_fluency_score(poor_features)
    assert poor_res["overall_score"] < 65


def test_vocal_arousal_baseline_delta():
    svc = ScoringService()
    # First session: no baseline
    delta1, baseline, interp1 = svc.compute_vocal_arousal_index(0.55, speaker_baseline=None)
    assert delta1 == 0.0
    assert baseline == 0.55
    assert "Baseline" in interp1

    # Second session: compared to speaker's own baseline
    delta2, _, interp2 = svc.compute_vocal_arousal_index(0.75, speaker_baseline=0.55)
    assert round(delta2, 2) == 0.20
    assert "Elevated" in interp2


def test_xai_explanation_structure():
    xai = XAIService()
    features = {
        "wpm": 145.0,
        "filler_rate": 4.5,
        "pause_count": 4,
        "total_pause_duration": 3.0,
        "rms_loudness": 0.15,
        "prosody_variance": 0.60,
        "repetition_count": 1,
        "self_correction_count": 0,
    }
    res = xai.explain_delivery(features, score=74.0, top_k=3)
    assert "shap_breakdown" in res
    assert len(res["shap_breakdown"]) <= 3
    for item in res["shap_breakdown"]:
        assert "feature" in item
        assert "contribution" in item
        assert "explanation" in item
        assert len(item["explanation"]) > 10
    assert "disclaimer" in res
