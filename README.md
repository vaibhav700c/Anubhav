# Anubhav — VR Multilingual AI Public Speaking Coach


> An immersive, multilingual public speaking coach that listens in VR, transcribes and coaches in 22 Indian languages, reads emotional prosody, scores delivery with Explainable AI (SHAP), and tracks longitudinal growth through a persistent Digital Twin.

---

## System Architecture

```
                                  ┌────────────────────────┐
                                  │   Unity (Meta Quest 3) │
                                  │  Reactive NPC Audience │
                                  └──────────┬─────────────┘
                                             │  WS /session/{id}?client_type=vr
                                             ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                               FASTAPI INTELLIGENCE HUB                                 │
│                                                                                        │
│  ┌────────────────────────┐  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │     SarvamService      │  │     MetricsService     │  │      EmotionService      │  │
│  │  - Saaras 22L STT      │  │  - Tier 1: Timing      │  │  - Hume AI EVI (Primary) │  │
│  │  - 30B/105B LLM Coach  │  │  - Tier 2: Fluency     │  │  - Acoustic DSP Fallback │  │
│  │  - Bulbul TTS (Native) │  │  - Tier 3: Acoustic    │  │  - 6 Unified Labels      │  │
│  └────────────────────────┘  └────────────────────────┘  └──────────────────────────┘  │
│               │                           │                            │               │
│               ▼                           ▼                            ▼               │
│  ┌────────────────────────┐  ┌────────────────────────┐  ┌──────────────────────────┐  │
│  │     ScoringService     │  │       XAIService       │  │    DigitalTwinService    │  │
│  │  - Fluency Score       │  │  - SHAP TreeExplainer  │  │  - Trend Regression      │  │
│  │  - Vocal Arousal Delta │  │  - Top-3 Explanations  │  │  - Session Projection    │  │
│  └────────────────────────┘  └────────────────────────┘  └──────────────────────────┘  │
│                                           │                                            │
│                                           ▼                                            │
│                               SQLAlchemy / PostgreSQL / SQLite                         │
│                              (users, sessions, feedback, twin)                         │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │  WS /session/{id}?client_type=app
                                            │  REST: /history, /session, /twin, /explain
                                            ▼
                                  ┌────────────────────────┐
                                  │  Flutter Companion App │
                                  │  Live Telemetry & XAI  │
                                  └────────────────────────┘
```

---

## Core Project Feature Implementations

### 1. Multilingual Speech Intelligence Pipeline (Sarvam AI)
All Sarvam AI interactions are encapsulated in a single, resilient `SarvamService`:
- **Saaras Speech-to-Text (Streaming Verbatim Mode)**: Ingests raw audio chunks across 22 Indian languages and English. Configured in **verbatim mode** to intentionally preserve filler words (`matlab`, `um`, `uh`, `basically`, `like`, `you know`), repeated words, and false starts for downstream metric extraction.
- **Sarvam-30B / Sarvam-105B Coaching Engine**: Dynamic prompt templates combine the live transcript, detected emotional state, fluency score, and last 2–3 historical sessions. Produces actionable, quotable coaching lines (e.g., *"You paused for 4s after 'revenue'—great suspense, but keep follow-up pace under 140 WPM"*) rather than generic praise.
- **Bulbul Text-to-Speech**: Synthesizes the generated coaching response in the speaker's native Indian language with expressive, emotion-aware modulation and streams audio bytes back to the VR headset.
- **Offline Stub / Mock Mode**: Integrated fallbacks ensure full functionality even during network drops or quota exhaustion.

---

### 2. Three-Tier Voice & Speech Metrics Engine
The `MetricsService` computes multi-dimensional speech parameters categorized into three distinct tiers:

| Tier | Focus | Metrics Computed |
|---|---|---|
| **Tier 1: Timing** | Cadence & Pacing | Words Per Minute (WPM), pause count ($>0.4\text{s}$ threshold), total pause duration, speech-to-silence ratio. |
| **Tier 2: Fluency** | Articulation & Flow | Filler word density (Indian English & Hinglish vocabulary), consecutive single-word and multi-word phrase repetitions, false starts, and self-corrections. |
| **Tier 3: Acoustic** | Vocal Dynamics | Fundamental frequency ($f_0$ mean and standard deviation), RMS loudness intensity, local jitter (pitch perturbation), local shimmer (amplitude perturbation), and prosody variance using Parselmouth (Praat) and Librosa. |

- **Speech Fluency Score ($0\text{--}100$)**: A weighted composite index combining continuity ($S_{\text{cont}}$), pause control ($S_{\text{pause}}$), filler rate penalty ($S_{\text{filler}}$), repetition penalty ($S_{\text{rep}}$), and self-correction penalty ($S_{\text{corr}}$). Weights are configurable via environment variables.
- **Vocal Arousal Index**: Computed as a **delta relative to the speaker's personal baseline session**, avoiding misleading comparisons against fixed population averages.
- **Model-Derived Proxy Labeling**: Every metric response includes an explicit disclaimer stating that scores are model-derived proxies for coaching and not medical or clinical diagnostics.

---

### 3. Dual-Tier Emotion Sensing with Graceful Degradation
The `EmotionService` unifies emotion recognition while protecting against quota exhaustion or internet instability:
- **Primary Path (Hume AI EVI)**: Real-time WebSocket connection to Hume's Empathic Voice Interface, measuring speech rhythm, timbre, and prosody.
- **Defensive Local Fallback**: When Hume quota is exhausted ($5\text{ min/month}$ free tier limit) or network drops, the system seamlessly transitions to local acoustic Digital Signal Processing (pitch variability, speaking rate, RMS loudness) blended with transcript sentiment heuristics.
- **Unified 6-Label Vocabulary**: Whichever source is active, predictions are mapped into a standardized label set:
  $$\{\text{Confident}, \text{Nervous}, \text{Bored}, \text{Excited}, \text{Monotone}, \text{Calm}\}$$
  This is mapped into color-coded theme tokens for both the VR headset and the Flutter companion app.

---

### 4. Explainable AI (XAI) via SHAP
The `XAIService` eliminates black-box scoring by providing full transparency:
- **Trained Scorer Model**: A Gradient Boosting Regressor trained on speech delivery vectors (`ml/train_scorer.py`), achieving $R^2 = 0.923$ and $\text{MAE} = 2.85$ points, serialized to `ml/scorer.pkl`.
- **SHAP TreeExplainer**: Computes exact Shapley feature attributions for any given delivery.
- **Human-Readable Explanations**: Converts mathematical feature impacts into clear, judge-facing feedback matching the `{feature, contribution, explanation}` contract:
  - *Filler Words: $-8.3\text{ pts}$* — "High filler density (4.2% fillers like 'matlab' and 'um') lowered your score."
  - *Speaking Pace: $+6.1\text{ pts}$* — "Speaking pace of 142 WPM maintained excellent audience engagement."
  - *Pause Duration: $+4.5\text{ pts}$* — "Deliberate 1.2s pauses after main points gave arguments impact."

---

### 5. Persistent Digital Twin Progress Modeling
The `DigitalTwinService` ensures continuous learning across sessions:
- **Longitudinal Trend Regression**: Fits linear regression models across historical Speech Fluency Scores to calculate trajectory slopes.
- **Next-Session Projections**: Predicts expected performance for the upcoming practice session.
- **Persistent Storage**: Stores session feature vectors, audio summaries, and baseline vocal arousal in PostgreSQL / SQLite.

---

### 6. Central WebSocket Hub & API Architecture
The `WebSocketHub` in `app/hub.py` acts as the single central communication node:
- **`WS /session/{id}`**: Coordinates dual-party streaming:
  - **VR Client (`client_type=vr`)**: Sends voice audio/text chunks in; receives coaching text, emotion signals, and TTS audio bytes out.
  - **Flutter Companion App (`client_type=app`)**: Receives real-time streaming telemetry frames:
    ```json
    {
      "score": 76,
      "emotion_label": "confident",
      "transcript_partial": "Basically our architecture solves the latency issue...",
      "coaching_tip": "Maintain steady cadence",
      "is_final": false,
      "disclaimer": "All metrics are model-derived proxies..."
    }
    ```
- **REST Contract Endpoints**:
  - `POST /session/complete`: Finalizes session, executes metrics aggregation, runs SHAP analysis, updates Digital Twin, and writes to database.
  - `GET /session/{id}`: Returns comprehensive session reports including emotion timeline points and SHAP bar charts.
  - `GET /twin/{user_id}`: Returns Digital Twin profile, history points, and projection.
  - `GET /history/{user_id}`: Returns historical session summaries.
  - `GET /emotion`: Single consistent endpoint returning current emotion readings.
  - `GET /explain`: Returns SHAP breakdown for any session.

---

### 7. Flutter Companion Mobile App
Located in `frontend/`:
- **Live Telemetry Dashboard**: Radial score gauge with animated tweens, color-coded emotion badge, and auto-scrolling live transcript feed.
- **Session Detail Screen**: Interactive area charts for Emotion Timelines, horizontal bar charts for SHAP feature contributions, and trend lines for Digital Twin projections (`fl_chart`).
- **Resilient Connectivity**: Built-in exponential backoff WebSocket reconnection ($1\text{s} \to 2\text{s} \to 4\text{s} \dots$) and local caching via `shared_preferences`.

---

### 8. Unity VR Interactive Audience Simulation
- **Environment**: Meta Quest 3 standalone wireless 6DOF VR stage/conference room.
- **Reactive Audience Engine**: $10\text{--}50$ NPC audience members dynamically reacting to speaker emotional and engagement cues (nodding, taking notes, clapping, looking at phones, leaning forward).

---

## Repository Structure

```
Anubhav/
├── backend/
│   ├── app/
│   │   ├── main.py                  # FastAPI application & router mounting
│   │   ├── hub.py                   # Central WebSocket orchestrator
│   │   ├── config.py                # Environment configuration & disclaimer constants
│   │   ├── db/
│   │   │   ├── database.py          # SQLAlchemy engine & session management
│   │   │   └── models.py            # User, Session, Feedback, DigitalTwin tables
│   │   ├── routes/
│   │   │   ├── session.py           # WS /session/{id}, POST /session/complete, GET /session/{id}
│   │   │   ├── twin.py              # GET /twin/{user_id}
│   │   │   ├── history.py           # GET /history/{user_id}
│   │   │   ├── emotion.py           # GET /emotion (single consistent endpoint)
│   │   │   └── explain.py           # GET /explain (SHAP breakdown)
│   │   ├── services/
│   │   │   ├── sarvam_service.py    # STT Saaras, LLM 30B/105B, TTS Bulbul
│   │   │   ├── metrics_service.py   # Tier 1/2/3 voice & speech metrics engine
│   │   │   ├── scoring_service.py   # Fluency Score & Vocal Arousal baseline delta
│   │   │   ├── emotion_service.py   # Hume EVI + local prosody fallback
│   │   │   ├── xai_service.py       # SHAP TreeExplainer attributions
│   │   │   └── digital_twin_service.py # Longitudinal trend regression & projection
│   │   └── schemas/                 # Pydantic models matching Flutter & VR contracts
│   ├── ml/
│   │   ├── train_scorer.py          # Offline synthetic data generation & model training
│   │   ├── synthetic_dataset.csv    # 600-sample delivery dataset
│   │   └── scorer.pkl               # Serialized Gradient Boosting model artifact
│   ├── tests/                       # 26 unit & integration tests (Pytest)
│   ├── requirements.txt
│   └── .env.example
├── frontend/                        # Flutter companion mobile app
│   ├── lib/
│   │   ├── screens/                 # Live dashboard, Session History, Session Detail
│   │   ├── widgets/                 # ScoreGauge, EmotionBadge, SHAP bar charts
│   │   ├── services/                # ApiService, WebSocketService, CacheService
│   │   ├── providers/               # Provider state management
│   │   └── theme/                   # Emotion-to-color mapping & typography
│   └── pubspec.yaml
└── README.md
```

---

## Quickstart & Verification

### Running the Backend

```bash
# 1. Setup virtual environment
cd backend
python3.11 -m venv .venv
source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Train scoring model & generate artifacts
python ml/train_scorer.py

# 4. Run full test suite (26 passing tests)
pytest tests/ -v

# 5. Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation available at `http://localhost:8000/docs`.

### Running the Flutter Mobile App

```bash
cd frontend
dart pub get
dart analyze lib/      # 0 errors, 0 warnings
flutter run
```

---

## License & Credits
Developed by **Team Kaala Teeka▪️**
All speech, fluency, and emotion metrics are model-derived proxies designed for practice and coaching, and do not constitute clinical assessments.
