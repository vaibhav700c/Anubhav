"""Configuration module for Anubhav ML / Backend Hub.
Loads environment variables and sets sensible defaults for all services.
"""

from typing import Optional
import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    ENVIRONMENT: str = "development"
    MOCK_MODE: bool = True

    # Database
    DATABASE_URL: str = "sqlite:///./anubhav.db"

    # Sarvam AI
    SARVAM_API_KEY: Optional[str] = None
    SARVAM_BASE_URL: str = "https://api.sarvam.ai"

    # Hume AI
    HUME_API_KEY: Optional[str] = None
    HUME_EVI_WS_URL: str = "wss://api.hume.ai/v0/evi/chat"

    # Voice & Speech Scoring Weights (Sum to 1.0)
    WEIGHT_CONTINUITY: float = 0.25
    WEIGHT_PAUSE_CONTROL: float = 0.20
    WEIGHT_FILLER_RATE: float = 0.25
    WEIGHT_REPETITION_RATE: float = 0.15
    WEIGHT_SELF_CORRECTION: float = 0.15

    # Universal model disclaimer
    DISCLAIMER: str = (
        "All metrics (Speech Fluency Score, Vocal Arousal Index, emotion labels) are model-derived "
        "proxies designed for public speaking practice and coaching. They are not medical, clinical, "
        "or neuroscientific diagnoses or assessments."
    )

    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
