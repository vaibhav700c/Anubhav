"""Unit tests for MetricsService (Tier 1 timing, Tier 2 fluency, Tier 3 acoustic)."""

import pytest
from app.services.metrics_service import MetricsService


def test_tier1_timing():
    svc = MetricsService()
    words = [
        {"word": "Hello", "start_time": 0.0, "end_time": 0.5},
        {"word": "world", "start_time": 0.6, "end_time": 1.0},
        # Gap of 0.8s -> pause detected
        {"word": "welcome", "start_time": 1.8, "end_time": 2.3},
        {"word": "here", "start_time": 2.4, "end_time": 2.8},
    ]
    res = svc.compute_tier1_timing(words, total_duration_sec=3.0)
    assert res["wpm"] > 0
    assert res["pause_count"] == 1
    assert res["total_pause_duration"] == 0.8


def test_tier2_fluency():
    svc = MetricsService()
    transcript = "Basically, um, we achieved, matlab, great results. Let me let me explain. No wait, actually wait."
    res = svc.compute_tier2_fluency(transcript)

    assert res["filler_count"] >= 3  # "basically", "um", "matlab"
    assert res["filler_rate"] > 0.0
    assert res["repetition_count"] >= 1  # "let me let me"
    assert res["self_correction_count"] >= 2  # "no wait", "actually wait"


def test_tier3_acoustic_fallback():
    svc = MetricsService()
    res = svc.compute_tier3_acoustic(None)
    assert "mean_f0_hz" in res
    assert "rms_loudness" in res
    assert "jitter_local" in res
    assert "shimmer_local" in res
    assert "arousal_raw" in res
    assert res["is_fallback"] is True


def test_extract_all_metrics():
    svc = MetricsService()
    transcript = "Good morning everyone. This is our project Anubhav."
    features = svc.extract_all_metrics(transcript)
    assert "wpm" in features
    assert "filler_rate" in features
    assert "prosody_variance" in features
    assert "arousal_raw" in features
