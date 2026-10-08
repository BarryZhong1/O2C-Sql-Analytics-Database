from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_LIVE = Path("artifacts/live_eval_report.json")
DEFAULT_SEMANTIC = Path("artifacts/semantic_eval_report.json")
DEFAULT_BENCHMARK = Path("evals/scenario_v1_benchmark.json")
DEFAULT_OUTPUT = Path("artifacts/evaluation_summary.md")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a portfolio-ready Markdown summary from evaluation artifacts."
    )
    parser.add_argument("--live", type=Path, default=DEFAULT_LIVE)
    parser.add_argument("--semantic", type=Path, default=DEFAULT_SEMANTIC)
    parser.add_argument("--benchmark", type=Path, default=DEFAULT_BENCHMARK)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def _load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _semantic_index(report: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    if not report:
        return {}
    return {
        item.get("case_id"): item
        for item in report.get("results", [])
        if item.get("case_id")
    }


def _status_mark(value: bool | None) -> str:
    if value is True:
        return "PASS"
    if value is False:
        return "FAIL"
    return "N/A"


def _observability_totals(live: dict[str, Any]) -> dict[str, Any]:
    completed_runs = [
        item.get("agent_run") or {}
        for item in live.get("results", [])
        if item.get("status") == "completed"
    ]
    elapsed_values = [
        run["elapsed_ms"]
        for run in completed_runs
        if isinstance(run.get("elapsed_ms"), (int, float))
    ]

    token_fields = (
        "input_tokens",
        "output_tokens",
        "total_tokens",
        "cached_input_tokens",
        "reasoning_tokens",
    )
    token_totals = {field: 0 for field in token_fields}
    model_call_count = 0
    runs_with_usage = 0

    for run in completed_runs:
        usage = run.get("usage") or {}
        if usage:
            runs_with_usage += 1
        for field in token_fields:
            value = usage.get(field)
            if isinstance(value, int):
                token_totals[field] += value
        calls = run.get("model_call_count")
        if isinstance(calls, int):
            model_call_count += calls

    return {
        "runs_with_latency": len(elapsed_values),
        "average_elapsed_ms": (
            round(sum(elapsed_values) / len(elapsed_values), 2)
            if elapsed_values
            else None
        ),
        "runs_with_usage": runs_with_usage,
        "model_call_count": model_call_count,
        **token_totals,
    }


def build_summary(
    live: dict[str, Any],
    benchmark: dict[str, Any],
    semantic: dict[str, Any] | None = None,
) -> str:
    baseline = benchmark["baseline_period"]
    problem = benchmark["problem_period"]
    channels = benchmark["channel_order_to_ship_days"]
    semantic_by_case = _semantic_index(semantic)
    observability = _observability_totals(live)

    lines = [
        "# Agent Evaluation Summary",
        "",
        "## Controlled benchmark",
        "",
        f"Scenario: `{benchmark['scenario_id']}` ({benchmark['status']}).",
        "",
        f"- {baseline['label']} total O2C: **{baseline['total_o2c_cycle_days']:.2f} days**",
        f"- {problem['label']} total O2C: **{problem['total_o2c_cycle_days']:.2f} days**",
        (
            f"- Order-to-ship: **{baseline['order_to_ship_days']:.2f} → "
            f"{problem['order_to_ship_days']:.2f} days**"
        ),
        (
            f"- Marketplace order-to-ship: **{channels['Q2']['Marketplace']:.2f} → "
            f"{channels['Q3']['Marketplace']:.2f} days**"
        ),
        (
            f"- Invoice-to-payment: **{baseline['invoice_to_payment_days']:.2f} → "
            f"{problem['invoice_to_payment_days']:.2f} days**"
        ),
        "",
        "The benchmark intentionally makes invoice-to-payment the longest absolute stage while order-to-ship is the stage that deteriorates most.",
        "",
        "## Behavior evaluation totals",
        "",
        f"- Model backend: **{live.get('model_backend', 'unknown')}**",
        f"- Evidence scope: **{live.get('evidence_scope', 'unspecified')}**",
        f"- Cases requested: **{live.get('cases_requested', 'N/A')}**",
        f"- Cases completed: **{live.get('cases_completed', 'N/A')}**",
        f"- Deterministic trace checks passed: **{live.get('trace_checks_passed', 'N/A')}**",
        f"- Deterministic trace pass rate: **{live.get('trace_pass_rate', 'N/A')}**",
    ]

    if semantic:
        lines.extend(
            [
                f"- Semantic cases completed: **{semantic.get('cases_completed', 'N/A')}**",
                f"- Semantic cases passed: **{semantic.get('cases_passed', 'N/A')}**",
                f"- Semantic pass rate: **{semantic.get('semantic_pass_rate', 'N/A')}**",
            ]
        )
    else:
        lines.append("- Semantic rubric: **not included in this summary**")

    lines.extend(["", "## Runtime observability", ""])
    if observability["runs_with_latency"]:
        lines.append(
            f"- Average end-to-end agent latency: **{observability['average_elapsed_ms']:.2f} ms**"
        )
    else:
        lines.append("- Average end-to-end agent latency: **not captured**")

    if observability["runs_with_usage"]:
        lines.extend(
            [
                f"- Model calls across completed cases: **{observability['model_call_count']}**",
                f"- Input tokens: **{observability['input_tokens']}**",
                f"- Cached input tokens: **{observability['cached_input_tokens']}**",
                f"- Output tokens: **{observability['output_tokens']}**",
                f"- Reasoning tokens: **{observability['reasoning_tokens']}**",
                f"- Total tokens: **{observability['total_tokens']}**",
            ]
        )
    else:
        lines.append("- Model token usage: **not captured**")

    lines.extend(
        [
            "",
            "## Per-case results",
            "",
            "| Case | Status | Trace | Semantic | Score | Latency | Tokens | Tool sequence |",
            "|---|---|---|---|---:|---:|---:|---|",
        ]
    )

    for item in live.get("results", []):
        case_id = item.get("case_id", "unknown")
        status = item.get("status", "unknown")
        trace_eval = item.get("deterministic_trace_eval") or {}
        trace_pass = trace_eval.get("trace_checks_passed")
        sequence = " → ".join(trace_eval.get("tool_sequence") or []) or "—"
        agent_run = item.get("agent_run") or {}
        elapsed = agent_run.get("elapsed_ms")
        latency_text = f"{elapsed:.0f} ms" if isinstance(elapsed, (int, float)) else "—"
        total_tokens = (agent_run.get("usage") or {}).get("total_tokens")
        token_text = str(total_tokens) if isinstance(total_tokens, int) else "—"

        semantic_item = semantic_by_case.get(case_id) or {}
        semantic_eval = semantic_item.get("semantic_eval") or {}
        semantic_pass = semantic_eval.get("passed")
        semantic_score = semantic_eval.get("total_score")
        max_score = semantic_eval.get("maximum_score")
        score_text = (
            f"{semantic_score}/{max_score}"
            if semantic_score is not None and max_score is not None
            else "—"
        )

        lines.append(
            f"| `{case_id}` | {status} | {_status_mark(trace_pass)} | "
            f"{_status_mark(semantic_pass)} | {score_text} | {latency_text} | "
            f"{token_text} | {sequence} |"
        )

    failed_checks: list[str] = []
    for item in live.get("results", []):
        trace_eval = item.get("deterministic_trace_eval") or {}
        for check in trace_eval.get("checks", []):
            if check.get("passed") is False:
                failed_checks.append(
                    f"- `{item.get('case_id')}` / `{check.get('name')}`: {check.get('detail')}"
                )

    lines.extend(["", "## Deterministic failures", ""])
    if failed_checks:
        lines.extend(failed_checks)
    else:
        lines.append("No deterministic trace failures were recorded.")

    semantic_failures: list[str] = []
    if semantic:
        for item in semantic.get("results", []):
            semantic_eval = item.get("semantic_eval") or {}
            if item.get("status") == "completed" and semantic_eval.get("passed") is False:
                critical = semantic_eval.get("critical_failures") or []
                semantic_failures.append(
                    f"- `{item.get('case_id')}` scored {semantic_eval.get('total_score')}/"
                    f"{semantic_eval.get('maximum_score')}; critical failures: {critical or 'none'}"
                )
            elif item.get("status") == "error":
                semantic_failures.append(
                    f"- `{item.get('case_id')}` judge error: {item.get('error')}"
                )

    lines.extend(["", "## Semantic failures", ""])
    if semantic_failures:
        lines.extend(semantic_failures)
    elif semantic:
        lines.append("No semantic rubric failures were recorded.")
    else:
        lines.append("Semantic evaluation was not supplied.")

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "Deterministic trace and numerical checks are authoritative for tool-use and KPI facts. Semantic scores are a separate quality layer for synthesis, causal discipline, decision usefulness, risks, and approval boundaries.",
            "",
            "Latency and token metrics describe runtime behavior and evaluation cost characteristics; they are not treated as answer-quality scores.",
            "",
            ("Mock-backend results validate scripted orchestration and deterministic integration only; they must not be reported as real-model reasoning or semantic quality." if live.get("model_backend") == "mock" else "This report uses the configured non-mock model backend; semantic quality still depends on the separate rubric layer when present."),
            "",
            "Prompt or tool changes should be tied to recorded failures rather than tuned against hidden Scenario V1 ground truth.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    live = _load(args.live)
    benchmark = _load(args.benchmark)
    semantic = _load(args.semantic) if args.semantic.exists() else None

    output = build_summary(live, benchmark, semantic)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
