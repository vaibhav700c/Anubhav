"""Digital Twin routes:
- GET /twin/{user_id} : Returns speaker profile, longitudinal progress, and next session projection.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession
from app.db.database import get_db
from app.schemas.twin_schemas import DigitalTwinResponse, TwinHistoryPoint
from app.services.digital_twin_service import DigitalTwinService

router = APIRouter()
twin_svc = DigitalTwinService()


@router.get("/twin/{user_id}", response_model=DigitalTwinResponse)
def get_user_digital_twin(
    user_id: str,
    db: DBSession = Depends(get_db),
):
    """Retrieve the speaker's Digital Twin profile, history trend, and projection."""
    data = twin_svc.get_or_create_twin(user_id=user_id, db=db)
    return DigitalTwinResponse(
        user_id=data["user_id"],
        history_summary=[TwinHistoryPoint(**pt) for pt in data["history_summary"]],
        next_session_projection=data["next_session_projection"],
        trend_slope=data.get("trend_slope"),
        baseline_arousal=data.get("baseline_arousal"),
        disclaimer=data.get("disclaimer"),
    )
