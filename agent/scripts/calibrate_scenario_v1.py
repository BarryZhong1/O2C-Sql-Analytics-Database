from __future__ import annotations

import json
import sys
from typing import Any

from sqlalchemy import text

from app.db import engine
from app.tools.process_analytics import analyze_process, compare_stage_performance
from app.workflow import investigate_cycle_time


# Keep these windows fixed so repeated CI runs are directly comparable.
CURRENT = ("2024-07-01", "2024-09-30")
BASELINE = ("2024-04-01", "2024-06-30")

# Acceptance thresholds are intentionally stronger than "directionally positive".
# The controlled scenario should be visible enough for a portfolio demo while still
# requiring an actual drill-down.
MIN_OVERALL_STAGE_DETERIORATION_DAYS = 0.25
MIN_MARKETPLACE_DETERIORATION_DAYS = 2.0
MIN_MARKETPLACE_LEAD_OVER_OTHER_CHANNELS_DAYS = 1.5


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


def _scenario_registry() -> dict[str, Any]:
    with engine.connect() as conn:
        row = conn.execute(
            text(
                """
                SELECT scenario_id, primary_order_count, secondary_invoice_count
                FROM agent_scenario_registry
                WHERE scenario_id = 'scenario_v1_marketplace_bottleneck'
                """
            )
        ).mappings().one()
    return dict(row)


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

    payment_delay = analyze_process(
        metric="payment_delay_vs_due_days",
        start_date=CURRENT[0],
        end_date=CURRENT[1],
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

    order_to_ship_change = next(
        (
            float(row["absolute_change_days"])
            for row in stages.get("stage_changes", [])
            if row["stage"] == "order_to_ship_days"
            and row["absolute_change_days"] is not None
        ),
        None,
    )

    payment_delay_change = (
        float(payment_delay["change"]["absolute"])
        if payment_delay.get("change")
        and payment_delay["change"].get("absolute") is not None
        else None
    )

    fixed_workflow = investigate_cycle_time(
        start_date=CURRENT[0],
        end_date=CURRENT[1],
        compare_start_date=BASELINE[0],
        compare_end_date=BASELINE[1],
    )

    registry = _scenario_registry()

    max_other_change = max(other_changes.values()) if other_changes else None
    marketplace_lead = (
        marketplace_change - max_other_change
        if marketplace_change is not None and max_other_change is not None
        else None
    )

    checks = [
        {
            "name": "scenario registry contains a non-empty primary cohort",
            "passed": int(registry["primary_order_count"]) > 0,
        },
        {
            "name": "scenario registry contains a non-empty secondary cohort",
            "passed": int(registry["secondary_invoice_count"]) > 0,
        },
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
                and float(top_stage["absolute_change_days"])
                >= MIN_OVERALL_STAGE_DETERIORATION_DAYS
            ),
        },
        {
            "name": "Marketplace order-to-ship deterioration is material",
            "passed": bool(
                marketplace_change is not None
                and marketplace_change >= MIN_MARKETPLACE_DETERIORATION_DAYS
            ),
        },
        {
            "name": "Marketplace deterioration clearly exceeds other channels",
            "passed": bool(
                marketplace_change is not None
                and (
                    not other_changes
                    or marketplace_lead is not None
                    and marketplace_lead
                    >= MIN_MARKETPLACE_LEAD_OVER_OTHER_CHANNELS_DAYS
                )
            ),
        },
        {
            "name": "primary fulfillment deterioration exceeds due-date-relative payment deterioration",
            "passed": bool(
                order_to_ship_change is not None
                and payment_delay_change is not None
                and order_to_ship_change > payment_delay_change
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
        "acceptance_thresholds": {
            "min_overall_stage_deterioration_days": MIN_OVERALL_STAGE_DETERIORATION_DAYS,
            "min_marketplace_deterioration_days": MIN_MARKETPLACE_DETERIORATION_DAYS,
            "min_marketplace_lead_over_other_channels_days": (
                MIN_MARKETPLACE_LEAD_OVER_OTHER_CHANNELS_DAYS
            ),
        },
        "scenario_registry": registry,
        "baseline_period": {
            "start_date": BASELINE[0],
            "end_date": BASELINE[1],
        },
        "problem_period": {
            "start_date": CURRENT[0],
            "end_date": CURRENT[1],
        },
        "stage_comparison": stages,
        "collections_context": {
            "metric": "payment_delay_vs_due_days",
            "comparison": payment_delay,
            "period_change_days": payment_delay_change,
        },
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
            "marketplace_change_days": marketplace_change,
            "largest_other_channel_change_days": max_other_change,
            "marketplace_lead_days": marketplace_lead,
        },
        "checks": checks,
        "all_primary_checks_passed": all(check["passed"] for check in checks),
    }

    print(json.dumps(report, indent=2, default=str))
    return 0 if report["all_primary_checks_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
