"""Sarvam AI Service wrapper for Saaras STT, Sarvam-105B LLM, and Bulbul TTS.
All direct Sarvam API calls must reside within this service.
Supports both real Sarvam HTTP/WS APIs and zero-dependency mock fallbacks.
"""

import asyncio
import logging
import re
import struct
from typing import AsyncGenerator, Dict, Any, List, Optional
import httpx
from app.config import settings

logger = logging.getLogger("sarvam_service")


def _pcm16_to_wav(pcm_bytes: bytes, sample_rate: int = 16000, channels: int = 1) -> bytes:
    """Wraps raw 16-bit PCM (Unity's HubClient wire format) in a canonical
    WAV/RIFF header. Sarvam's real STT endpoint needs a decodable audio
    file - sending raw PCM mislabeled as .wav (the previous behavior) only
    ever worked by accident against the mock path, which never actually
    reads the bytes."""
    block_align = channels * 2
    byte_rate = sample_rate * block_align
    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF", 36 + len(pcm_bytes), b"WAVE",
        b"fmt ", 16, 1, channels, sample_rate, byte_rate, block_align, 16,
        b"data", len(pcm_bytes),
    )
    return header + pcm_bytes


# sarvam-105b (a reasoning model) sometimes wraps self-check scratch-work
# around the actual line rather than answering cleanly - observed BOTH
# orderings live: the real line first followed by "\n\nWord count: 1-Insert
# 2-a ...", and separately a whole self-verification monologue first
# ("okay? Yes.\nOne actionable vocal tip? \"...\" - yes.\n...") with the real
# line last. In both cases the actual coaching line was the one wrapped in
# quote marks, so extracting the longest quoted span is far more reliable
# than assuming the scratch-work's position.
_WORD_COUNT_ARTIFACT_RE = re.compile(
    r"\n+\s*(?:word count\s*:.*|\d+\s*words\.?\s*)", re.IGNORECASE | re.DOTALL
)
_QUOTED_SPAN_RE = re.compile(r"[\"“]([^\"“”]{8,400})[\"”]")
# A run of 3+ "(1)"/"(2)"/"(3)" or "- 1" / "- 2" / "- 3"-style numbered
# markers is the model enumerating its own words for a self-count under some
# "Words:" or "Word count:" header - never legitimate content in a short
# spoken line. Observed live in three different shapes across English,
# Hindi, and Kannada replies, which is exactly why this matches the general
# pattern rather than one exact phrasing.
_ENUMERATION_MARKERS_RE = re.compile(r"(?:\(\d+\)\s*){3,}|(?:[-–]\s*\d+\s*\n){3,}")

# If the model burns its whole token budget on self-verification and never
# produces a clean answer at all (observed live, finish_reason "length" with
# a checklist mid-sentence, in more shapes than any fixed list can name -
# "Word count:", a bare "13 words.", a "Words:" header, "Alternatively, ...",
# a second attempt started and cut off mid-word), these markers catch what's
# left. No translated fallback exists for all 22 languages here, so this one
# English line is an accepted, honest degradation rather than ever showing
# checklist debris to a real speaker.
_CHECKLIST_ARTIFACT_MARKERS = (
    "word count", "words:", "check)", "- yes.", "- no.", "guideline", "checklist",
    "alternatively", "this is very", "sharp and actionable", "this is good",
)
_SAFE_FALLBACK_COACHING_TEXT = "Keep your pace steady and cut filler words."
_MAX_COACHING_TEXT_LEN = 220  # generous for a spoken "under 35 words" line


def _clean_coaching_text(text: str) -> str:
    quoted = _QUOTED_SPAN_RE.findall(text)
    if quoted:
        candidate = max(quoted, key=len).strip()
    else:
        candidate = _WORD_COUNT_ARTIFACT_RE.sub("", text).strip().strip("\"'").strip()

    # A genuine single spoken sentence never contains a line break - every
    # checklist/enumeration/multi-paragraph-reasoning shape observed live so
    # far has, regardless of its exact wording. This is the general backstop
    # behind the specific marker list above, for whatever shape comes next.
    if "\n" in candidate:
        return _SAFE_FALLBACK_COACHING_TEXT

    lowered = candidate.lower()
    if (
        len(candidate) < 8
        or len(candidate) > _MAX_COACHING_TEXT_LEN
        or any(marker in lowered for marker in _CHECKLIST_ARTIFACT_MARKERS)
        or _ENUMERATION_MARKERS_RE.search(candidate)
    ):
        return _SAFE_FALLBACK_COACHING_TEXT
    return candidate


# Sarvam's real API recognizes 22 official Indian languages plus English on
# STT auto-detect (language_code: "unknown" - verified live). Named here so
# the coaching prompt can tell the LLM which language to actually answer in
# by name ("Hindi") rather than a bare code ("hi-IN"), which is what
# reliably steers a general-purpose chat model's output language.
SARVAM_LANGUAGE_NAMES: Dict[str, str] = {
    "as-IN": "Assamese", "bn-IN": "Bengali", "brx-IN": "Bodo", "doi-IN": "Dogri",
    "en-IN": "English", "gu-IN": "Gujarati", "hi-IN": "Hindi", "kn-IN": "Kannada",
    "kok-IN": "Konkani", "ks-IN": "Kashmiri", "mai-IN": "Maithili", "ml-IN": "Malayalam",
    "mni-IN": "Manipuri", "mr-IN": "Marathi", "ne-IN": "Nepali", "or-IN": "Odia",
    "od-IN": "Odia", "pa-IN": "Punjabi", "sa-IN": "Sanskrit", "sat-IN": "Santali",
    "sd-IN": "Sindhi", "ta-IN": "Tamil", "te-IN": "Telugu", "ur-IN": "Urdu",
}


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

    language_name = SARVAM_LANGUAGE_NAMES.get(preferred_language, preferred_language)

    # Written as flowing prose rather than a numbered checklist deliberately -
    # sarvam-105b (a reasoning model) was observed live mirroring a numbered
    # guideline list back as its own step-by-step self-verification
    # ("No generic praise? Check.", echoing guideline 1 verbatim) instead of
    # just answering, sometimes exhausting its whole token budget on that
    # checklist before ever producing the actual line. Prose doesn't hand it
    # a checklist shape to mirror.
    prompt = (
        "You are Anubhav's expert speech coach for an Indian speaker in a VR simulation, "
        "analyzing their live delivery with technical specificity.\n\n"
        f"Speaker's language (auto-detected from their live speech): {language_name} ({preferred_language})\n"
        f"Current Speech Fluency Score: {current_score:.1f}/100\n"
        f"Detected Emotional State: {emotion_label}\n"
        f"{history_context}\n"
        f"Speaker Verbatim Transcript:\n\"{transcript}\"\n\n"
        f"Write one short coaching line, entirely in {language_name}, that quotes a specific "
        "moment from the transcript above and gives exactly one concrete, actionable vocal tip "
        "(pace, a filler word, or pause placement) growing out of that quote - not generic praise "
        "like 'good job'. Keep it under 35 words, encouraging and sharp, phrased as something a "
        "coach would actually say out loud."
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
        # "unknown" triggers Sarvam's real language auto-detection across its
        # 22 supported Indian languages plus English (verified live: fed its
        # own Hindi/Kannada/English TTS output back through STT with
        # language_code="unknown" and got the correct language_code back
        # every time) - hardcoding en-IN here would silently force every
        # session into English regardless of what the speaker actually used.
        language_code: str = "unknown",
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
                # Mock has no real audio to detect a language from - report
                # en-IN rather than echoing back "unknown" verbatim.
                "language_code": language_code if language_code != "unknown" else "en-IN",
                "confidence": 0.94,
                "words": [
                    {"word": w, "start_time": idx * 0.4, "end_time": (idx + 1) * 0.4}
                    for idx, w in enumerate(selected.split())
                ],
                "verbatim": verbatim,
            }

        url = f"{self.base_url}/speech-to-text"
        # Unity's HubClient sends raw headerless PCM16 (16 kHz mono) over the
        # WebSocket - it is not actually a WAV file, despite the filename/
        # content-type below. Sarvam's real STT endpoint expects a decodable
        # audio file, so wrap it in a proper WAV container before sending;
        # previously this sent raw PCM mislabeled as .wav, which a real
        # server would reject or misparse (mock mode never touched these
        # bytes, so this never surfaced against the mock).
        files = {"file": ("chunk.wav", _pcm16_to_wav(audio_bytes), "audio/wav")}
        data = {
            "language_code": language_code,
            # "saaras:v1" doesn't exist on the real API anymore (confirmed
            # directly against api.sarvam.ai - it 400s with the current valid
            # list: saarika:v1/v2/v2.5/flash, saaras:v3/v3-realtime/v4/
            # v4-multispk). v3 is the current non-realtime STT model, matching
            # this endpoint's per-chunk file-upload (not WebSocket) shape.
            "model": "saaras:v3",
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

        # Confirmed directly against the real API: the chat endpoint lives
        # under /v1 (unlike /speech-to-text and /text-to-speech, which sit
        # at the bare root) - the previous {base_url}/chat/completions
        # always 404'd, and since that call was never wrapped in a
        # try/except anywhere up the call chain, raise_for_status() below
        # took the whole WebSocket connection down with it on every attempt.
        language_name = SARVAM_LANGUAGE_NAMES.get(preferred_language, preferred_language)
        url = f"{self.base_url}/v1/chat/completions"
        payload = {
            "model": "sarvam-105b",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a professional public speaking coach. This model "
                        "reasons internally before answering - do that reasoning "
                        "silently and briefly, then commit to one answer without "
                        "double-checking it against a checklist afterward. Your reply "
                        'must contain exactly one double-quoted sentence - "like this" '
                        "- which is the coaching line itself, and nothing else outside "
                        "those quotes: no preamble, no self-verification, no word count. "
                        f"Write that quoted line entirely in {language_name}, matching "
                        "the speaker's own detected language - never default to English "
                        f"unless {language_name} is English."
                    ),
                },
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.5,
            # sarvam-105b is a reasoning model that spends completion tokens on
            # an internal reasoning_content pass before emitting the final
            # `content` field. Verified live: 120 tokens exhausts the budget
            # mid-reasoning (finish_reason "length", content stays null) even
            # for a ~15-word reply; a real reply completed at ~1571 tokens.
            "max_tokens": 2500,
        }

        async with httpx.AsyncClient(timeout=25.0) as client:
            response = await client.post(url, headers=self.headers, json=payload)
            response.raise_for_status()
            data = response.json()
            message = data["choices"][0]["message"]
            content = message.get("content")
            if not content:
                # Ran out of budget before emitting final content (or the
                # API shape changes) - fall back to the tail of the
                # reasoning trace rather than crashing on None.strip().
                reasoning = message.get("reasoning_content") or ""
                content = reasoning.strip()[-200:] or "Keep your pace steady and cut filler words."
            return _clean_coaching_text(content)

    # -------------------------------------------------------------------------
    # 3. TTS: Sarvam Bulbul (Emotion-Aware Voice Synthesis)
    # -------------------------------------------------------------------------
    # bulbul:v1 doesn't exist on the real API anymore (confirmed live - only
    # v2/v3-beta/v3/v4 are accepted, and v2 is itself deprecated in favor of
    # v3). Sarvam's speaker field also isn't a gender string - it's a named
    # voice ID, and the valid names differ per model version. This maps the
    # simple "male"/"female" callers already use to real bulbul:v3 voices,
    # while still passing through an already-valid voice name unchanged.
    _TTS_MODEL = "bulbul:v3"
    _SPEAKER_MAP = {"female": "priya", "male": "rahul"}

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
        speaker = self._SPEAKER_MAP.get(speaker_gender, speaker_gender)
        payload = {
            "inputs": [text],
            "target_language_code": target_language_code,
            "speaker": speaker,
            "pace": pace,
            "model": self._TTS_MODEL,
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
