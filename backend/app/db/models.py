"""SQLAlchemy models for Anubhav: users, sessions, feedback, and digital_twin."""

from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, Text, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    preferred_language = Column(String, default="en-IN")
    baseline_arousal = Column(Float, nullable=True)  # Speaker's baseline acoustic arousal
    created_at = Column(DateTime, default=datetime.utcnow)

    sessions = relationship("Session", back_populates="user", cascade="all, delete-orphan")
    digital_twin = relationship("DigitalTwin", back_populates="user", uselist=False, cascade="all, delete-orphan")


class Session(Base):
    __tablename__ = "sessions"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    transcript = Column(Text, default="")
    feature_vector = Column(JSON, default=dict)
    score = Column(Float, default=0.0)
    date = Column(String, nullable=False)  # ISO 8601 string, e.g. "2026-09-05T10:32:00Z"
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="sessions")
    feedback = relationship("Feedback", back_populates="session", uselist=False, cascade="all, delete-orphan")


class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False, unique=True, index=True)
    shap_breakdown = Column(JSON, default=list)  # [{"feature": ..., "contribution": ..., "explanation": ...}]
    coaching_text = Column(Text, default="")
    emotion_timeline = Column(JSON, default=list)  # [{"time": ..., "emotion": ..., "intensity": ...}]
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("Session", back_populates="feedback")


class DigitalTwin(Base):
    __tablename__ = "digital_twin"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True, index=True)
    history_summary = Column(JSON, default=list)  # [{"session_index": 1, "score": 70}, ...]
    next_session_projection = Column(Float, default=75.0)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="digital_twin")
