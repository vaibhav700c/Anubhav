import asyncio
from app.services.metrics_service import MetricsService

ms = MetricsService()
res = ms.compute_tier2_fluency("Hello everyone, uh uh welcome to our pitch, um like yeah")
print(res)
