"""Schemas for Emotion and Explain endpoints."""

from typing import List, Dict, Optional
from pydantic import BaseModel, Field
from app.schemas.session_schemas import ShapFeatureSchema


class EmotionResponse(BaseModel):
    emotion: str  # e.g., Confident, Nervous, Bored, Excited, Monotone, Calm
    flutter_label: str  # lowercase normalized: confident, nervous, neutral, excited, calm
    confidence: float
    source: str  # "hume_evi" or "local_fallback"
    arousal_index: Optional[float] = None
    raw_scores: Dict[str, float] = Field(default_factory=dict)
    disclaimer: Optional[str] = None


class ExplainResponse(BaseModel):
    session_id: str
    overall_score: float
    base_value: float
    shap_breakdown: List[ShapFeatureSchema] = Field(default_factory=list)
    top_factors: List[str] = Field(default_factory=list)
    disclaimer: Optional[str] = None
