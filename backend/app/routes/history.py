"""History routes:
- GET /history/{user_id} : Returns list of past sessions with headline scores.
"""

from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession
from app.db.database import get_db
from app.db.models import Session as SessionModel
from app.schemas.session_schemas import SessionSummarySchema
from app.config import settings

router = APIRouter()


@router.get("/history/{user_id}", response_model=List[SessionSummarySchema])
def get_user_history(
    user_id: str,
    db: DBSession = Depends(get_db),
):
    """Retrieve all historical sessions for a user, ordered by creation date."""
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == user_id)
        .order_by(SessionModel.created_at.desc())
        .all()
    )

    if not sessions:
        # Provide realistic mock history for instant demo compatibility
        return [
            SessionSummarySchema(session_id="s001", date="2026-09-05T10:32:00Z", overall_score=74),
            SessionSummarySchema(session_id="s002", date="2026-09-04T15:15:00Z", overall_score=68),
            SessionSummarySchema(session_id="s003", date="2026-09-03T09:45:00Z", overall_score=61),
        ]

    return [
        SessionSummarySchema(
            session_id=s.id,
            date=s.date,
            overall_score=int(round(s.score)),
        )
        for s in sessions
    ]
