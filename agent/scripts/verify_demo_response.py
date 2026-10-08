from __future__ import annotations

import argparse
import json
from pathlib import Path


EXPECTED_TOOLS = [
    "compare_stage_performance",
    "analyze_process",
    "retrieve_policy",
    "simulate_stage_improvement",
]

EXPECTED_ANSWER_MARKERS = [
    "FINDING",
    "Marketplace",
    "WHAT-IF SCENARIO",
    "NEXT ACTION",
    "DEMO NOTE",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify the zero-cost portfolio demo API response.")
    parser.add_argument("response", type=Path)
    return parser.parse_args()


def verify(payload: dict) -> None:
    assert payload.get("backend") == "mock", payload.get("backend")
    trace = payload.get("tool_trace") or []
    tools = [item.get("tool") for item in trace]
    assert tools == EXPECTED_TOOLS, tools
    assert payload.get("tool_call_count") == len(EXPECTED_TOOLS), payload.get("tool_call_count")

    answer = payload.get("answer") or ""
    for marker in EXPECTED_ANSWER_MARKERS:
        assert marker in answer, f"Missing answer marker: {marker}"


def main() -> int:
    args = parse_args()
    payload = json.loads(args.response.read_text(encoding="utf-8"))
    verify(payload)
    print("Full portfolio demo API path passed.")
    print("Tool path:", " -> ".join(EXPECTED_TOOLS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
