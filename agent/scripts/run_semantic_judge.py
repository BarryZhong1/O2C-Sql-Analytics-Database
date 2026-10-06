from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from evals.llm_judge import judge_agent_run
from evals.trace_evaluator import load_cases


DEFAULT_INPUT = Path("artifacts/live_eval_report.json")
DEFAULT_OUTPUT = Path("artifacts/semantic_eval_report.json")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Apply the documented semantic rubric to completed live agent eval runs "
            "using an optional LLM-as-Judge layer."
        )
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=DEFAULT_INPUT,
        help=f"Live eval report path (default: {DEFAULT_INPUT})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Semantic report path (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--model",
        default=None,
        help="Optional judge model override. Defaults to OPENAI_MODEL.",
    )
    return parser.parse_args()


def _case_index() -> dict[str, dict[str, Any]]:
    return {case["id"]: case for case in load_cases()}


def judge_report(
    live_report: dict[str, Any],
    model: str | None = None,
) -> dict[str, Any]:
    cases = _case_index()
    results: list[dict[str, Any]] = []

    for live_result in live_report.get("results", []):
        case_id = live_result.get("case_id")
        case = cases.get(case_id)
        if case is None:
            results.append(
                {
                    "case_id": case_id,
                    "status": "error",
                    "error": "Unknown evaluation case in live report",
                }
            )
            continue

        if live_result.get("status") != "completed":
            results.append(
                {
                    "case_id": case_id,
                    "case_name": case["name"],
                    "status": "skipped",
                    "reason": "Live agent run did not complete",
                }
            )
            continue

        try:
            semantic = judge_agent_run(
                case,
                live_result["agent_run"],
                model=model,
            )
            results.append(
                {
                    "case_id": case_id,
                    "case_name": case["name"],
                    "status": "completed",
                    "semantic_eval": semantic,
                }
            )
        except Exception as exc:  # noqa: BLE001 - preserve per-case judge errors
            results.append(
                {
                    "case_id": case_id,
                    "case_name": case["name"],
                    "status": "error",
                    "error": f"{type(exc).__name__}: {exc}",
                }
            )

    completed = [item for item in results if item["status"] == "completed"]
    passed = [item for item in completed if item["semantic_eval"]["passed"]]
    errors = [item for item in results if item["status"] == "error"]
    skipped = [item for item in results if item["status"] == "skipped"]

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "eval_layer": "llm_semantic_rubric",
        "source_report_generated_at": live_report.get("generated_at"),
        "cases_seen": len(results),
        "cases_completed": len(completed),
        "cases_passed": len(passed),
        "cases_failed": len(completed) - len(passed),
        "cases_error": len(errors),
        "cases_skipped": len(skipped),
        "semantic_pass_rate": (
            round(len(passed) / len(completed), 4) if completed else None
        ),
        "authority_note": (
            "Semantic scoring is advisory for answer quality. Deterministic trace and "
            "numerical checks remain authoritative for tool-use and KPI facts."
        ),
        "results": results,
    }


def main() -> int:
    args = parse_args()
    live_report = json.loads(args.input.read_text(encoding="utf-8"))
    report = judge_report(live_report, model=args.model)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, default=str) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, indent=2, default=str))

    all_completed = report["cases_completed"] == report["cases_seen"]
    all_passed = report["cases_failed"] == 0
    no_errors = report["cases_error"] == 0
    return 0 if all_completed and all_passed and no_errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
