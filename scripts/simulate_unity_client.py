#!/usr/bin/env python3
"""Simulate Unity VR Headset WebSocket Client for Anubhav Backend Hub.

Demonstrates:
1. Connecting to WS /session/{id}?client_type=vr
2. Streaming text / audio chunks into the hub
3. Receiving real-time coach feedback (score, emotion, coaching tips)
4. Triggering POST /session/complete to finalize metrics and update Digital Twin.
"""

import asyncio
import json
import logging
import sys
import websockets
import httpx

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [UnitySimulator]: %(message)s"
)
logger = logging.getLogger("unity_sim")

BACKEND_HOST = "127.0.0.1"
BACKEND_PORT = 8000
SESSION_ID = "live_001"
USER_ID = "user_001"

WS_URL = f"ws://{BACKEND_HOST}:{BACKEND_PORT}/session/{SESSION_ID}?client_type=vr"
COMPLETE_URL = f"http://{BACKEND_HOST}:{BACKEND_PORT}/session/complete"

SPEECH_CHUNKS = [
    "Good morning everyone. Today I am pitching our AI system for public speaking.",
    "Um, matlab, our biggest technical hurdle was latency, but we solved it with streaming WebSockets.",
    "Notice how our speech rate remains steady at around 130 words per minute.",
    "Thank you for listening, and I am excited to show our live demo!",
]


async def receive_coach_feedback(ws):
    """Listens for AI Coach responses and audio chunks from backend."""
    try:
        async for message in ws:
            if isinstance(message, str):
                try:
                    data = json.loads(message)
                    if data.get("type") == "coach_feedback":
                        logger.info(
                            f"⭐ COACH FEEDBACK RECEIVED -> Score: {data.get('score')} | "
                            f"Emotion: {data.get('emotion')} | Tip: \"{data.get('coaching_text')}\""
                        )
                    elif data.get("type") == "pong":
                        logger.debug("Received pong from server")
                except json.JSONDecodeError:
                    logger.info(f"Received raw text: {message}")
            elif isinstance(message, bytes):
                logger.info(f"🔊 Received TTS audio chunk from coach: {len(message)} bytes")
    except asyncio.CancelledError:
        pass
    except Exception as e:
        logger.warning(f"Receiver loop closed: {e}")


async def simulate_unity_speech():
    logger.info(f"Connecting to Anubhav WebSocket Hub at {WS_URL}...")
    try:
        async with websockets.connect(WS_URL) as ws:
            logger.info("Connected! Unity VR client is now registered.")

            # Start background listener for coach feedback
            listener_task = asyncio.create_task(receive_coach_feedback(ws))

            # Stream simulated chunks every 2.5 seconds
            for idx, chunk in enumerate(SPEECH_CHUNKS, start=1):
                await asyncio.sleep(2.0)
                logger.info(f"[{idx}/{len(SPEECH_CHUNKS)}] Speaking: \"{chunk}\"")
                payload = {
                    "type": "text_chunk",
                    "text": chunk,
                }
                await ws.send(json.dumps(payload))

            # Wait a moment for final feedback
            await asyncio.sleep(2.0)
            listener_task.cancel()
            logger.info("Finished speaking in VR. Disconnecting WebSocket.")
    except Exception as e:
        logger.error(f"WebSocket connection error: {e}")
        return

    # Post session completion to finalize metrics
    logger.info(f"Calling {COMPLETE_URL} to finalize session...")
    complete_payload = {
        "session_id": SESSION_ID,
        "user_id": USER_ID,
        "topic": "Unity VR Presentation Demo",
        "audience_size": "50",
        "environment": "Auditorium",
        "final_transcript": " ".join(SPEECH_CHUNKS),
    }

    async with httpx.AsyncClient() as client:
        res = await client.post(COMPLETE_URL, json=complete_payload)
        if res.status_code == 200:
            data = res.json()
            sess = data.get("session", {})
            logger.info("✅ Session completed successfully! DB & Digital Twin updated.")
            logger.info(f"   Status: {data.get('status')}")
            logger.info(f"   Overall Score: {sess.get('overall_score')}/100")
            logger.info(f"   Transcript: \"{sess.get('transcript')[:80]}...\"")
            logger.info(f"   Coaching Advice: \"{sess.get('coaching_text')}\"")
            logger.info(f"   SHAP Factors: {len(sess.get('shap_breakdown', []))} features evaluated")
            logger.info(f"   Disclaimer: {data.get('disclaimer')}")
        else:
            logger.error(f"Failed to complete session: {res.status_code} - {res.text}")


if __name__ == "__main__":
    asyncio.run(simulate_unity_speech())
