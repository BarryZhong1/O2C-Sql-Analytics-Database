from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.agent import ask_agent
from evals.trace_evaluator import evaluate_agent_run, load_cases


DEFAULT_OUTPUT = Path("artifacts/live_eval_report.json")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run one or more agent evaluation prompts against the live Responses API, "
            "capture tool traces, and apply deterministic trace checks."
        )
    )
    parser.add_argument(
        "--case",
        action="append",
        dest="case_ids",
        help="Eval case ID to run. Repeat for multiple cases. Default: all cases.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output report path (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=8,
        help="Maximum tool-calling turns per case.",
    )
    return parser.parse_args()


def _select_cases(case_ids: list[str] | None) -> list[dict[str, Any]]:
    cases = load_cases()
    if not case_ids:
        return cases

    requested = set(case_ids)
    selected = [case for case in cases if case["id"] in requested]
    missing = requested - {case["id"] for case in selected}
    if missing:
        raise KeyError(f"Unknown eval case(s): {sorted(missing)}")
    return selected


def run_case(case: dict[str, Any], max_turns: int) -> dict[str, Any]:
    try:
        agent_run = ask_agent(case["input"], max_turns=max_turns)
        trace_report = evaluate_agent_run(case["id"], agent_run)
        return {
            "case_id": case["id"],
            "case_name": case["name"],
            "prompt": case["input"],
            "expected_behavior": case.get("expected_behavior", []),
            "status": "completed",
            "agent_run": agent_run,
            "deterministic_trace_eval": trace_report,
        }
    except Exception as exc:  # noqa: BLE001 - report failures per eval case
        return {
            "case_id": case["id"],
            "case_name": case["name"],
            "prompt": case["input"],
            "expected_behavior": case.get("expected_behavior", []),
            "status": "error",
            "error": f"{type(exc).__name__}: {exc}",
        }


def main() -> int:
    args = parse_args()
    cases = _select_cases(args.case_ids)

    results = [run_case(case, args.max_turns) for case in cases]
    completed = [result for result in results if result["status"] == "completed"]
    passed = [
        result
        for result in completed
        if result["deterministic_trace_eval"]["trace_checks_passed"]
    ]

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "eval_layer": "live_agent_plus_deterministic_trace_checks",
        "cases_requested": len(cases),
        "cases_completed": len(completed),
        "trace_checks_passed": len(passed),
        "trace_pass_rate": (
            round(len(passed) / len(completed), 4) if completed else None
        ),
        "semantic_scoring_status": (
            "not_yet_automated; review expected_behavior manually or add rubric judge"
        ),
        "results": results,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, indent=2, default=str))

    has_errors = any(result["status"] == "error" for result in results)
    trace_failures = len(passed) != len(completed)
    return 1 if has_errors or trace_failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
