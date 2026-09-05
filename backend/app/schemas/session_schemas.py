"""Schemas for Session, History, and Live Telemetry."""

from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field


class EmotionPointSchema(BaseModel):
    time: float
    emotion: str
    intensity: float = 1.0


class ShapFeatureSchema(BaseModel):
    feature: str
    contribution: float
    explanation: str


class SessionSummarySchema(BaseModel):
    session_id: str
    date: str
    overall_score: int
    topic: Optional[str] = None
    language: Optional[str] = None


class SessionDetailSchema(BaseModel):
    session_id: str
    user_id: Optional[str] = None
    date: str
    overall_score: int
    emotion_timeline: List[EmotionPointSchema] = Field(default_factory=list)
    shap_breakdown: List[ShapFeatureSchema] = Field(default_factory=list)
    transcript: str = ""
    coaching_text: Optional[str] = None
    feature_vector: Optional[Dict[str, Any]] = None
    disclaimer: Optional[str] = None
    topic: Optional[str] = None
    language: Optional[str] = None


class LiveUpdateSchema(BaseModel):
    score: int
    emotion_label: str
    transcript_partial: str
    coaching_tip: Optional[str] = None
    is_final: bool = False
    disclaimer: Optional[str] = None


class SessionCompleteRequest(BaseModel):
    session_id: str
    user_id: str
    final_transcript: Optional[str] = None
    topic: Optional[str] = None
    language: Optional[str] = None
    audience_size: Optional[str] = None


class SessionCompleteResponse(BaseModel):
    status: str
    session: SessionDetailSchema
    disclaimer: str
