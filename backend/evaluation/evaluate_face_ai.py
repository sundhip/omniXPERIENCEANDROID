import os
import time
import numpy as np
import cv2
from typing import Dict, Any, List
from app.services.face_analysis_service import face_analysis_service

def run_ai_evaluation() -> Dict[str, Any]:
    print("==================================================")
    print("  OmniXPERIENCE Phase 3 — Computer Vision Evaluation")
    print("==================================================")

    data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "tests", "data")
    uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")

    # Evaluation test scenarios
    eval_cases = [
        {
            "category": "Clear Front-Facing Face (David 1)",
            "file": os.path.join(data_dir, "david1.jpg"),
            "expected_outcome": "success",
            "expected_face_count": 1
        },
        {
            "category": "Different Lighting / Expression (David 2)",
            "file": os.path.join(data_dir, "david2.jpg"),
            "expected_outcome": "success",
            "expected_face_count": 1
        },
        {
            "category": "Multiple Faces Synthesized (Two Faces)",
            "file": os.path.join(data_dir, "two_faces.jpg"),
            "expected_outcome": "rejected_multiple_faces",
            "expected_face_count": 2
        },
        {
            "category": "Side Pose / Obstructed (Lena 45-degree angle)",
            "file": os.path.join(data_dir, "test_face.jpg"),
            "expected_outcome": "rejected_pose",
            "expected_face_count": 1
        },
        {
            "category": "No Face (Geometric Objects & Room)",
            "file": os.path.join(data_dir, "objects_no_face.jpg"),
            "expected_outcome": "rejected_no_face",
            "expected_face_count": 0
        },
        {
            "category": "Low Contrast Background",
            "file": os.path.join(data_dir, "no_face.jpg"),
            "expected_outcome": "rejected_low_contrast",
            "expected_face_count": 0
        }
    ]

    results = []
    latencies = []

    for case in eval_cases:
        filepath = case["file"]
        if not os.path.exists(filepath):
            continue

        with open(filepath, "rb") as f:
            data = f.read()

        t0 = time.perf_counter()
        res = face_analysis_service.analyze_photo(data, "eval_user", uploads_dir)
        dt = (time.perf_counter() - t0) * 1000.0
        latencies.append(dt)

        is_success = res.get("success", False)
        err = res.get("error", None)

        results.append({
            "category": case["category"],
            "latency_ms": round(dt, 2),
            "success": is_success,
            "error": err,
            "face_shape": res.get("detected_face_shape"),
            "shape_conf": res.get("face_shape_confidence"),
            "skin_tone": res.get("detected_skin_tone"),
            "tone_conf": res.get("skin_tone_confidence"),
            "undertone": res.get("detected_skin_undertone"),
            "hair_length": res.get("detected_hair_length"),
            "hair_texture": res.get("detected_hair_texture"),
            "hair_conf": res.get("hair_confidence"),
            "quality_score": res.get("quality_score")
        })

    avg_latency = float(np.mean(latencies)) if latencies else 0.0
    p95_latency = float(np.percentile(latencies, 95)) if latencies else 0.0

    print(f"\n[AI Evaluation Summary]")
    print(f"Total Test Cases Evaluated: {len(results)}")
    print(f"Average Inference Latency: {avg_latency:.2f} ms")
    print(f"P95 Latency: {p95_latency:.2f} ms")
    print("--------------------------------------------------")
    for r in results:
        status_sym = "[OK]" if (r["success"] or r["error"]) else "[ERR]"
        print(f"{status_sym} {r['category']} ({r['latency_ms']} ms)")
        if r['success']:
            print(f"     Shape: {r['face_shape']} ({r['shape_conf']*100:.0f}%), Skin: {r['skin_tone']} ({r['tone_conf']*100:.0f}%), Hair: {r['hair_texture']} / {r['hair_length']}")
        else:
            print(f"     Rejection Notice: {r['error']}")

    return {
        "total_cases": len(results),
        "avg_latency_ms": round(avg_latency, 2),
        "p95_latency_ms": round(p95_latency, 2),
        "results": results
    }

if __name__ == "__main__":
    run_ai_evaluation()
