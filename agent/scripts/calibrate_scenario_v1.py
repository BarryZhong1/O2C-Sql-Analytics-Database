from __future__ import annotations

import json
import sys
from typing import Any

from app.tools.process_analytics import analyze_process, compare_stage_performance
from app.workflow import investigate_cycle_time


CURRENT = ("2024-07-01", "2024-09-30")
BASELINE = ("2024-04-01", "2024-06-30")


def _row_map(result: dict[str, Any]) -> dict[str, float | None]:
    rows = result["current"]["rows"]
    return {
        row["dimension_value"]: (
            float(row["metric_value"]) if row["metric_value"] is not None else None
        )
        for row in rows
    }


def _comparison_map(result: dict[str, Any]) -> dict[str, float | None]:
    rows = result["comparison"]["rows"]
    return {
        row["dimension_value"]: (
            float(row["metric_value"]) if row["metric_value"] is not None else None
        )
        for row in rows
    }


def main() -> int:
    stages = compare_stage_performance(
        start_date=CURRENT[0],
        end_date=CURRENT[1],
        compare_start_date=BASELINE[0],
        compare_end_date=BASELINE[1],
    )

    channels = analyze_process(
        metric="order_to_ship_days",
        start_date=CURRENT[0],
        end_date=CURRENT[1],
        group_by="channel",
        compare_start_date=BASELINE[0],
        compare_end_date=BASELINE[1],
    )

    current_channels = _row_map(channels)
    baseline_channels = _comparison_map(channels)

    marketplace_current = current_channels.get("Marketplace")
    marketplace_baseline = baseline_channels.get("Marketplace")
    marketplace_change = (
        marketplace_current - marketplace_baseline
        if marketplace_current is not None and marketplace_baseline is not None
        else None
    )

    other_changes: dict[str, float] = {}
    for channel, current_value in current_channels.items():
        if channel == "Marketplace" or current_value is None:
            continue
        previous_value = baseline_channels.get(channel)
        if previous_value is not None:
            other_changes[channel] = current_value - previous_value

    top_stage = (
        stages["deterioration_rank"][0]
        if stages.get("deterioration_rank")
        else None
    )

    fixed_workflow = investigate_cycle_time(
        start_date=CURRENT[0],
        end_date=CURRENT[1],
        compare_start_date=BASELINE[0],
        compare_end_date=BASELINE[1],
    )

    checks = [
        {
            "name": "Q3 total O2C is worse than Q2",
            "passed": (
                stages["current_period"]["observed_total_o2c_cycle_days"] is not None
                and stages["comparison_period"]["observed_total_o2c_cycle_days"] is not None
                and float(stages["current_period"]["observed_total_o2c_cycle_days"])
                > float(stages["comparison_period"]["observed_total_o2c_cycle_days"])
            ),
        },
        {
            "name": "order_to_ship is the largest stage deterioration",
            "passed": bool(
                top_stage
                and top_stage["stage"] == "order_to_ship_days"
                and top_stage["absolute_change_days"] is not None
                and float(top_stage["absolute_change_days"]) > 0
            ),
        },
        {
            "name": "Marketplace order-to-ship worsens from Q2 to Q3",
            "passed": bool(
                marketplace_change is not None and marketplace_change > 0
            ),
        },
        {
            "name": "Marketplace deterioration exceeds other channels",
            "passed": bool(
                marketplace_change is not None
                and (
                    not other_changes
                    or marketplace_change > max(other_changes.values())
                )
            ),
        },
        {
            "name": "fixed workflow selects order-to-ship as the candidate bottleneck",
            "passed": (
                fixed_workflow.get("candidate_bottleneck")
                == "order_to_ship_days"
            ),
        },
        {
            "name": "fixed workflow produces an illustrative scenario",
            "passed": bool(fixed_workflow.get("illustrative_scenario")),
        },
    ]

    report = {
        "scenario": "scenario_v1_marketplace_bottleneck",
        "baseline_period": {
            "start_date": BASELINE[0],
            "end_date": BASELINE[1],
        },
        "problem_period": {
            "start_date": CURRENT[0],
            "end_date": CURRENT[1],
        },
        "stage_comparison": stages,
        "fixed_workflow": {
            "candidate_bottleneck": fixed_workflow.get("candidate_bottleneck"),
            "illustrative_scenario": fixed_workflow.get("illustrative_scenario"),
        },
        "channel_order_to_ship": {
            "current": current_channels,
            "baseline": baseline_channels,
            "period_change": {
                channel: (
                    value - baseline_channels[channel]
                    if value is not None
                    and baseline_channels.get(channel) is not None
                    else None
                )
                for channel, value in current_channels.items()
            },
        },
        "checks": checks,
        "all_primary_checks_passed": all(check["passed"] for check in checks),
    }

    print(json.dumps(report, indent=2, default=str))
    return 0 if report["all_primary_checks_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
