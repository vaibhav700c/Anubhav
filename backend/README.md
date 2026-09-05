# Anubhav ML / Sarvam AI / Emotion / XAI / Backend Hub
**Team Kaala Teeka▪️ | graVITas'26 Hackathon**

Anubhav is a VR-based public speaking coach. This backend service is the central intelligence hub that ingests real-time voice streams, transcribes and coaches speakers in native Indian languages, senses emotional state, scores delivery with explainable feedback (SHAP), and projects improvement over time through a Digital Twin.

Both the **Unity (VR headset)** client and **Flutter (Companion Mobile App)** client integrate through this service.

---

## Architecture Overview

```
                          ┌────────────────────────┐
                          │   Unity (VR Headset)   │
                          └──────────┬─────────────┘
                                     │  WS /session/{id}?client_type=vr
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                             FASTAPI HUB                                  │
│                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────────────┐  │
│  │  SarvamService  │    │ MetricsService  │    │    EmotionService    │  │
│  │  - Saaras STT   │    │ - Tier 1 Timing │    │ - Hume AI EVI (Pri)  │  │
│  │  - 105B LLM     │    │ - Tier 2 Fluency│    │ - Prosody (Fallback) │  │
│  │  - Bulbul TTS   │    │ - Tier 3 Acoustic│   │ - 6 Fixed Labels     │  │
│  └─────────────────┘    └─────────────────┘    └──────────────────────┘  │
│           │                      │                         │             │
│           ▼                      ▼                         ▼             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────────────┐  │
│  │ ScoringService  │    │   XAIService    │    │  DigitalTwinService  │  │
│  │ - Fluency Score │    │ - SHAP Explainer│    │ - Trend Regression   │  │
│  │ - Vocal Arousal │    │ - Top 3 Factors │    │ - Session Projection │  │
│  └─────────────────┘    └─────────────────┘    └──────────────────────┘  │
│                                  │                                       │
│                                  ▼                                       │
│                          SQLAlchemy / SQLite                             │
│                  (users, sessions, feedback, twin)                       │
└──────────────────────────────────┬───────────────────────────────────────┘
                                   │  WS /session/{id}?client_type=app
                                   │  REST: /history, /session, /twin, etc.
                                   ▼
                          ┌────────────────────────┐
                          │ Flutter Mobile Client  │
                          └────────────────────────┘
```

---

## Quickstart & Local Setup

### 1. Environment Requirements
- Python 3.10, 3.11, or 3.12 (Python 3.11 recommended for Praat Parselmouth & SHAP)

### 2. Create Virtual Environment & Install Dependencies
```bash
cd backend
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Default `.env` settings run in **Mock / Offline Mode** (`MOCK_MODE=True`), enabling full end-to-end evaluation without active internet or third-party API keys.

To enable live production APIs:
```env
MOCK_MODE=False
SARVAM_API_KEY=your_actual_sarvam_api_key
HUME_API_KEY=your_actual_hume_api_key
```

### 4. Train Scorer Model & Generate Dataset
```bash
python ml/train_scorer.py
```
This generates `ml/synthetic_dataset.csv` and serializes the SHAP-compatible `ml/scorer.pkl` model.

### 5. Launch FastAPI Backend
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive Swagger API docs will be available at: `http://localhost:8000/docs`.

---

## Core Services

### 1. `SarvamService` (`app/services/sarvam_service.py`)
- Single point of entry for all Sarvam API calls:
  - **Saaras STT**: Streams chunked speech audio with **verbatim mode** turned on to preserve filler words (`matlab`, `um`, `uh`, `basically`), repetitions, and false starts for the downstream metrics engine.
  - **Sarvam-105B LLM**: Builds technical, specific coaching feedback quoting the speaker's actual phrases and advising on pace/filler reduction rather than generic praise.
  - **Bulbul TTS**: Converts the coach feedback into natural Indian English or native Indian language audio bytes and streams back to VR.
- Full offline mock fallbacks built-in for connectivity-resilient demos.

### 2. `MetricsService` (`app/services/metrics_service.py`)
Implements 3-tier speech metrics:
- **Tier 1 (Timing)**: WPM, pause count, total pause duration, speech-to-silence ratio.
- **Tier 2 (Fluency)**: Verbatim transcript analysis for filler words (`um, uh, matlab, yaani, like, basically`), repetitions, and false starts.
- **Tier 3 (Acoustic)**: Parselmouth (Praat) pitch $f_0$, RMS loudness, local jitter, local shimmer, and prosody variance.

### 3. `ScoringService` (`app/services/scoring_service.py`)
- **Speech Fluency Score (0–100)**: Weighted combination of continuity, pause control, filler penalty, repetition penalty, and self-correction penalty. Configurable via `.env`.
- **Vocal Arousal Index**: Computed as a **delta from the speaker's own baseline session** stored in the database. Never compared against a rigid population threshold.
- **Proxy Disclaimer**: Explicitly labels every metric as a model-derived proxy, never a medical or neuroscientific diagnosis.

### 4. `EmotionService` (`app/services/emotion_service.py`)
- **Primary**: Hume AI EVI WebSocket integration with automatic defensive switching on quota exhaustion.
- **Fallback**: Local acoustic prosody rules blended with transcript heuristic sentiment.
- **Normalized Palette**: Always outputs one of the fixed 6 labels: `Confident`, `Nervous`, `Bored`, `Excited`, `Monotone`, `Calm` (mapped transparently to Flutter theme keys: `confident`, `nervous`, `neutral`, `excited`, `calm`).

### 5. `XAIService` (`app/services/xai_service.py`)
- Loads `scorer.pkl` and executes `shap.TreeExplainer`.
- Identifies the top 2–3 feature attributions (pace, fillers, pauses, pitch) with human-readable explanations matching Flutter's `{feature, contribution, explanation}` contract.

### 6. `DigitalTwinService` (`app/services/digital_twin_service.py`)
- Tracks longitudinal progress across all sessions.
- Fits a linear regression trend line and calculates `next_session_projection`.

---

## API Endpoints & Contracts

### WebSocket: `WS /session/{id}`
- Connect with `?client_type=app` (Flutter) or `?client_type=vr` (Unity).
- **VR stream in**: Audio bytes or JSON `{type: "text_chunk", text: "..."}`.
- **Flutter stream out**: Real-time telemetry frames:
```json
{
  "score": 76,
  "emotion_label": "confident",
  "transcript_partial": "Basically our architecture solves the latency issue directly.",
  "coaching_tip": "Maintain steady cadence",
  "is_final": false,
  "disclaimer": "All metrics are model-derived proxies..."
}
```

### `POST /session/complete`
Finalizes an active session, computes metrics, SHAP breakdown, and updates the speaker's Digital Twin.
- **Request Body**:
```json
{
  "session_id": "s001",
  "user_id": "user_001",
  "final_transcript": "Good morning everyone. Today I am presenting Anubhav..."
}
```

### `GET /session/{id}`
Returns full session details matching the Flutter `SessionDetail` model:
```json
{
  "session_id": "s001",
  "date": "2026-09-05T10:32:00Z",
  "overall_score": 74,
  "emotion_timeline": [
    {"time": 5.0, "emotion": "confident", "intensity": 0.82}
  ],
  "shap_breakdown": [
    {
      "feature": "Filler Words",
      "contribution": -8.3,
      "explanation": "Too many filler words (4.2%) lowered your score by 8.3 points."
    }
  ],
  "transcript": "...",
  "coaching_text": "..."
}
```

### `GET /twin/{user_id}`
Returns the Digital Twin longitudinal profile and next-session projection:
```json
{
  "user_id": "user_001",
  "history_summary": [
    {"session_index": 1, "score": 68},
    {"session_index": 2, "score": 74}
  ],
  "next_session_projection": 81.0
}
```

### `GET /history/{user_id}`
Returns list of past sessions with headline scores:
```json
[
  {"session_id": "s001", "date": "2026-09-05T10:32:00Z", "overall_score": 74}
]
```

### `GET /emotion`
Unified emotion sensing endpoint:
```json
{
  "emotion": "Confident",
  "flutter_label": "confident",
  "confidence": 0.85,
  "source": "local_fallback"
}
```

### `GET /explain`
SHAP feature contribution breakdown for a given session.

---

## Running the Automated Test Suite

Run pytest across all service and API tests:
```bash
backend/.venv/bin/pytest backend/tests/ -v
```
