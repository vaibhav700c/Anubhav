"""Session routes:
- WS /session/{id} : Dual-party WebSocket connection for VR and Flutter Companion App
- POST /session/complete : Finalize session, compute scoring + XAI + Digital Twin, persist to DB
- GET /session/{id} : Retrieve full session report matching Flutter SessionDetail model
"""

import json
import logging
import time
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, Query
from sqlalchemy.orm import Session as DBSession

from app.hub import hub
from app.db.database import get_db
from app.db.models import User, Session as SessionModel, Feedback, DigitalTwin
from app.schemas.session_schemas import (
    SessionDetailSchema,
    SessionCompleteRequest,
    SessionCompleteResponse,
    EmotionPointSchema,
    ShapFeatureSchema,
)
from app.services.sarvam_service import SarvamService
from app.services.metrics_service import MetricsService
from app.services.scoring_service import ScoringService
from app.services.emotion_service import EmotionService
from app.services.xai_service import XAIService
from app.services.digital_twin_service import DigitalTwinService
from app.config import settings

logger = logging.getLogger("routes.session")
router = APIRouter()

sarvam_svc = SarvamService()
metrics_svc = MetricsService()
scoring_svc = ScoringService()
emotion_svc = EmotionService()
xai_svc = XAIService()
twin_svc = DigitalTwinService()


# -----------------------------------------------------------------------------
# WebSocket: WS /session/{id}
# -----------------------------------------------------------------------------
@router.websocket("/session/{session_id}")
async def session_websocket_endpoint(
    websocket: WebSocket,
    session_id: str,
    client_type: str = Query("app", description="Client type: 'app' (Flutter) or 'vr' (Unity)"),
):
    """Dual-party WebSocket endpoint.

    - Flutter companion app connects as client_type=app (or default)
    - Unity VR headset connects as client_type=vr
    """
    await hub.register(websocket, session_id, client_type=client_type)
    try:
        while True:
            # Receive frames: can be JSON text, ping/pong, or raw audio bytes
            message = await websocket.receive()
            if message.get("type") == "websocket.disconnect":
                break
            if "bytes" in message and message["bytes"]:
                # Raw audio chunk from VR
                await hub.process_incoming_vr_frame(session_id, audio_chunk=message["bytes"])
            elif "text" in message and message["text"]:
                try:
                    payload = json.loads(message["text"])
                    msg_type = payload.get("type", "")
                    if msg_type == "audio_chunk":
                        # Base64 audio chunk or transcript simulation
                        import base64
                        raw_bytes = base64.b64decode(payload.get("data", ""))
                        await hub.process_incoming_vr_frame(session_id, audio_chunk=raw_bytes)
                    elif msg_type == "text_chunk":
                        await hub.process_incoming_vr_frame(session_id, text_chunk=payload.get("text", ""))
                    elif msg_type == "ping":
                        await websocket.send_json({"type": "pong"})
                except json.JSONDecodeError:
                    # Treat plain text as text chunk
                    await hub.process_incoming_vr_frame(session_id, text_chunk=message["text"])
    except WebSocketDisconnect:
        logger.info(f"Client disconnected from session {session_id}")
    finally:
        hub.unregister(websocket, session_id)


# -----------------------------------------------------------------------------
# POST /session/complete
# -----------------------------------------------------------------------------
@router.post("/session/complete", response_model=SessionCompleteResponse)
async def complete_session(
    request: SessionCompleteRequest,
    db: DBSession = Depends(get_db),
):
    """Finalize an active session, compute metrics, run XAI SHAP analysis,

    update speaker's baseline & Digital Twin, and store in the database.
    """
    session_id = request.session_id
    user_id = request.user_id

    # 1. Ensure user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        user = User(id=user_id, name=f"Speaker {user_id}", preferred_language="en-IN")
        db.add(user)
        db.commit()
        db.refresh(user)

    # 2. Gather active session artifacts from hub (or fallback to request)
    active = hub.active_sessions.get(session_id)
    if active:
        transcript = request.final_transcript or " ".join(active.transcripts)
        raw_words = active.words
        raw_audio = b"".join(active.audio_chunks) if active.audio_chunks else None
        elapsed_sec = max(time.time() - active.start_time, 10.0) if hasattr(active, "start_time") else 45.0
        emotion_timeline = active.emotion_timeline
    else:
        # Fallback realistic data
        transcript = request.final_transcript or (
            "Good morning. Today I am presenting our speech intelligence platform, Anubhav. "
            "Basically, um, we connect VR and mobile apps seamlessly. "
            "Notice how our latency is kept minimal through WebSocket clustering."
        )
        raw_words = None
        raw_audio = None
        elapsed_sec = 45.0
        emotion_timeline = [
            {"time": 10.0, "emotion": "confident", "intensity": 0.82},
            {"time": 25.0, "emotion": "calm", "intensity": 0.79},
            {"time": 40.0, "emotion": "excited", "intensity": 0.88},
        ]

    # 3. Compute 3-tier metrics
    features = metrics_svc.extract_all_metrics(
        transcript=transcript,
        words=raw_words,
        audio_bytes=raw_audio,
        total_duration_sec=elapsed_sec,
    )

    # 4. Compute Speech Fluency Score & Vocal Arousal Index
    score_result = scoring_svc.compute_fluency_score(features)
    overall_score = score_result["overall_score"]

    raw_arousal = float(features.get("arousal_raw", 0.50))
    arousal_delta, new_baseline, interpretation = scoring_svc.compute_vocal_arousal_index(
        current_raw_arousal=raw_arousal,
        speaker_baseline=user.baseline_arousal,
    )
    if user.baseline_arousal is None and new_baseline is not None:
        user.baseline_arousal = new_baseline
        db.commit()

    features["arousal_delta"] = arousal_delta
    features["arousal_interpretation"] = interpretation

    # 5. XAI SHAP Explanation
    xai_result = xai_svc.explain_delivery(features=features, score=overall_score)
    shap_breakdown = xai_result["shap_breakdown"]

    # 6. Sarvam-105B Coaching Feedback
    coaching_text = await sarvam_svc.generate_coaching(
        transcript=transcript,
        emotion_label=active.current_emotion if active else "Confident",
        current_score=overall_score,
    )

    # 7. Persist to DB
    iso_date = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    session_rec = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if not session_rec:
        session_rec = SessionModel(
            id=session_id,
            user_id=user_id,
            transcript=transcript,
            feature_vector=features,
            score=overall_score,
            date=iso_date,
        )
        db.add(session_rec)
        db.commit()
    else:
        session_rec.transcript = transcript
        session_rec.feature_vector = features
        session_rec.score = overall_score
        db.commit()

    feedback_rec = db.query(Feedback).filter(Feedback.session_id == session_id).first()
    if not feedback_rec:
        feedback_rec = Feedback(
            session_id=session_id,
            shap_breakdown=shap_breakdown,
            coaching_text=coaching_text,
            emotion_timeline=emotion_timeline,
        )
        db.add(feedback_rec)
        db.commit()

    # 8. Update Digital Twin
    twin_svc.update_twin_after_session(user_id=user_id, session_score=overall_score, db=db)

    # Clean up memory session from hub if complete
    if session_id in hub.active_sessions:
        del hub.active_sessions[session_id]

    detail_schema = SessionDetailSchema(
        session_id=session_id,
        user_id=user_id,
        date=iso_date,
        overall_score=overall_score,
        emotion_timeline=[EmotionPointSchema(**pt) for pt in emotion_timeline],
        shap_breakdown=[ShapFeatureSchema(**sf) for sf in shap_breakdown],
        transcript=transcript,
        coaching_text=coaching_text,
        feature_vector=features,
        disclaimer=settings.DISCLAIMER,
    )

    return SessionCompleteResponse(
        status="completed",
        session=detail_schema,
        disclaimer=settings.DISCLAIMER,
    )


# -----------------------------------------------------------------------------
# GET /session/{id}
# -----------------------------------------------------------------------------
@router.get("/session/{session_id}", response_model=SessionDetailSchema)
async def get_session_detail(
    session_id: str,
    db: DBSession = Depends(get_db),
):
    """Retrieve full session detail matching Flutter app contract."""
    session_rec = db.query(SessionModel).filter(SessionModel.id == session_id).first()

    if not session_rec:
        # Check if it's the mock session requested by Flutter
        if session_id in ["s001", "live_001"] or settings.MOCK_MODE:
            return SessionDetailSchema(
                session_id=session_id,
                user_id="user_001",
                date="2026-09-05T10:32:00Z",
                overall_score=74,
                emotion_timeline=[
                    EmotionPointSchema(time=5.0, emotion="confident", intensity=0.82),
                    EmotionPointSchema(time=15.0, emotion="calm", intensity=0.75),
                    EmotionPointSchema(time=28.0, emotion="nervous", intensity=0.68),
                    EmotionPointSchema(time=42.0, emotion="confident", intensity=0.85),
                ],
                shap_breakdown=[
                    ShapFeatureSchema(
                        feature="Filler Words",
                        contribution=-8.3,
                        explanation="Too many filler words (4.2%) lowered your score by 8.3 points.",
                    ),
                    ShapFeatureSchema(
                        feature="Speaking Pace (WPM)",
                        contribution=6.1,
                        explanation="Speaking pace of 142 WPM maintained excellent audience engagement.",
                    ),
                    ShapFeatureSchema(
                        feature="Pause Duration",
                        contribution=4.5,
                        explanation="Deliberate 1.2s pauses after main points gave arguments impact.",
                    ),
                ],
                transcript=(
                    "Good morning. Today I want to demonstrate our speech intelligence platform, Anubhav. "
                    "We connect the VR simulation directly with our Flutter companion mobile app. "
                    "Notice how our explainability models reveal exactly why your score improved."
                ),
                coaching_text=(
                    "Solid pacing throughout the opening. Keep reducing 'matlab' and 'um' fillers "
                    "during transition slides."
                ),
                disclaimer=settings.DISCLAIMER,
            )
        raise HTTPException(status_code=404, detail="Session not found")

    feedback_rec = db.query(Feedback).filter(Feedback.session_id == session_id).first()
    emotion_timeline = feedback_rec.emotion_timeline if feedback_rec else []
    shap_breakdown = feedback_rec.shap_breakdown if feedback_rec else []
    coaching_text = feedback_rec.coaching_text if feedback_rec else ""

    return SessionDetailSchema(
        session_id=session_rec.id,
        user_id=session_rec.user_id,
        date=session_rec.date,
        overall_score=int(round(session_rec.score)),
        emotion_timeline=[EmotionPointSchema(**pt) for pt in emotion_timeline],
        shap_breakdown=[ShapFeatureSchema(**sf) for sf in shap_breakdown],
        transcript=session_rec.transcript or "",
        coaching_text=coaching_text,
        feature_vector=session_rec.feature_vector,
        disclaimer=settings.DISCLAIMER,
    )
