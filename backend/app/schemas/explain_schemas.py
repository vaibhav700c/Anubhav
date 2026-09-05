"""Schemas for Explainability endpoint."""

from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.session_schemas import ShapFeatureSchema


class ExplainResponse(BaseModel):
    session_id: str
    overall_score: float
    base_value: float
    shap_breakdown: List[ShapFeatureSchema] = Field(default_factory=list)
    top_factors: List[str] = Field(default_factory=list)
    disclaimer: Optional[str] = None
