from app.services.metrics_service import MetricsService
from app.services.scoring_service import ScoringService
from app.services.xai_service import XAIService

transcript = "Hello um uh basically I mean literally like yeah we are doing this."
ms = MetricsService()
features = ms.extract_all_metrics(transcript=transcript)

ss = ScoringService()
res = ss.compute_fluency_score(features)

xs = XAIService()
xai_res = xs.explain_delivery(features, res["overall_score"])
print(f"Fillers: {features['filler_count']}, Rate: {features['filler_rate']}%")
print(f"Score: {res['overall_score']}")
for shap in xai_res["shap_breakdown"]:
    print(f"- {shap['feature']}: {shap['explanation']}")
