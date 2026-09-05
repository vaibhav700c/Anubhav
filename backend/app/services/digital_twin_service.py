"""Digital Twin Service:
Tracks longitudinal public speaking progress across sessions for a speaker.
Fits a linear regression trend model over Speech Fluency Scores and calculates
next-session score projections.
Matches Flutter app contract:
{
    "user_id": "user_001",
    "history_summary": [{"session_index": 1, "score": 68}, ...],
    "next_session_projection": 81.0,
    "disclaimer": "..."
}
"""

import logging
from typing import Dict, Any, List, Optional
import numpy as np
from sqlalchemy.orm import Session as DBSession
from app.db.models import User, Session as SessionModel, DigitalTwin
from app.config import settings

logger = logging.getLogger("digital_twin_service")


class DigitalTwinService:
    """Longitudinal trend modeling and projection for speaker's Digital Twin."""

    def fit_trend_and_project(self, scores: List[float]) -> Dict[str, Any]:
        """Fit a linear regression trend model over historical session scores.

        Returns slope, projected next score, and summary points.
        (Clean seam left to plug in Facebook Prophet or ARIMA).
        """
        if not scores:
            return {
                "history_summary": [],
                "next_session_projection": 75.0,
                "trend_slope": 0.0,
            }

        history_summary = [
            {"session_index": idx + 1, "score": int(round(score))}
            for idx, score in enumerate(scores)
        ]

        if len(scores) == 1:
            # Single baseline session: conservative projection
            single_score = scores[0]
            projected = min(max(single_score + 3.0, 30.0), 98.0)
            return {
                "history_summary": history_summary,
                "next_session_projection": round(projected, 1),
                "trend_slope": 3.0,
            }

        # Multi-session: Linear regression y = mx + c
        x = np.arange(1, len(scores) + 1, dtype=float)
        y = np.array(scores, dtype=float)

        # Fit least squares line
        A = np.vstack([x, np.ones(len(x))]).T
        slope, intercept = np.linalg.lstsq(A, y, rcond=None)[0]

        next_x = len(scores) + 1
        raw_projection = slope * next_x + intercept
        # Realistic clamping
        projection = min(max(raw_projection, 30.0), 98.0)

        return {
            "history_summary": history_summary,
            "next_session_projection": round(float(projection), 1),
            "trend_slope": round(float(slope), 2),
        }

    def get_or_create_twin(self, user_id: str, db: DBSession) -> Dict[str, Any]:
        """Retrieve the Digital Twin representation for a user."""
        # 1. Fetch user sessions ordered by creation date
        sessions = (
            db.query(SessionModel)
            .filter(SessionModel.user_id == user_id)
            .order_by(SessionModel.created_at.asc())
            .all()
        )

        user = db.query(User).filter(User.id == user_id).first()
        baseline_arousal = user.baseline_arousal if user else None

        if not sessions:
            # Return demo/mock twin data if no recorded sessions yet
            mock_scores = [68.0, 74.0, 79.0]
            trend_data = self.fit_trend_and_project(mock_scores)
            return {
                "user_id": user_id,
                "history_summary": trend_data["history_summary"],
                "next_session_projection": trend_data["next_session_projection"],
                "trend_slope": trend_data["trend_slope"],
                "baseline_arousal": baseline_arousal or 0.52,
                "disclaimer": settings.DISCLAIMER,
            }

        scores = [s.score for s in sessions]
        trend_data = self.fit_trend_and_project(scores)

        # Persist or update digital_twin record in DB
        twin_record = db.query(DigitalTwin).filter(DigitalTwin.user_id == user_id).first()
        if not twin_record:
            twin_record = DigitalTwin(
                user_id=user_id,
                history_summary=trend_data["history_summary"],
                next_session_projection=trend_data["next_session_projection"],
            )
            db.add(twin_record)
        else:
            twin_record.history_summary = trend_data["history_summary"]
            twin_record.next_session_projection = trend_data["next_session_projection"]

        db.commit()

        return {
            "user_id": user_id,
            "history_summary": trend_data["history_summary"],
            "next_session_projection": trend_data["next_session_projection"],
            "trend_slope": trend_data["trend_slope"],
            "baseline_arousal": baseline_arousal,
            "disclaimer": settings.DISCLAIMER,
        }

    def update_twin_after_session(
        self,
        user_id: str,
        session_score: float,
        db: DBSession,
    ) -> Dict[str, Any]:
        """Update twin projection immediately after session completion."""
        return self.get_or_create_twin(user_id, db)
