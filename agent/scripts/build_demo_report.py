from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


STAGE_LABELS = {
    "order_to_ship_days": "Order → Ship",
    "ship_to_invoice_days": "Ship → Invoice",
    "invoice_to_payment_days": "Invoice → Payment",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a Markdown portfolio report from a demo API response."
    )
    parser.add_argument("--response", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--design", type=Path, default=None)
    parser.add_argument(
        "--question",
        default=(
            "Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. "
            "Identify the stage that deteriorated most, drill into the strongest "
            "driver, and test a realistic improvement scenario."
        ),
    )
    return parser.parse_args()


def fmt(value: Any, digits: int = 2) -> str:
    if value is None:
        return "N/A"
    try:
        return f"{float(value):.{digits}f}"
    except (TypeError, ValueError):
        return str(value)


def tool_label(name: str) -> str:
    return {
        "compare_stage_performance": "Compare stages",
        "analyze_process": "Drill down",
        "retrieve_policy": "Retrieve context",
        "simulate_stage_improvement": "Run scenario",
        "get_stage_baseline": "Get baseline",
    }.get(name, name)


def tool_note(item: dict[str, Any]) -> str:
    name = item.get("tool")
    if name == "compare_stage_performance":
        return "Rank period-over-period deterioration"
    if name == "analyze_process":
        group_by = (item.get("arguments") or {}).get("group_by") or "KPI"
        return f"Analyze {group_by} pattern"
    if name == "retrieve_policy":
        return "Ground interpretation in business context"
    if name == "simulate_stage_improvement":
        return "Calculate transparent what-if impact"
    return "Approved analytical tool"


def build_report(
    payload: dict[str, Any],
    question: str,
    design: dict[str, Any] | None,
) -> str:
    trace = payload.get("tool_trace") or []
    stage_call = next(
        (item for item in trace if item.get("tool") == "compare_stage_performance"),
        None,
    )
    channel_call = next(
        (
            item
            for item in trace
            if item.get("tool") == "analyze_process"
            and (item.get("arguments") or {}).get("group_by") == "channel"
        ),
        None,
    )
    policy_call = next(
        (item for item in trace if item.get("tool") == "retrieve_policy"),
        None,
    )
    scenario_call = next(
        (item for item in trace if item.get("tool") == "simulate_stage_improvement"),
        None,
    )

    lines = [
        "# O2C Process Improvement Investigation",
        "",
        f"Backend: **{payload.get('backend', 'unknown')}**",
        f"Tool calls: **{payload.get('tool_call_count', len(trace))}**",
        "",
        "## Business question",
        "",
        question,
    ]

    if design:
        lines.extend(
            [
                "",
                "## Agent design versions",
                "",
                f"- System prompt: **{design.get('system_prompt_version', 'unknown')}**",
                f"- Tool catalog: **{design.get('tool_catalog_version', 'unknown')}**",
            ]
        )

    if stage_call:
        result = stage_call.get("result") or {}
        current = result.get("current_period") or {}
        comparison = result.get("comparison_period") or {}
        rows = result.get("deterioration_rank") or []
        lines.extend(
            [
                "",
                "## KPI summary",
                "",
                f"- Q2 total O2C cycle: **{fmt(comparison.get('observed_total_o2c_cycle_days'))} days**",
                f"- Q3 total O2C cycle: **{fmt(current.get('observed_total_o2c_cycle_days'))} days**",
                "",
                "### Stage comparison",
                "",
                "| Stage | Q2 | Q3 | Change |",
                "|---|---:|---:|---:|",
            ]
        )
        for row in rows:
            change = float(row.get("absolute_change_days") or 0)
            prefix = "+" if change > 0 else ""
            lines.append(
                "| "
                + STAGE_LABELS.get(row.get("stage"), str(row.get("stage")))
                + f" | {fmt(row.get('comparison_days'))}"
                + f" | {fmt(row.get('current_days'))}"
                + f" | {prefix}{fmt(change)} |"
            )

    if channel_call:
        result = channel_call.get("result") or {}
        rows = (
            (result.get("group_change_summary") or {}).get("deterioration_rank")
            or []
        )
        lines.extend(
            [
                "",
                "### Channel comparison",
                "",
                "| Channel | Q2 | Q3 | Change |",
                "|---|---:|---:|---:|",
            ]
        )
        for row in rows:
            change = float(row.get("absolute_change") or 0)
            prefix = "+" if change > 0 else ""
            lines.append(
                f"| {row.get('dimension_value', 'N/A')}"
                f" | {fmt(row.get('comparison_value'))}"
                f" | {fmt(row.get('current_value'))}"
                f" | {prefix}{fmt(change)} |"
            )

    if policy_call:
        matches = (policy_call.get("result") or {}).get("matches") or []
        if matches:
            lines.extend(["", "## Retrieved business context", ""])
            for match in matches[:3]:
                paragraph = " ".join(str(match.get("paragraph", "")).split())
                lines.append(
                    f"- **{match.get('source', 'context')}**: {paragraph}"
                )

    if scenario_call:
        result = scenario_call.get("result") or {}
        baseline = result.get("baseline") or {}
        scenario = result.get("scenario") or {}
        lines.extend(
            [
                "",
                "## What-if scenario",
                "",
                f"- Modeled baseline cash cycle: **{fmt(baseline.get('modeled_cash_cycle_days'))} days**",
                f"- Modeled scenario cash cycle: **{fmt(scenario.get('modeled_cash_cycle_days'))} days**",
                f"- Modeled days saved: **{fmt(scenario.get('days_saved'))} days**",
                f"- Modeled improvement: **{fmt(scenario.get('percent_improvement'))}%**",
                "",
                "The scenario is assumption-based and is not a guaranteed intervention effect.",
            ]
        )

    lines.extend(
        [
            "",
            "## Findings and recommendation",
            "",
            payload.get("answer") or "No answer returned.",
            "",
            "## Tool path",
            "",
        ]
    )
    for index, item in enumerate(trace, start=1):
        lines.append(
            f"{index}. **{tool_label(str(item.get('tool')))}** — {tool_note(item)}"
        )

    lines.extend(["", "## Evidence note", ""])
    if payload.get("backend") == "mock":
        lines.append(
            "This report was generated in scripted mock mode. The SQL, retrieval, "
            "and scenario results are real project outputs, while the model-side "
            "investigation path is scripted."
        )
    else:
        lines.append(
            "This report was generated using the configured OpenAI model backend."
        )

    lines.extend(
        [
            "",
            "## Governance",
            "",
            "Recommendations are decision support only. Operational or policy "
            "changes require human approval.",
        ]
    )
    return "\n".join(lines).strip() + "\n"


def main() -> int:
    args = parse_args()
    payload = json.loads(args.response.read_text(encoding="utf-8"))
    design = None
    if args.design and args.design.exists():
        design = json.loads(args.design.read_text(encoding="utf-8"))

    report = build_report(payload, args.question, design)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(report, encoding="utf-8")
    print(f"Wrote demo report to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
