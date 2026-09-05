"""Unit tests for DigitalTwinService (trend regression, projections)."""

import pytest
from app.services.digital_twin_service import DigitalTwinService


def test_fit_trend_empty():
    svc = DigitalTwinService()
    res = svc.fit_trend_and_project([])
    assert res["history_summary"] == []
    assert res["next_session_projection"] == 75.0


def test_fit_trend_single_baseline():
    svc = DigitalTwinService()
    res = svc.fit_trend_and_project([70.0])
    assert len(res["history_summary"]) == 1
    assert res["history_summary"][0]["session_index"] == 1
    assert res["history_summary"][0]["score"] == 70
    assert res["next_session_projection"] == 73.0


def test_fit_trend_multiple_sessions():
    svc = DigitalTwinService()
    scores = [60.0, 66.0, 72.0]  # Slope = +6 per session
    res = svc.fit_trend_and_project(scores)
    assert len(res["history_summary"]) == 3
    assert res["trend_slope"] > 0
    # Next session (index 4) should project to ~78
    assert 76.0 <= res["next_session_projection"] <= 80.0
