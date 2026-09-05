"""Anubhav ML / Sarvam AI / Emotion / XAI / Backend Hub
FastAPI Entry Point
"""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.db.database import init_db
from app.routes import (
    session_router,
    history_router,
    twin_router,
    emotion_router,
    explain_router,
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("anubhav_hub")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    logger.info("Initializing Anubhav Database...")
    init_db()
    logger.info(f"Anubhav Backend Hub started. Mock mode: {settings.MOCK_MODE}")
    yield
    logger.info("Anubhav Backend Hub shutting down.")


app = FastAPI(
    title="Anubhav AI Hub",
    description="ML / Sarvam AI / Emotion / XAI / Backend Hub for VR Public Speaking Coach & Flutter Companion App",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware for mobile emulator & web client access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routes
app.include_router(session_router)
app.include_router(history_router)
app.include_router(twin_router)
app.include_router(emotion_router)
app.include_router(explain_router)


@app.get("/")
def root():
    """System status and contract information."""
    return {
        "service": "Anubhav Backend Intelligence Hub",
        "team": "Kaala Teeka▪️ (graVITas'26)",
        "status": "healthy",
        "mock_mode": settings.MOCK_MODE,
        "disclaimer": settings.DISCLAIMER,
        "endpoints": {
            "websocket_session": "WS /session/{id}",
            "complete_session": "POST /session/complete",
            "session_detail": "GET /session/{id}",
            "digital_twin": "GET /twin/{user_id}",
            "history": "GET /history/{user_id}",
            "emotion": "GET /emotion",
            "explain": "GET /explain",
        },
    }


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=True,
    )
