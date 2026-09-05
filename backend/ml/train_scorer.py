"""Offline training script for the Speech Fluency Scoring model.
Generates synthetic public speaking delivery data, trains a SHAP-compatible
Tree-based Regressor, and pickles the trained model artifact.
"""

import os
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error

FEATURE_NAMES = [
    "wpm",
    "filler_rate",
    "pause_count",
    "total_pause_duration",
    "rms_loudness",
    "prosody_variance",
    "repetition_count",
    "self_correction_count",
]


def generate_synthetic_data(num_samples: int = 500, random_state: int = 42) -> pd.DataFrame:
    """Generate realistic synthetic features and ground-truth fluency scores."""
    np.random.seed(random_state)

    wpm = np.random.normal(loc=138.0, scale=22.0, size=num_samples).clip(80, 210)
    filler_rate = np.random.exponential(scale=2.5, size=num_samples).clip(0.0, 12.0)
    pause_count = np.random.poisson(lam=4.0, size=num_samples).clip(0, 15)
    total_pause_duration = (pause_count * np.random.uniform(0.3, 1.4, size=num_samples)).clip(0.0, 20.0)
    rms_loudness = np.random.normal(loc=0.14, scale=0.04, size=num_samples).clip(0.04, 0.30)
    prosody_variance = np.random.normal(loc=0.52, scale=0.15, size=num_samples).clip(0.15, 0.95)
    repetition_count = np.random.poisson(lam=0.8, size=num_samples).clip(0, 6)
    self_correction_count = np.random.poisson(lam=0.6, size=num_samples).clip(0, 5)

    # Ground truth formula with non-linear penalties and noise
    # Pacing optimal at 135-150 WPM
    pace_penalty = np.abs(wpm - 142.0) * 0.35
    filler_penalty = (filler_rate ** 1.3) * 3.2
    pause_penalty = (total_pause_duration / np.maximum(pause_count, 1) - 0.75).clip(0, 5) * 6.0
    rep_penalty = repetition_count * 4.5
    corr_penalty = self_correction_count * 5.0
    prosody_boost = (prosody_variance - 0.3).clip(0, 0.6) * 12.0

    noise = np.random.normal(0, 2.5, size=num_samples)

    score = 92.0 - pace_penalty - filler_penalty - pause_penalty - rep_penalty - corr_penalty + prosody_boost + noise
    score = score.clip(35.0, 98.0)

    df = pd.DataFrame({
        "wpm": np.round(wpm, 1),
        "filler_rate": np.round(filler_rate, 2),
        "pause_count": pause_count,
        "total_pause_duration": np.round(total_pause_duration, 2),
        "rms_loudness": np.round(rms_loudness, 3),
        "prosody_variance": np.round(prosody_variance, 3),
        "repetition_count": repetition_count,
        "self_correction_count": self_correction_count,
        "speech_fluency_score": np.round(score, 1),
    })

    return df


def train_and_save_scorer(output_dir: str = "backend/ml"):
    """Train GradientBoostingRegressor and save synthetic data & model artifact."""
    os.makedirs(output_dir, exist_ok=True)
    df = generate_synthetic_data(num_samples=600)

    # Save synthetic dataset
    csv_path = os.path.join(output_dir, "synthetic_dataset.csv")
    df.to_csv(csv_path, index=False)
    print(f"Saved synthetic dataset to {csv_path} ({len(df)} samples)")

    X = df[FEATURE_NAMES]
    y = df["speech_fluency_score"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = GradientBoostingRegressor(
        n_estimators=80,
        max_depth=4,
        learning_rate=0.08,
        random_state=42,
    )
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    r2 = r2_score(y_test, preds)
    mae = mean_absolute_error(y_test, preds)
    print(f"Scorer trained successfully. Test R^2: {r2:.3f}, MAE: {mae:.2f}")

    # Save artifact
    pkl_path = os.path.join(output_dir, "scorer.pkl")
    payload = {
        "model": model,
        "feature_names": FEATURE_NAMES,
        "metrics": {"r2": r2, "mae": mae},
        "version": "1.0.0",
    }
    joblib.dump(payload, pkl_path)
    print(f"Saved model artifact to {pkl_path}")
    return pkl_path


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    train_and_save_scorer(output_dir=current_dir)
