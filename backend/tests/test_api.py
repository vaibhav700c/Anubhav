"""Integration tests for all REST and WebSocket endpoints in FastAPI Hub."""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_and_health():
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "disclaimer" in data

    resp_health = client.get("/health")
    assert resp_health.status_code == 200


def test_history_endpoint():
    resp = client.get("/history/user_001")
    assert resp.status_code == 200
    items = resp.json()
    assert isinstance(items, list)
    assert len(items) > 0
    first = items[0]
    assert "session_id" in first
    assert "date" in first
    assert "overall_score" in first


def test_session_detail_endpoint():
    resp = client.get("/session/s001")
    assert resp.status_code == 200
    data = resp.json()
    assert data["session_id"] == "s001"
    assert "overall_score" in data
    assert "emotion_timeline" in data
    assert "shap_breakdown" in data
    assert "transcript" in data
    assert "disclaimer" in data


def test_digital_twin_endpoint():
    resp = client.get("/twin/user_001")
    assert resp.status_code == 200
    data = resp.json()
    assert data["user_id"] == "user_001"
    assert "history_summary" in data
    assert "next_session_projection" in data
    assert "disclaimer" in data


def test_emotion_endpoint():
    resp = client.get("/emotion?transcript=Great+presentation&wpm=140")
    assert resp.status_code == 200
    data = resp.json()
    assert data["emotion"] in ["Confident", "Nervous", "Bored", "Excited", "Monotone", "Calm"]
    assert "flutter_label" in data
    assert "confidence" in data


def test_explain_endpoint():
    resp = client.get("/explain?session_id=s001")
    assert resp.status_code == 200
    data = resp.json()
    assert "shap_breakdown" in data
    assert len(data["shap_breakdown"]) > 0
    assert "disclaimer" in data


def test_session_complete_flow():
    payload = {
        "session_id": "test_session_999",
        "user_id": "user_001",
        "final_transcript": "Good morning. In this presentation we showcase speech analytics and coaching.",
    }
    resp = client.post("/session/complete", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "completed"
    assert data["session"]["session_id"] == "test_session_999"
    assert data["session"]["overall_score"] > 0
    assert len(data["session"]["shap_breakdown"]) > 0


def test_websocket_session():
    with client.websocket_connect("/session/live_test_123?client_type=app") as websocket:
        data = websocket.receive_json()
        assert "score" in data
        assert "emotion_label" in data
        assert "transcript_partial" in data
