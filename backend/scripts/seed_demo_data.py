"""Seeds realistic demo data into whatever database DATABASE_URL points at
(local SQLite by default, or Render's Postgres once that's wired up).

Unlike hand-typed fake rows, every number here is produced by the app's own
pipeline: MetricsService -> ScoringService -> XAIService, run over a handful
of representative Hindi/English speech-coaching transcripts (matching the
languages this app is actually being tested with). Only the LLM coaching
line is hand-written per sample instead of calling the real Sarvam API, so
this runs standalone with no API keys and no network calls.

Idempotent: re-running it upserts the same fixed session ids instead of
piling up duplicates, so it's safe to run again after a schema change or
just to refresh the numbers.

Usage:
    cd backend
    python scripts/seed_demo_data.py

Against Render's Postgres once provisioned, run this from the Render Shell
tab for the anubhav-hub service (DATABASE_URL is already set there) -
there's no way to run it against your production DB from outside Render
without that same DATABASE_URL.
"""

import os
import sys
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal  # noqa: E402
from app.db.models import User, Session as SessionModel, Feedback  # noqa: E402
from app.services.metrics_service import MetricsService  # noqa: E402
from app.services.scoring_service import ScoringService  # noqa: E402
from app.services.xai_service import XAIService  # noqa: E402
from app.services.digital_twin_service import DigitalTwinService  # noqa: E402

metrics_svc = MetricsService()
scoring_svc = ScoringService()
xai_svc = XAIService()
twin_svc = DigitalTwinService()

DEMO_USER_ID = "user_001"
DEMO_USER_NAME = "Demo Speaker"

# Three sessions across a couple of weeks, deliberately improving in
# fluency/fewer fillers so the Digital Twin's trend line has something real
# to fit - matches the two languages actually in active use/testing.
SAMPLE_SESSIONS = [
    {
        "id": "demo_session_1",
        "days_ago": 14,
        "topic": "Introducing our VR speech coach",
        "language": "en-IN",
        "duration_sec": 62.0,
        "transcript": (
            "Good morning everyone. Um, today I want to, uh, present our project Anubhav. "
            "Basically it's a VR app that, you know, helps people practice public speaking. "
            "We connect a Quest headset to a backend that does, um, speech to text and scoring. "
            "The biggest challenge was, uh, getting the latency low enough to feel real time."
        ),
        "emotion_timeline": [
            {"time": 8.0, "emotion": "nervous", "intensity": 0.71},
            {"time": 28.0, "emotion": "calm", "intensity": 0.6},
            {"time": 50.0, "emotion": "nervous", "intensity": 0.65},
        ],
        "coaching_text": "Good structure overall, but cut the 'um' and 'uh' fillers before your key points.",
    },
    {
        "id": "demo_session_2",
        "days_ago": 7,
        "topic": "Explaining the coaching pipeline",
        "language": "hi-IN",
        "duration_sec": 58.0,
        "transcript": (
            "namaste, aaj main hamare speech coaching pipeline ke baare mein btaunga. "
            "hum sarvam ki speech to text aur text to speech technology use karte hain. "
            "matlab, jab user bolta hai, hum uska transcript nikaalte hain aur score dete hain. "
            "isse hame accurate feedback milta hai aur speaker apni fluency improve kar sakta hai."
        ),
        "emotion_timeline": [
            {"time": 10.0, "emotion": "calm", "intensity": 0.68},
            {"time": 30.0, "emotion": "confident", "intensity": 0.74},
            {"time": 48.0, "emotion": "confident", "intensity": 0.8},
        ],
        "coaching_text": "Achha pace hai, bas 'matlab' ka use thoda kam karo transitions mein.",
    },
    {
        "id": "demo_session_3",
        "days_ago": 1,
        "topic": "Demo day pitch",
        "language": "en-IN",
        "duration_sec": 65.0,
        "transcript": (
            "Good morning judges. Today I am presenting our speech intelligence platform, Anubhav. "
            "We connect the VR simulation directly with our Flutter companion mobile app. "
            "Our explainability model shows exactly why a score improved between sessions. "
            "Notice how the audience reacts live based on the speaker's detected emotion and pacing. "
            "Thank you, and I am ready to take your questions."
        ),
        "emotion_timeline": [
            {"time": 6.0, "emotion": "confident", "intensity": 0.82},
            {"time": 25.0, "emotion": "confident", "intensity": 0.85},
            {"time": 45.0, "emotion": "excited", "intensity": 0.88},
            {"time": 60.0, "emotion": "confident", "intensity": 0.83},
        ],
        "coaching_text": "Strong, confident close - that's exactly the pacing to keep for the real pitch.",
    },
]


def upsert_user(db) -> User:
    user = db.query(User).filter(User.id == DEMO_USER_ID).first()
    if user:
        print(f"User {DEMO_USER_ID!r} already exists - reusing.")
        return user
    user = User(
        id=DEMO_USER_ID,
        name=DEMO_USER_NAME,
        preferred_language="hi-IN",
        baseline_arousal=0.55,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    print(f"Created user {DEMO_USER_ID!r}.")
    return user


def upsert_session(db, sample: dict) -> float:
    session_id = sample["id"]

    # Derive real metrics/score/SHAP from the transcript exactly the way
    # /session/complete does, instead of hand-picking numbers.
    features = metrics_svc.extract_all_metrics(
        transcript=sample["transcript"],
        total_duration_sec=sample["duration_sec"],
    )
    features["topic"] = sample["topic"]
    features["language"] = sample["language"]

    score_result = scoring_svc.compute_fluency_score(features)
    overall_score = score_result["overall_score"]

    try:
        xai_result = xai_svc.explain_delivery(features=features, score=overall_score)
        shap_breakdown = xai_result["shap_breakdown"]
    except Exception as exc:  # pragma: no cover - defensive, matches session.py
        print(f"  XAI explanation failed for {session_id}, saving without it: {exc}")
        shap_breakdown = []

    iso_date = (datetime.utcnow() - timedelta(days=sample["days_ago"])).strftime("%Y-%m-%dT%H:%M:%SZ")

    session_rec = db.query(SessionModel).filter(SessionModel.id == session_id).first()
    if session_rec:
        session_rec.transcript = sample["transcript"]
        session_rec.feature_vector = features
        session_rec.score = overall_score
        session_rec.date = iso_date
        action = "Updated"
    else:
        session_rec = SessionModel(
            id=session_id,
            user_id=DEMO_USER_ID,
            transcript=sample["transcript"],
            feature_vector=features,
            score=overall_score,
            date=iso_date,
        )
        db.add(session_rec)
        action = "Created"
    db.commit()

    feedback_rec = db.query(Feedback).filter(Feedback.session_id == session_id).first()
    if feedback_rec:
        feedback_rec.shap_breakdown = shap_breakdown
        feedback_rec.coaching_text = sample["coaching_text"]
        feedback_rec.emotion_timeline = sample["emotion_timeline"]
    else:
        feedback_rec = Feedback(
            session_id=session_id,
            shap_breakdown=shap_breakdown,
            coaching_text=sample["coaching_text"],
            emotion_timeline=sample["emotion_timeline"],
        )
        db.add(feedback_rec)
    db.commit()

    print(f"  {action} session {session_id!r}: score={overall_score}, language={sample['language']}")
    return overall_score


def main():
    db = SessionLocal()
    try:
        upsert_user(db)
        print("Seeding sessions...")
        last_score = 75.0
        for sample in SAMPLE_SESSIONS:
            last_score = upsert_session(db, sample)

        twin = twin_svc.update_twin_after_session(
            user_id=DEMO_USER_ID,
            session_score=last_score,
            db=db,
        )
        print(
            f"Digital twin updated: history={twin['history_summary']}, "
            f"next_projection={twin['next_session_projection']}"
        )
    finally:
        db.close()

    print("Done.")


if __name__ == "__main__":
    main()
