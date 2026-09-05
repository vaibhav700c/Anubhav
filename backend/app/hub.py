"""Central WebSocket Hub:
Orchestrates real-time communication between Unity VR client and Flutter mobile app.
Receives voice/text stream from VR -> runs STT -> Metrics -> Scoring -> Emotion -> TTS,
and broadcasts live telemetry (score, emotion, transcript) to the Flutter companion app.
"""

import asyncio
import json
import logging
import time
from typing import Dict, Set, Optional, Any
from fastapi import WebSocket, WebSocketDisconnect
from app.services.sarvam_service import SarvamService
from app.services.metrics_service import MetricsService
from app.services.scoring_service import ScoringService
from app.services.emotion_service import EmotionService
from app.services.xai_service import XAIService
from app.config import settings

logger = logging.getLogger("hub")


class SessionState:
    """In-memory active state for an ongoing speech session."""

    def __init__(self, session_id: str, user_id: str = "user_001"):
        self.session_id = session_id
        self.user_id = user_id
        self.start_time = time.time()
        self.transcripts: list[str] = []
        self.words: list[dict] = []
        self.emotion_timeline: list[dict] = []
        self.current_score: int = 75
        self.current_emotion: str = "Calm"
        self.audio_chunks: list[bytes] = []
        self.app_sockets: Set[WebSocket] = set()
        self.vr_sockets: Set[WebSocket] = set()
        self.mock_task: Optional[asyncio.Task] = None


class WebSocketHub:
    """Central orchestrator managing active sessions and WebSocket connections."""

    def __init__(self):
        self.active_sessions: Dict[str, SessionState] = {}
        self.sarvam = SarvamService()
        self.metrics = MetricsService()
        self.scoring = ScoringService()
        self.emotion_svc = EmotionService()
        self.xai = XAIService()

    def get_or_create_session(self, session_id: str, user_id: str = "user_001") -> SessionState:
        if session_id not in self.active_sessions:
            self.active_sessions[session_id] = SessionState(session_id, user_id)
        return self.active_sessions[session_id]

    async def register(self, websocket: WebSocket, session_id: str, client_type: str = "app"):
        """Register a new WebSocket connection."""
        await websocket.accept()
        session = self.get_or_create_session(session_id)

        if client_type == "vr":
            session.vr_sockets.add(websocket)
            logger.info(f"VR client connected to session {session_id}")
        else:
            session.app_sockets.add(websocket)
            logger.info(f"Flutter app connected to session {session_id}")

            # If mock mode is active, or no VR stream is sending data, start background telemetry simulation
            if settings.MOCK_MODE and (session.mock_task is None or session.mock_task.done()):
                session.mock_task = asyncio.create_task(self._run_mock_telemetry(session_id))

    def unregister(self, websocket: WebSocket, session_id: str):
        """Remove a disconnected socket."""
        if session_id in self.active_sessions:
            session = self.active_sessions[session_id]
            session.app_sockets.discard(websocket)
            session.vr_sockets.discard(websocket)
            if not session.app_sockets and not session.vr_sockets:
                if session.mock_task and not session.mock_task.done():
                    session.mock_task.cancel()
                logger.info(f"Session {session_id} cleaned up from active hub.")

    async def broadcast_to_app(self, session_id: str, payload: Dict[str, Any]):
        """Send live telemetry frames to all Flutter mobile apps listening to this session."""
        if session_id not in self.active_sessions:
            return
        session = self.active_sessions[session_id]
        dead_sockets = set()
        for ws in list(session.app_sockets):
            try:
                await ws.send_json(payload)
            except Exception:
                dead_sockets.add(ws)
        for ws in dead_sockets:
            session.app_sockets.discard(ws)

    async def send_to_vr(self, session_id: str, payload: Dict[str, Any], audio_bytes: Optional[bytes] = None):
        """Send coaching reply, emotion reading, and TTS audio to VR clients."""
        if session_id not in self.active_sessions:
            return
        session = self.active_sessions[session_id]
        dead_sockets = set()
        for ws in list(session.vr_sockets):
            try:
                await ws.send_json(payload)
                if audio_bytes:
                    await ws.send_bytes(audio_bytes)
            except Exception:
                dead_sockets.add(ws)
        for ws in dead_sockets:
            session.vr_sockets.discard(ws)

    async def process_incoming_vr_frame(
        self,
        session_id: str,
        audio_chunk: Optional[bytes] = None,
        text_chunk: Optional[str] = None,
    ):
        """Process incoming audio/speech chunk from VR headset."""
        session = self.get_or_create_session(session_id)

        # 1. Speech-to-text via Sarvam Saaras
        transcript_text = text_chunk or ""
        if audio_chunk:
            session.audio_chunks.append(audio_chunk)
            stt_result = await self.sarvam.transcribe_audio_chunk(audio_chunk)
            transcript_text = stt_result.get("transcript", "")
            for w in stt_result.get("words", []):
                session.words.append(w)

        if transcript_text:
            session.transcripts.append(transcript_text)

        full_transcript = " ".join(session.transcripts)

        # 2. Extract metrics
        elapsed_sec = time.time() - session.start_time
        metrics_feats = self.metrics.extract_all_metrics(
            full_transcript,
            words=session.words,
            audio_bytes=audio_chunk,
            total_duration_sec=elapsed_sec,
        )

        # 3. Compute score
        score_data = self.scoring.compute_fluency_score(metrics_feats)
        session.current_score = score_data["overall_score"]

        # 4. Emotion sensing
        emotion_data = await self.emotion_svc.get_emotion(
            audio_bytes=audio_chunk,
            features=metrics_feats,
            transcript=full_transcript,
        )
        session.current_emotion = emotion_data["emotion"]
        flutter_label = emotion_data["flutter_label"]

        # Record point in emotion timeline
        session.emotion_timeline.append({
            "time": round(elapsed_sec, 1),
            "emotion": flutter_label,
            "intensity": round(emotion_data["confidence"], 2),
        })

        # 5. Broadcast live telemetry frame to Flutter companion app
        live_frame = {
            "score": session.current_score,
            "emotion_label": flutter_label,
            "transcript_partial": transcript_text or full_transcript[-60:],
            "coaching_tip": "Keep steady cadence" if session.current_score > 70 else "Pause before next slide",
            "is_final": False,
            "disclaimer": settings.DISCLAIMER,
        }
        await self.broadcast_to_app(session_id, live_frame)

        # 6. Generate Coaching reply & TTS if appropriate
        coaching_text = await self.sarvam.generate_coaching(
            transcript=transcript_text or full_transcript,
            emotion_label=session.current_emotion,
            current_score=session.current_score,
        )
        tts_audio = await self.sarvam.synthesize_speech(coaching_text)

        # Reply to VR headset
        vr_payload = {
            "type": "coach_feedback",
            "score": session.current_score,
            "emotion": session.current_emotion,
            "coaching_text": coaching_text,
        }
        await self.send_to_vr(session_id, vr_payload, audio_bytes=tts_audio)

    async def _run_mock_telemetry(self, session_id: str):
        """Simulate realistic live WebSocket telemetry frames for Flutter app demos."""
        logger.info(f"Starting mock telemetry generator for session {session_id}")
        mock_steps = [
            (72, "confident", "Good morning everyone. Today I want to walk through our AI architecture."),
            (70, "calm", "Specifically, how we handle speech-to-text with verbatim precision."),
            (66, "nervous", "Um, matlab, our biggest hurdle was latency... but we resolved it."),
            (76, "confident", "By co-locating the metrics engine directly alongside the audio stream."),
            (82, "excited", "Notice how our Digital Twin predicts a 15% jump in fluency over time!"),
            (80, "calm", "Thank you, and I am now ready to take questions from the judges."),
        ]

        session = self.get_or_create_session(session_id)
        step_idx = 0

        while session_id in self.active_sessions and session.app_sockets:
            score, emotion, transcript = mock_steps[step_idx % len(mock_steps)]
            elapsed = round(time.time() - session.start_time, 1)

            session.current_score = score
            session.current_emotion = emotion.capitalize()
            session.transcripts.append(transcript)
            session.emotion_timeline.append({
                "time": elapsed,
                "emotion": emotion,
                "intensity": 0.85,
            })

            frame = {
                "score": score,
                "emotion_label": emotion,
                "transcript_partial": transcript,
                "coaching_tip": "Maintain eye contact" if score > 75 else "Slow down cadence slightly",
                "is_final": False,
                "disclaimer": settings.DISCLAIMER,
            }
            await self.broadcast_to_app(session_id, frame)
            step_idx += 1
            await asyncio.sleep(2.0)


# Global hub instance
hub = WebSocketHub()
