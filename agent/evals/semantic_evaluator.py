from __future__ import annotations

import json
from pathlib import Path
from typing import Any


DEFAULT_RUBRIC_PATH = Path(__file__).with_name("semantic_rubric.json")


def load_rubric(path: Path = DEFAULT_RUBRIC_PATH) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def aggregate_semantic_scores(
    scores: dict[str, int],
    rubric_path: Path = DEFAULT_RUBRIC_PATH,
) -> dict[str, Any]:
    """Validate and aggregate externally assigned semantic rubric scores.

    The score assignment itself may be completed by a human reviewer or a future
    LLM judge. This function is deliberately deterministic: it validates dimension
    coverage, score ranges, total score, and the critical-dimension pass rule.
    """
    rubric = load_rubric(rubric_path)
    dimensions = rubric["dimensions"]
    dimension_ids = {item["id"] for item in dimensions}

    missing = dimension_ids - set(scores)
    unknown = set(scores) - dimension_ids
    if missing:
        raise ValueError(f"Missing rubric score(s): {sorted(missing)}")
    if unknown:
        raise ValueError(f"Unknown rubric score(s): {sorted(unknown)}")

    invalid = {
        key: value
        for key, value in scores.items()
        if not isinstance(value, int) or value not in {0, 1, 2}
    }
    if invalid:
        raise ValueError(f"Scores must be integers in [0, 2]: {invalid}")

    total = sum(scores.values())
    recommended_pass_score = int(rubric["scoring"]["recommended_pass_score"])
    critical_ids = set(rubric["scoring"]["critical_dimensions"])
    critical_failures = sorted(
        dimension_id
        for dimension_id in critical_ids
        if scores[dimension_id] == 0
    )

    passed = total >= recommended_pass_score and not critical_failures

    return {
        "rubric_version": rubric["rubric_version"],
        "scores": scores,
        "total_score": total,
        "maximum_score": int(rubric["scoring"]["maximum_score"]),
        "recommended_pass_score": recommended_pass_score,
        "critical_failures": critical_failures,
        "passed": passed,
        "note": (
            "The aggregator validates assigned rubric scores only. Deterministic "
            "tool and numerical checks remain authoritative for tool-use and KPI facts."
        ),
    }
