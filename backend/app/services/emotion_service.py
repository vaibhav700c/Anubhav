"""Emotion AI Service:
Primary: Hume AI EVI WebSocket connection with quota-exhaustion defense.
Fallback: Local acoustic prosody (pitch variance, speaking rate, RMS) blended with transcript heuristics.
Unified output: Always normalized to the fixed 6-label set:
[Confident, Nervous, Bored, Excited, Monotone, Calm]
"""

import json
import logging
from typing import Dict, Any, Optional
import httpx
from app.config import settings

logger = logging.getLogger("emotion_service")

# Fixed 6-label vocabulary specified in project requirements
UNIFIED_EMOTIONS = ["Confident", "Nervous", "Bored", "Excited", "Monotone", "Calm"]

# Mapping to Flutter app's client theme keys
FLUTTER_THEME_MAP = {
    "Confident": "confident",
    "Nervous": "nervous",
    "Bored": "neutral",
    "Excited": "excited",
    "Monotone": "neutral",
    "Calm": "calm",
}


class EmotionService:
    """Emotion sensing with Hume AI EVI primary and local prosody offline fallback."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or settings.HUME_API_KEY
        self.secret_key = settings.HUME_SECRET_KEY
        self.token_url = settings.HUME_TOKEN_URL
        self.ws_url = settings.HUME_EVI_WS_URL
        self._quota_exhausted = False
        self._force_fallback = settings.MOCK_MODE or not bool(self.api_key)
        self._access_token: Optional[str] = None  # Cached OAuth2 access token
        self._token_expiry: float = 0.0  # Unix timestamp

    # -------------------------------------------------------------------------
    # Hume OAuth2 Client-Credentials Token Exchange
    # -------------------------------------------------------------------------
    async def _get_access_token(self) -> Optional[str]:
        """Exchange API Key + Secret Key for a short-lived OAuth2 access token.

        Hume EVI uses client-credentials flow:
        POST https://api.hume.ai/oauth2-cc/token
        Auth: Basic base64(api_key:secret_key)
        Body: grant_type=client_credentials
        Token is valid for 30 minutes; we refresh 2 minutes before expiry.
        """
        import time
        import base64

        if not self.api_key or not self.secret_key:
            return None  # Fall back to API-key-only header method

        # Return cached token if still valid (refresh 2 min before expiry)
        if self._access_token and time.time() < self._token_expiry - 120:
            return self._access_token

        credentials = base64.b64encode(f"{self.api_key}:{self.secret_key}".encode()).decode()
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.post(
                    self.token_url,
                    headers={
                        "Authorization": f"Basic {credentials}",
                        "Content-Type": "application/x-www-form-urlencoded",
                    },
                    data="grant_type=client_credentials",
                )
                if resp.status_code == 200:
                    data = resp.json()
                    self._access_token = data.get("access_token")
                    expires_in = data.get("expires_in", 1800)  # default 30 min
                    self._token_expiry = time.time() + expires_in
                    logger.info("Hume AI access token obtained successfully.")
                    return self._access_token
                else:
                    logger.warning(f"Hume AI token exchange failed: {resp.status_code} {resp.text}")
                    return None
        except Exception as e:
            logger.warning(f"Hume AI token exchange error: {e}")
            return None

    # -------------------------------------------------------------------------
    # Primary: Hume AI EVI Sensing
    # -------------------------------------------------------------------------
    async def analyze_with_hume(self, audio_bytes: bytes) -> Optional[Dict[str, Any]]:
        """Query Hume AI EVI. Uses OAuth2 token if both API key and Secret Key are set;
        otherwise falls back to API-Key header only."""
        if self._force_fallback or self._quota_exhausted or not audio_bytes:
            return None

        try:
            # Prefer OAuth2 access token; fall back to raw API key header
            access_token = await self._get_access_token()
            if access_token:
                headers = {"Authorization": f"Bearer {access_token}"}
            else:
                headers = {"X-Hume-Api-Key": self.api_key or ""}

            url = "https://api.hume.ai/v0/evi/chat"
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.post(url, headers=headers, json={"audio": "stream"})
                if resp.status_code in [401, 402, 429]:
                    logger.warning(f"Hume AI quota exhausted or rate limited ({resp.status_code}). Switching to fallback.")
                    self._quota_exhausted = True
                    self._access_token = None  # Force token refresh on next call
                    return None
                data = resp.json()
                raw_scores = data.get("emotions", {})
                return self._map_hume_to_unified(raw_scores)
        except Exception as e:
            logger.warning(f"Hume AI connection issue: {e}. Degrading to local prosody fallback.")
            return None

    def _map_hume_to_unified(self, raw_emotions: Dict[str, float]) -> Dict[str, Any]:
        """Map Hume AI's 48-dimension emotion palette to our fixed 6-label vocabulary."""
        # Aggregate Hume dimension clusters
        score_confident = (
            raw_emotions.get("Determination", 0.0) * 0.4
            + raw_emotions.get("Pride", 0.0) * 0.3
            + raw_emotions.get("Triumph", 0.0) * 0.3
        )
        score_nervous = (
            raw_emotions.get("Anxiety", 0.0) * 0.5
            + raw_emotions.get("Fear", 0.0) * 0.3
            + raw_emotions.get("Doubt", 0.0) * 0.2
        )
        score_bored = (
            raw_emotions.get("Boredom", 0.0) * 0.6
            + raw_emotions.get("Tiredness", 0.0) * 0.4
        )
        score_excited = (
            raw_emotions.get("Excitement", 0.0) * 0.5
            + raw_emotions.get("Joy", 0.0) * 0.3
            + raw_emotions.get("Enthusiasm", 0.0) * 0.2
        )
        score_monotone = (
            raw_emotions.get("Calmness", 0.0) * 0.3
            + raw_emotions.get("Boredom", 0.0) * 0.4
        )
        score_calm = (
            raw_emotions.get("Calmness", 0.0) * 0.6
            + raw_emotions.get("Satisfaction", 0.0) * 0.4
        )

        candidates = {
            "Confident": score_confident,
            "Nervous": score_nervous,
            "Bored": score_bored,
            "Excited": score_excited,
            "Monotone": score_monotone,
            "Calm": score_calm,
        }

        best_label = max(candidates, key=candidates.get)
        confidence = round(float(candidates[best_label]), 2)
        if confidence == 0.0:
            best_label = "Calm"
            confidence = 0.75

        return {
            "emotion": best_label,
            "confidence": min(max(confidence, 0.5), 0.98),
            "source": "hume_evi",
            "raw_scores": {k: round(v, 3) for k, v in candidates.items()},
        }

    # -------------------------------------------------------------------------
    # Fallback: Local Prosody + Transcript Heuristics
    # -------------------------------------------------------------------------
    def analyze_with_fallback(
        self,
        features: Optional[Dict[str, Any]] = None,
        transcript: str = "",
    ) -> Dict[str, Any]:
        """Estimate emotion locally from pitch variance, WPM, RMS volume, and transcript.

        Runs completely offline without external APIs.
        """
        feats = features or {}
        wpm = float(feats.get("wpm", 135.0))
        pitch_variance = float(feats.get("prosody_variance", 0.5))
        rms = float(feats.get("rms_loudness", 0.12))
        filler_rate = float(feats.get("filler_rate", 2.0))

        # Local heuristic scoring
        scores = {
            "Confident": 0.3,
            "Nervous": 0.2,
            "Bored": 0.1,
            "Excited": 0.1,
            "Monotone": 0.1,
            "Calm": 0.2,
        }

        # Prosody rules
        if pitch_variance < 0.25 and 110 <= wpm <= 135:
            scores["Monotone"] += 0.45
            scores["Bored"] += 0.25

        if filler_rate > 4.5 or (wpm > 165 and pitch_variance > 0.6):
            scores["Nervous"] += 0.55
            scores["Confident"] -= 0.2

        if 130 <= wpm <= 155 and 0.35 <= pitch_variance <= 0.65 and filler_rate < 2.5:
            scores["Confident"] += 0.55
            scores["Calm"] += 0.25

        if wpm > 160 and rms > 0.15 and pitch_variance > 0.5:
            scores["Excited"] += 0.50

        if wpm < 115 and pitch_variance < 0.3:
            scores["Bored"] += 0.40

        # Transcript sentiment boost
        text = transcript.lower()
        if any(w in text for w in ["uncertain", "not sure", "maybe", "sorry"]):
            scores["Nervous"] += 0.3
        if any(w in text for w in ["definitely", "clearly", "proven", "solution", "strong"]):
            scores["Confident"] += 0.3

        best_label = max(scores, key=scores.get)
        total = sum(scores.values())
        confidence = round(scores[best_label] / total, 2) if total > 0 else 0.75

        return {
            "emotion": best_label,
            "confidence": min(max(confidence, 0.55), 0.95),
            "source": "local_fallback",
            "raw_scores": {k: round(v, 2) for k, v in scores.items()},
        }

    # -------------------------------------------------------------------------
    # Unified Single Emotion Resolution
    # -------------------------------------------------------------------------
    async def get_emotion(
        self,
        audio_bytes: Optional[bytes] = None,
        features: Optional[Dict[str, Any]] = None,
        transcript: str = "",
    ) -> Dict[str, Any]:
        """Get unified emotion from Hume primary or local fallback.

        Always returns a label from UNIFIED_EMOTIONS with Flutter compatibility keys.
        """
        result = None
        if audio_bytes and not self._force_fallback:
            result = await self.analyze_with_hume(audio_bytes)

        if not result:
            result = self.analyze_with_fallback(features, transcript)

        # Normalize label to guarantee it's in UNIFIED_EMOTIONS
        raw_label = result.get("emotion", "Calm")
        normalized = raw_label if raw_label in UNIFIED_EMOTIONS else "Calm"
        flutter_label = FLUTTER_THEME_MAP.get(normalized, "neutral")

        return {
            "emotion": normalized,
            "flutter_label": flutter_label,
            "confidence": result.get("confidence", 0.80),
            "source": result.get("source", "local_fallback"),
            "raw_scores": result.get("raw_scores", {}),
            "disclaimer": settings.DISCLAIMER,
        }
