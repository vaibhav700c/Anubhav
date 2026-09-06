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

# Unity streams audio in ~200ms chunks (5/sec). Running the full STT ->
# metrics -> emotion -> LLM -> TTS pipeline on every single chunk means up
# to 5 chained round-trips per second to real external APIs, which the
# receive loop can never keep up with - the socket falls behind and gets
# killed mid-processing (observed live as the connection repeatedly
# "closing without completing the close handshake" every few seconds, with
# zero coach_feedback ever returned). Instead the pipeline runs at most
# once per this many seconds, over whatever audio accumulated in between -
# this also gives Sarvam STT several seconds of continuous speech per call
# instead of 200ms fragments, which transcribes far more accurately.
#
# Was raised from 3.5s to 9s specifically to fix language-detection
# accuracy (a single real session got misdetected as Gujarati, then Tamil,
# across consecutive windows, flipping the coaching language mid-session).
# That accuracy fix now lives in SessionState.update_detected_language
# instead - a wrong detection needs 2-3 consecutive repeats before it's
# ever trusted, regardless of window size - so the window itself no longer
# has to be this wide just to protect detection. Lowered back down for a
# more responsive live transcript/score (reported live as "vague" and
# barely updating at 9s), while still giving Sarvam STT a few real seconds
# of continuous speech per call rather than the 200ms raw chunks Unity
# streams at.
PIPELINE_WINDOW_SEC = 4.0

# Hindi and English are the two languages actually in active use/testing
# right now (explicit direction, after every real misdetection observed
# live this session ran the same direction: genuine Hindi speech getting
# misread as some OTHER Indic language - Gujarati, then Tamil, then
# Kannada, then Punjabi, in different sessions - never the reverse). See
# SessionState.update_detected_language for how this is used.
_PRIORITY_LANGUAGES = frozenset({"hi-IN", "en-IN"})


class SessionState:
    """In-memory active state for an ongoing speech session."""

    def __init__(self, session_id: str, user_id: str = "user_001", language: str = "unknown"):
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
        # Windowed-pipeline bookkeeping (see PIPELINE_WINDOW_SEC above).
        self.pending_audio: list[bytes] = []
        self.last_pipeline_run: float = self.start_time
        self.pipeline_running: bool = False
        # "unknown" (the default) means auto-detect via Sarvam STT across its
        # 22 supported Indian languages plus English - a client can still
        # request a specific one (e.g. "hi-IN") to skip detection. Once real
        # audio comes in, detected_language holds what STT actually
        # identified, which is what the LLM/TTS calls use from then on -
        # STT itself is fine being told "unknown" every time, but the LLM
        # and TTS need one concrete language to answer/speak in.
        self.language: str = language
        self.detected_language: Optional[str] = language if language != "unknown" else None
        # Debounce bookkeeping: a single noisy window can misdetect (observed
        # live - real Hindi speech misread as Gujarati, then Tamil, across
        # consecutive windows), so detected_language only actually changes
        # once the SAME new language shows up twice in a row - see
        # _update_detected_language. The very first detection of a session
        # still commits immediately (nothing to debounce against yet).
        self._pending_language: Optional[str] = None
        self._pending_language_count: int = 0

    def update_detected_language(self, detected: str) -> None:
        """Commits a new STT-detected language only once it's been seen
        enough times in a row, so one noisy window can't flip the whole
        session's coaching language by itself. Bootstraps immediately if
        nothing is set yet.

        Once locked onto Hindi or English, leaving requires 3 consecutive
        detections of something else instead of the normal 2 - every real
        misdetection observed live has been genuine Hindi speech misread as
        some other Indic language (Gujarati, Tamil, Kannada, Punjabi, Odia,
        in different sessions), never the other way round, so the extra bar
        only makes it harder to wrongly leave hi-IN/en-IN, not to correctly
        switch away from them when the speaker really does. A correction
        back TO hi-IN/en-IN keeps the normal 2-in-a-row bar.

        The very first detection of a session is a special case: a non-
        priority language still bootstraps as PENDING rather than committing
        outright, and needs one more matching detection before it becomes
        session.detected_language - otherwise a single misread first window
        (observed live: Odia, immediately, on session start) locks in wrong
        before there's anything to debounce against at all. Hindi/English
        still bootstrap immediately, since those are the two actually being
        used - effective_language falls back to en-IN while nothing is
        confirmed yet, so a session isn't left without a language mid-lock.
        """
        if self.detected_language is None:
            if detected in _PRIORITY_LANGUAGES:
                self.detected_language = detected
                self._pending_language = None
                self._pending_language_count = 0
                return
            if detected == self._pending_language:
                self._pending_language_count += 1
            else:
                self._pending_language = detected
                self._pending_language_count = 1
            if self._pending_language_count >= 2:
                self.detected_language = detected
                self._pending_language = None
                self._pending_language_count = 0
            return
        if detected == self.detected_language:
            self._pending_language = None
            self._pending_language_count = 0
            return
        if detected == self._pending_language:
            self._pending_language_count += 1
        else:
            self._pending_language = detected
            self._pending_language_count = 1
        required_streak = (
            3
            if self.detected_language in _PRIORITY_LANGUAGES and detected not in _PRIORITY_LANGUAGES
            else 2
        )
        if self._pending_language_count >= required_streak:
            self.detected_language = detected
            self._pending_language = None
            self._pending_language_count = 0


class WebSocketHub:
    """Central orchestrator managing active sessions and WebSocket connections."""

    def __init__(self):
        self.active_sessions: Dict[str, SessionState] = {}
        self.sarvam = SarvamService()
        self.metrics = MetricsService()
        self.scoring = ScoringService()
        self.emotion_svc = EmotionService()
        self.xai = XAIService()

    def get_or_create_session(
        self, session_id: str, user_id: str = "user_001", language: str = "unknown"
    ) -> SessionState:
        if session_id not in self.active_sessions:
            self.active_sessions[session_id] = SessionState(session_id, user_id, language=language)
        return self.active_sessions[session_id]

    async def register(
        self, websocket: WebSocket, session_id: str, client_type: str = "app", language: str = "unknown"
    ):
        """Register a new WebSocket connection."""
        await websocket.accept()
        session = self.get_or_create_session(session_id, language=language)

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
        """Entry point for every incoming audio/speech frame from the VR
        headset. Just buffers audio and returns immediately - the actual
        pipeline is gated to run at most once per PIPELINE_WINDOW_SEC by
        _maybe_run_pipeline, so the WebSocket receive loop this is called
        from never blocks for multiple chained external-API round-trips.
        """
        session = self.get_or_create_session(session_id)
        if session.mock_task and not session.mock_task.done():
            session.mock_task.cancel()

        if text_chunk:
            # Text-chunk path (manual/simulated testing) is already a
            # complete utterance - run it immediately, no windowing needed.
            await self._run_pipeline_guarded(session_id, combined_audio=None, transcript_override=text_chunk)
            return

        if audio_chunk:
            session.audio_chunks.append(audio_chunk)
            session.pending_audio.append(audio_chunk)

        await self._maybe_run_pipeline(session_id)

    async def _maybe_run_pipeline(self, session_id: str):
        """Fires the heavy pipeline only if enough time has passed since the
        last run and no run is already in flight - see PIPELINE_WINDOW_SEC."""
        session = self.get_or_create_session(session_id)
        now = time.time()
        if (
            session.pipeline_running
            or not session.pending_audio
            or (now - session.last_pipeline_run) < PIPELINE_WINDOW_SEC
        ):
            return

        combined_audio = b"".join(session.pending_audio)
        session.pending_audio = []
        session.last_pipeline_run = now
        session.pipeline_running = True
        try:
            await self._run_pipeline_guarded(session_id, combined_audio=combined_audio)
        finally:
            session.pipeline_running = False

    async def _run_pipeline_guarded(self, session_id: str, **kwargs):
        """Wraps _run_pipeline so a transient failure in a real external call
        (Sarvam/Hume timeout, rate limit, transient 5xx) is logged and
        swallowed instead of propagating out of the WebSocket route handler -
        an uncaught exception there aborts the ASGI connection outright,
        which surfaces to the client as exactly the "closed without
        completing the close handshake" error observed live, killing the
        whole session over one bad API call instead of just skipping a
        window's worth of feedback."""
        try:
            await self._run_pipeline(session_id, **kwargs)
        except Exception:
            logger.exception(
                f"Pipeline run failed for session {session_id} - skipping this window "
                "so the connection stays alive for the next one."
            )

    async def _run_pipeline(
        self,
        session_id: str,
        combined_audio: Optional[bytes],
        transcript_override: Optional[str] = None,
    ):
        """Runs STT -> metrics -> scoring -> emotion -> LLM -> TTS once over
        a window of accumulated audio (or an already-complete text chunk)."""
        session = self.get_or_create_session(session_id)
        pipeline_started = time.time()
        audio_sec = len(combined_audio) / 32000 if combined_audio else 0.0
        logger.info(
            f"[{session_id}] pipeline window starting: "
            f"{'transcript_override' if transcript_override else f'{audio_sec:.1f}s audio'}"
        )

        # 1. Speech-to-text via Sarvam Saaras, over the whole window at once.
        # session.language is "unknown" unless a client asked for a specific
        # one, which tells Sarvam to auto-detect - real STT responses carry
        # back which of its 22 supported languages (+ English) it actually
        # heard, which becomes session.detected_language for every step
        # after this one (the LLM needs to answer in it, TTS needs to speak
        # in it - neither can take "unknown" the way STT can).
        transcript_text = transcript_override or ""
        if combined_audio and not transcript_override:
            stt_result = await self.sarvam.transcribe_audio_chunk(
                combined_audio, language_code=session.language
            )
            transcript_text = stt_result.get("transcript", "")
            detected = stt_result.get("language_code")
            if detected and detected != "unknown":
                session.update_detected_language(detected)
            for w in stt_result.get("words", []):
                session.words.append(w)
            logger.info(
                f"[{session_id}] STT result: raw_detected={detected!r} "
                f"committed_language={session.detected_language!r} "
                f"transcript={transcript_text[:80]!r}"
            )

        if transcript_text.strip():
            session.transcripts.append(transcript_text)
        else:
            # Silent/inaudible window - nothing new to score or coach on. This
            # used to return with NO log line at all, which is why a real VR
            # session where every window came back empty (background noise,
            # mic too quiet, distance from the headset) looked "stuck" with
            # zero visibility into why - score/transcript/reactions never
            # update because literally nothing gets sent for that window.
            logger.info(
                f"[{session_id}] empty transcript for this window ({audio_sec:.1f}s audio) "
                "- skipping score/coaching update, nothing sent to client."
            )
            return

        full_transcript = " ".join(session.transcripts)

        # 2. Extract metrics
        elapsed_sec = time.time() - session.start_time
        metrics_feats = self.metrics.extract_all_metrics(
            full_transcript,
            words=session.words,
            audio_bytes=combined_audio,
            total_duration_sec=elapsed_sec,
        )

        # 3. Compute score
        score_data = self.scoring.compute_fluency_score(metrics_feats)
        session.current_score = score_data["overall_score"]

        # 4. Emotion sensing
        emotion_data = await self.emotion_svc.get_emotion(
            audio_bytes=combined_audio,
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
        logger.info(
            f"[{session_id}] score={session.current_score} emotion={flutter_label} "
            f"(+{time.time() - pipeline_started:.1f}s so far)"
        )

        # 5. Broadcast live telemetry frame to Flutter companion app
        live_frame = {
            "score": session.current_score,
            "emotion_label": flutter_label,
            # The accumulated transcript so far, not just this window's raw
            # ~9s fragment. This used to send only transcript_text, which
            # made the VR live-transcript panel replace its text with a
            # short, disconnected snippet on every update (and go visibly
            # stale on any silent/noisy window, which never broadcasts at
            # all - see the empty-transcript branch above) - reported live
            # as the transcript looking "vague" and only really readable at
            # the start and end of a session. Unity's UpdateLiveTranscript
            # already trims to its own liveTranscriptMaxChars (160) showing
            # the tail with "..." - sending more context here just gives it
            # a coherent running view to trim from instead of one fragment.
            "transcript_partial": full_transcript[-300:],
            "coaching_tip": "Keep steady cadence" if session.current_score > 70 else "Pause before next slide",
            "is_final": False,
            "disclaimer": settings.DISCLAIMER,
        }
        await self.broadcast_to_app(session_id, live_frame)

        # 6. Generate Coaching reply & TTS if appropriate - both in whatever
        # language STT actually detected (falls back to en-IN only if no
        # speech has been successfully transcribed yet this session).
        effective_language = session.detected_language or "en-IN"
        coaching_text = await self.sarvam.generate_coaching(
            transcript=transcript_text or full_transcript,
            emotion_label=session.current_emotion,
            current_score=session.current_score,
            preferred_language=effective_language,
        )
        tts_audio = await self.sarvam.synthesize_speech(
            coaching_text, target_language_code=effective_language
        )

        # Reply to VR headset
        vr_payload = {
            "type": "coach_feedback",
            "score": session.current_score,
            "emotion": session.current_emotion,
            "coaching_text": coaching_text,
        }
        await self.send_to_vr(session_id, vr_payload, audio_bytes=tts_audio)
        logger.info(
            f"[{session_id}] pipeline window done in {time.time() - pipeline_started:.1f}s total "
            f"- sent coach_feedback (lang={effective_language}, "
            f"vr_sockets={len(session.vr_sockets)}, app_sockets={len(session.app_sockets)})"
        )

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
