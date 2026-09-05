"""Schemas for Digital Twin endpoint."""

from typing import List, Optional
from pydantic import BaseModel, Field


class TwinHistoryPoint(BaseModel):
    session_index: int
    score: int


class DigitalTwinResponse(BaseModel):
    user_id: str
    history_summary: List[TwinHistoryPoint] = Field(default_factory=list)
    next_session_projection: float
    trend_slope: Optional[float] = None
    baseline_arousal: Optional[float] = None
    disclaimer: Optional[str] = None
