"""Unit tests for SarvamService (Saaras STT, Sarvam-105B LLM, Bulbul TTS)."""

import pytest
from app.services.sarvam_service import SarvamService, build_coaching_prompt


@pytest.mark.asyncio
async def test_build_coaching_prompt():
    prompt = build_coaching_prompt(
        transcript="We, um, achieved great results today.",
        emotion_label="Confident",
        current_score=82.5,
        recent_history=[{"session_index": 1, "score": 75}, {"session_index": 2, "score": 80}],
    )
    assert "Sarvam-105B" not in prompt  # check prompt content
    assert "82.5" in prompt
    assert "Confident" in prompt
    assert "Session 1: Score 75" in prompt
    assert "DO NOT give generic praise" in prompt


@pytest.mark.asyncio
async def test_sarvam_stt_mock():
    svc = SarvamService()
    result = await svc.transcribe_audio_chunk(b"fake_audio_bytes")
    assert "transcript" in result
    assert result["verbatim"] is True
    assert len(result["words"]) > 0


@pytest.mark.asyncio
async def test_sarvam_llm_mock():
    svc = SarvamService()
    coaching = await svc.generate_coaching(
        transcript="Basically, matlab, our architecture solves the latency issue directly.",
        emotion_label="Nervous",
        current_score=68.0,
    )
    assert len(coaching) > 10
    # Must not be generic praise
    assert "Good job" not in coaching


@pytest.mark.asyncio
async def test_sarvam_tts_mock():
    svc = SarvamService()
    audio = await svc.synthesize_speech("Hold a silent 1-second pause instead.")
    assert isinstance(audio, bytes)
    assert len(audio) > 44  # Valid WAV header + audio payload


@pytest.mark.asyncio
async def test_sarvam_connectivity_check():
    svc = SarvamService()
    report = await svc.verify_connectivity()
    assert report["stt"] is True
    assert report["llm"] is True
    assert report["tts"] is True
