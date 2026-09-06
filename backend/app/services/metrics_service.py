"""Voice & Speech Metrics Engine implementing 3 tiers:
Tier 1: Timing (WPM, pause count/duration, speech-to-silence ratio)
Tier 2: Fluency (Filler words, repetitions, self-corrections, false starts)
Tier 3: Acoustic (Pitch f0, RMS loudness, jitter, shimmer via parselmouth/librosa)
"""

import re
import math
import logging
from typing import Dict, Any, List, Optional
import numpy as np

logger = logging.getLogger("metrics_service")


def _pcm16_bytes_to_float_array(audio_bytes: bytes) -> np.ndarray:
    """Decodes raw 16-bit little-endian PCM (Unity's HubClient wire format)
    into a float64 array in [-1, 1], as both parselmouth.Sound(values=...)
    and plain RMS/arousal math expect."""
    if len(audio_bytes) % 2:
        audio_bytes = audio_bytes[:-1]  # tolerate a truncated final byte from a partial frame
    samples = np.frombuffer(audio_bytes, dtype="<i2").astype(np.float64)
    return samples / 32768.0

# Indian English & Hinglish filler words vocabulary
COMMON_FILLERS = {
    "um", "uh", "uhh", "er", "ah", "like", "basically", "actually",
    "literally", "you know", "matlab", "yaani", "dekho", "sort of",
    "kind of", "right", "i mean", "so yeah"
}


class MetricsService:
    """Computes Tier 1, Tier 2, and Tier 3 voice & speech metrics."""

    def __init__(self):
        self._parselmouth_available = False
        try:
            import parselmouth
            self._parselmouth_available = True
        except ImportError:
            logger.warning("parselmouth not available. Acoustic metrics will use librosa / synthetic fallback.")

    # -------------------------------------------------------------------------
    # Tier 1 — Timing
    # -------------------------------------------------------------------------
    def compute_tier1_timing(
        self,
        words: List[Dict[str, Any]],
        total_duration_sec: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Compute WPM, pause count, total pause duration, and speech-to-silence ratio."""
        if not words:
            return {
                "wpm": 0.0,
                "pause_count": 0,
                "total_pause_duration": 0.0,
                "speech_to_silence_ratio": 1.0,
                "total_speech_duration": 0.0,
                "total_duration": total_duration_sec or 0.0,
            }

        word_count = len(words)
        start_time = words[0].get("start_time", 0.0)
        end_time = words[-1].get("end_time", start_time + word_count * 0.4)
        duration = total_duration_sec or max(end_time - start_time, 1.0)

        # Detect pauses (> 0.4s gap between consecutive words)
        pauses = []
        for i in range(len(words) - 1):
            curr_end = words[i].get("end_time", 0.0)
            next_start = words[i + 1].get("start_time", curr_end)
            gap = next_start - curr_end
            if gap > 0.4:
                pauses.append(gap)

        total_pause_time = sum(pauses)
        speech_time = max(duration - total_pause_time, 0.1)
        wpm = (word_count / (duration / 60.0)) if duration > 0 else 0.0
        speech_to_silence = speech_time / max(total_pause_time, 0.1)

        return {
            "wpm": round(wpm, 1),
            "pause_count": len(pauses),
            "total_pause_duration": round(total_pause_time, 2),
            "speech_to_silence_ratio": round(speech_to_silence, 2),
            "total_speech_duration": round(speech_time, 2),
            "total_duration": round(duration, 2),
        }

    # -------------------------------------------------------------------------
    # Tier 2 — Fluency
    # -------------------------------------------------------------------------
    def compute_tier2_fluency(self, verbatim_transcript: str) -> Dict[str, Any]:
        """Parse verbatim transcript to calculate filler rate, repetitions,

        self-corrections, and false starts.
        """
        if not verbatim_transcript.strip():
            return {
                "filler_count": 0,
                "filler_rate": 0.0,
                "detected_fillers": [],
                "repetition_count": 0,
                "self_correction_count": 0,
                "false_start_count": 0,
            }

        text_clean = verbatim_transcript.lower()
        words = re.findall(r"\b[\w'-]+\b", text_clean)
        total_words = max(len(words), 1)

        # 1. Fillers detection
        detected_fillers = []
        for filler in COMMON_FILLERS:
            # Handle multi-word fillers like "you know"
            if " " in filler:
                matches = len(re.findall(r"\b" + re.escape(filler) + r"\b", text_clean))
                if matches > 0:
                    detected_fillers.extend([filler] * matches)
            else:
                for w in words:
                    if w == filler:
                        detected_fillers.append(w)

        filler_count = len(detected_fillers)
        filler_rate = round((filler_count / total_words) * 100, 2)  # Percentage

        # 2. Consecutive Repetitions (single word e.g. "we we", "the the", or 2-word e.g. "let me let me")
        repetition_count = 0
        # Single-word repeats
        for i in range(len(words) - 1):
            if words[i] == words[i + 1]:
                repetition_count += 1
        # 2-word phrase repeats
        for i in range(len(words) - 3):
            if words[i:i + 2] == words[i + 2:i + 4]:
                repetition_count += 1


        # 3. Self-corrections & False starts (e.g. "I mean", "no wait", trailing dashes)
        correction_patterns = [r"\bno wait\b", r"\bi mean\b", r"\bor rather\b", r"\bactually wait\b", r"\w+--"]
        self_correction_count = 0
        for pat in correction_patterns:
            self_correction_count += len(re.findall(pat, text_clean))

        false_start_count = len(re.findall(r"\b[A-Za-z]+-\s", verbatim_transcript))

        return {
            "filler_count": filler_count,
            "filler_rate": filler_rate,
            "detected_fillers": detected_fillers[:10],
            "repetition_count": repetition_count,
            "self_correction_count": self_correction_count,
            "false_start_count": false_start_count,
        }

    # -------------------------------------------------------------------------
    # Tier 3 — Acoustic (Parselmouth / Librosa)
    # -------------------------------------------------------------------------
    def compute_tier3_acoustic(self, audio_bytes: Optional[bytes] = None) -> Dict[str, Any]:
        """Compute pitch (f0 mean/std), loudness (RMS), jitter, shimmer, prosody."""
        # Check if audio_bytes is valid
        if not audio_bytes or len(audio_bytes) < 200:
            # Return plausible baseline acoustics if audio not supplied
            return {
                "mean_f0_hz": 185.0,
                "f0_std_hz": 28.5,
                "rms_loudness": 0.12,
                "jitter_local": 0.012,
                "shimmer_local": 0.038,
                "prosody_variance": 0.65,
                "arousal_raw": 0.52,
                "is_fallback": True,
            }

        try:
            if self._parselmouth_available:
                import parselmouth
                from parselmouth.praat import call

                # audio_bytes is raw headerless PCM16 mono @ 16kHz (that's
                # exactly what Unity's HubClient streams over the WebSocket -
                # it is not a WAV/file blob). parselmouth.Sound() has no
                # constructor overload for raw bytes; the correct one here is
                # (values: ndarray, sampling_frequency) - previously this
                # passed audio_bytes directly, which always raised inside the
                # try/except and silently fell through to the fallback below.
                samples = _pcm16_bytes_to_float_array(audio_bytes)
                sound = parselmouth.Sound(values=samples, sampling_frequency=16000.0)
                pitch = sound.to_pitch()
                f0_values = pitch.selected_array["frequency"]
                voiced_f0 = f0_values[f0_values > 0]

                mean_f0 = float(np.mean(voiced_f0)) if len(voiced_f0) > 0 else 180.0
                std_f0 = float(np.std(voiced_f0)) if len(voiced_f0) > 0 else 25.0

                # Jitter & Shimmer via Praat call
                point_process = call(sound, "To PointProcess (periodic, cc)", 75, 500)
                jitter = call(point_process, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
                shimmer = call([sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)

                jitter_val = 0.015 if (jitter is None or math.isnan(jitter)) else float(jitter)
                shimmer_val = 0.040 if (shimmer is None or math.isnan(shimmer)) else float(shimmer)

                # RMS via sound values
                values = sound.values
                rms = float(np.sqrt(np.mean(values**2)))

                # Composite raw vocal arousal proxy: combination of pitch variation, volume, and speech activity
                arousal_raw = round(min(max((std_f0 / 50.0) * 0.5 + (rms / 0.2) * 0.5, 0.0), 1.0), 3)

                return {
                    "mean_f0_hz": round(mean_f0, 1),
                    "f0_std_hz": round(std_f0, 1),
                    "rms_loudness": round(rms, 3),
                    "jitter_local": round(jitter_val, 4),
                    "shimmer_local": round(shimmer_val, 4),
                    "prosody_variance": round(std_f0 / max(mean_f0, 1.0), 3),
                    "arousal_raw": arousal_raw,
                    "is_fallback": False,
                }
        except Exception as e:
            logger.warning(f"Parselmouth acoustic analysis error: {e}. Falling back to librosa/numpy.")

        # Numpy fallback - same raw-PCM assumption as above; soundfile was
        # never going to succeed here since audio_bytes has no container
        # format for it to sniff.
        try:
            data = _pcm16_bytes_to_float_array(audio_bytes)
            rms = float(np.sqrt(np.mean(data**2)))
            arousal_raw = round(min(max(rms / 0.15, 0.1), 0.95), 3)
            return {
                "mean_f0_hz": 180.0,
                "f0_std_hz": 26.0,
                "rms_loudness": round(rms, 3),
                "jitter_local": 0.014,
                "shimmer_local": 0.042,
                "prosody_variance": 0.55,
                "arousal_raw": arousal_raw,
                "is_fallback": True,
            }
        except Exception as e2:
            logger.warning(f"Acoustic fallback error: {e2}. Returning baseline defaults.")
            return {
                "mean_f0_hz": 175.0,
                "f0_std_hz": 24.0,
                "rms_loudness": 0.10,
                "jitter_local": 0.015,
                "shimmer_local": 0.045,
                "prosody_variance": 0.50,
                "arousal_raw": 0.50,
                "is_fallback": True,
            }

    # -------------------------------------------------------------------------
    # Aggregator: Unified Feature Vector
    # -------------------------------------------------------------------------
    def extract_all_metrics(
        self,
        transcript: str,
        words: Optional[List[Dict[str, Any]]] = None,
        audio_bytes: Optional[bytes] = None,
        total_duration_sec: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Extract all 3 tiers into a unified feature vector dictionary."""
        if words is None:
            # Build approximate word timings from transcript
            raw_words = transcript.split()
            words = [
                {"word": w, "start_time": i * 0.45, "end_time": (i + 1) * 0.45}
                for i, w in enumerate(raw_words)
            ]

        t1 = self.compute_tier1_timing(words, total_duration_sec)
        t2 = self.compute_tier2_fluency(transcript)
        t3 = self.compute_tier3_acoustic(audio_bytes)

        return {
            **t1,
            **t2,
            **t3,
        }
