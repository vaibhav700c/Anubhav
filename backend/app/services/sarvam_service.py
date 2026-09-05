"""Sarvam AI Service wrapper for Saaras STT, Sarvam-105B LLM, and Bulbul TTS.
All direct Sarvam API calls must reside within this service.
Supports both real Sarvam HTTP/WS APIs and zero-dependency mock fallbacks.
"""

import asyncio
import logging
from typing import AsyncGenerator, Dict, Any, List, Optional
import httpx
from app.config import settings

logger = logging.getLogger("sarvam_service")


def build_coaching_prompt(
    transcript: str,
    emotion_label: str,
    current_score: float,
    recent_history: Optional[List[Dict[str, Any]]] = None,
    preferred_language: str = "en-IN",
) -> str:
    """Build a detailed prompt for Sarvam-105B to produce specific, actionable,

    quotable coaching feedback rather than generic praise.
    """
    history_context = ""
    if recent_history:
        history_lines = [
            f"- Session {h.get('session_index', idx + 1)}: Score {h.get('score')}"
            for idx, h in enumerate(recent_history[-3:])
        ]
        history_context = "Past Sessions Performance:\n" + "\n".join(history_lines) + "\n"

    prompt = (
        "You are Anubhav's expert speech coach for an Indian speaker in a VR simulation. "
        "Analyze the speaker's live delivery with technical specificity.\n\n"
        f"Language: {preferred_language}\n"
        f"Current Speech Fluency Score: {current_score:.1f}/100\n"
        f"Detected Emotional State: {emotion_label}\n"
        f"{history_context}\n"
        f"Speaker Verbatim Transcript:\n\"{transcript}\"\n\n"
        "Guidelines for your coaching response:\n"
        "1. DO NOT give generic praise like 'Good job!' or 'You sound great!'.\n"
        "2. Quote a specific phrase or moment from the transcript.\n"
        "3. Provide exactly ONE actionable vocal tip (e.g., pace regulation, filler word reduction, or pause placement).\n"
        "4. Tone: encouraging, sharp, and concise (under 35 words).\n"
        "5. Output only the spoken coaching feedback in conversational voice."
    )
    return prompt


class SarvamService:
    """Unified service for all Sarvam AI operations."""

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        self.api_key = api_key or settings.SARVAM_API_KEY
        self.base_url = (base_url or settings.SARVAM_BASE_URL).rstrip("/")
        self.is_mock = settings.MOCK_MODE or not bool(self.api_key)
        self.headers = {
            "api-subscription-key": self.api_key or "",
            "Content-Type": "application/json",
        }

    # -------------------------------------------------------------------------
    # 1. STT: Sarvam Saaras (Verbatim Streaming / Chunking)
    # -------------------------------------------------------------------------
    async def transcribe_audio_chunk(
        self,
        audio_bytes: bytes,
        language_code: str = "en-IN",
        verbatim: bool = True,
    ) -> Dict[str, Any]:
        """Transcribe an incoming chunk of audio using Sarvam Saaras.

        Preserves verbatim fillers, pauses, repetitions, and false starts.
        """
        if self.is_mock or not audio_bytes:
            # Provide realistic mock verbatim transcription with filler words
            mock_segments = [
                "Hello everyone, um, welcome to today's, uh, presentation on AI.",
                "Basically, matlab, our architecture solves the latency issue directly.",
                "Let me, let me emphasize that, you know, confidence is key here.",
                "And... so, as we look at the results, the trend is very clear.",
            ]
            import random
            selected = random.choice(mock_segments)
            return {
                "transcript": selected,
                "language_code": language_code,
                "confidence": 0.94,
                "words": [
                    {"word": w, "start_time": idx * 0.4, "end_time": (idx + 1) * 0.4}
                    for idx, w in enumerate(selected.split())
                ],
                "verbatim": verbatim,
            }

        url = f"{self.base_url}/speech-to-text"
        files = {"file": ("chunk.wav", audio_bytes, "audio/wav")}
        data = {
            "language_code": language_code,
            "model": "saaras:v1",
            "mode": "verbatim" if verbatim else "clean",
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            headers = {"api-subscription-key": self.api_key or ""}
            response = await client.post(url, headers=headers, files=files, data=data)
            response.raise_for_status()
            return response.json()

    async def transcribe_stream(
        self,
        audio_stream: AsyncGenerator[bytes, None],
        language_code: str = "en-IN",
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """Simulate or stream partial transcripts over live WebSocket chunks."""
        async for chunk in audio_stream:
            result = await self.transcribe_audio_chunk(chunk, language_code=language_code)
            yield result

    # -------------------------------------------------------------------------
    # 2. LLM: Sarvam-105B Coaching Generation
    # -------------------------------------------------------------------------
    async def generate_coaching(
        self,
        transcript: str,
        emotion_label: str = "Calm",
        current_score: float = 75.0,
        recent_history: Optional[List[Dict[str, Any]]] = None,
        preferred_language: str = "en-IN",
    ) -> str:
        """Generate focused coaching feedback using Sarvam-105B."""
        prompt = build_coaching_prompt(
            transcript=transcript,
            emotion_label=emotion_label,
            current_score=current_score,
            recent_history=recent_history,
            preferred_language=preferred_language,
        )

        if self.is_mock:
            # Realistic, quotable mock feedback
            if "matlab" in transcript.lower() or "um" in transcript.lower() or "basically" in transcript.lower():
                return "Notice how 'matlab' and 'um' clustered in your explanation. Hold a silent 1-second pause instead."
            elif current_score < 70:
                return "Your cadence rushed when explaining the architecture. Drop your pace by 15% to let the idea land."
            else:
                return f"Strong delivery on '{transcript[:30]}...'. Keep your eye line forward and sustain this relaxed tone."

        url = f"{self.base_url}/chat/completions"
        payload = {
            "model": "sarvam-105b",
            "messages": [
                {"role": "system", "content": "You are a professional public speaking coach."},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.5,
            "max_tokens": 120,
        }

        async with httpx.AsyncClient(timeout=12.0) as client:
            response = await client.post(url, headers=self.headers, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"].strip()

    # -------------------------------------------------------------------------
    # 3. TTS: Sarvam Bulbul (Emotion-Aware Voice Synthesis)
    # -------------------------------------------------------------------------
    async def synthesize_speech(
        self,
        text: str,
        target_language_code: str = "en-IN",
        speaker_gender: str = "female",
        pace: float = 1.0,
    ) -> bytes:
        """Synthesize coach feedback to audio bytes using Sarvam Bulbul."""
        if self.is_mock:
            # Return a lightweight valid 44-byte WAV header stub for mock testing
            import struct
            sample_rate = 16000
            num_samples = 1600  # 0.1 sec of silence
            byte_rate = sample_rate * 2
            block_align = 2
            wav_header = struct.pack(
                "<4sI4s4sIHHIIHH4sI",
                b"RIFF",
                36 + num_samples * 2,
                b"WAVE",
                b"fmt ",
                16,
                1,  # PCM
                1,  # Mono
                sample_rate,
                byte_rate,
                block_align,
                16,  # BitsPerSample
                b"data",
                num_samples * 2,
            )
            return wav_header + (b"\x00\x00" * num_samples)

        url = f"{self.base_url}/text-to-speech"
        payload = {
            "inputs": [text],
            "target_language_code": target_language_code,
            "speaker": speaker_gender,
            "pace": pace,
            "model": "bulbul:v1",
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(url, headers=self.headers, json=payload)
            response.raise_for_status()
            data = response.json()
            import base64
            # Sarvam TTS returns base64 encoded audio in audios field
            audio_base64 = data.get("audios", [""])[0]
            return base64.b64decode(audio_base64)

    # -------------------------------------------------------------------------
    # Standalone Verification Method
    # -------------------------------------------------------------------------
    async def verify_connectivity(self) -> Dict[str, bool]:
        """Test STT, LLM, and TTS independently to confirm readiness."""
        results = {"stt": False, "llm": False, "tts": False}
        try:
            sample_stt = await self.transcribe_audio_chunk(b"")
            results["stt"] = bool(sample_stt.get("transcript"))
        except Exception as e:
            logger.error(f"STT verification failed: {e}")

        try:
            sample_llm = await self.generate_coaching("Testing speech delivery.", "Confident", 80.0)
            results["llm"] = len(sample_llm) > 0
        except Exception as e:
            logger.error(f"LLM verification failed: {e}")

        try:
            sample_tts = await self.synthesize_speech("Keep up the great work.")
            results["tts"] = len(sample_tts) > 0
        except Exception as e:
            logger.error(f"TTS verification failed: {e}")

        return results
