from __future__ import annotations

import argparse
import json
from pathlib import Path

from evals.trace_evaluator import evaluate_agent_run


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Evaluate a captured agent response against deterministic tool-trace "
            "requirements from evals/eval_cases.json."
        )
    )
    parser.add_argument("case_id", help="Eval case ID, for example eval_005")
    parser.add_argument(
        "run_json",
        type=Path,
        help="Path to JSON returned by the /agent/ask endpoint",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional path for the evaluation JSON report",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    agent_run = json.loads(args.run_json.read_text(encoding="utf-8"))
    result = evaluate_agent_run(args.case_id, agent_run)

    rendered = json.dumps(result, indent=2)
    print(rendered)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")

    return 0 if result["trace_checks_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
