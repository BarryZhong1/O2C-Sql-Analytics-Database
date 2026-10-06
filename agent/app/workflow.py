from __future__ import annotations

from app.tools.process_analytics import (
    analyze_process,
    compare_stage_performance,
)
from app.tools.scenario_simulator import simulate_stage_improvement


def investigate_cycle_time(
    start_date: str,
    end_date: str,
    compare_start_date: str,
    compare_end_date: str,
) -> dict:
    """
    Workflow v1: fixed sequence used as a baseline before agentic orchestration.

    The workflow measures total cycle-time change, ranks the sequential
    cash-cycle stages by period-over-period deterioration, and runs an
    illustrative 20% what-if reduction on the stage that worsened the most.

    It intentionally does not decide which business dimension to drill into.
    That gap is reserved for Agent v1.
    """
    comparison = analyze_process(
        metric="total_o2c_cycle_days",
        start_date=start_date,
        end_date=end_date,
        compare_start_date=compare_start_date,
        compare_end_date=compare_end_date,
    )
    stage_comparison = compare_stage_performance(
        start_date=start_date,
        end_date=end_date,
        compare_start_date=compare_start_date,
        compare_end_date=compare_end_date,
    )

    scenario = None
    candidate_bottleneck = None

    ranked = stage_comparison.get("deterioration_rank", [])
    if ranked:
        top = ranked[0]
        change = top.get("absolute_change_days")
        if change is not None and float(change) > 0:
            candidate_bottleneck = top["stage"]

    if candidate_bottleneck:
        kwargs = {
            "start_date": start_date,
            "end_date": end_date,
            "order_to_ship_reduction_pct": 0,
            "ship_to_invoice_reduction_pct": 0,
            "invoice_to_payment_reduction_pct": 0,
        }
        mapping = {
            "order_to_ship_days": "order_to_ship_reduction_pct",
            "ship_to_invoice_days": "ship_to_invoice_reduction_pct",
            "invoice_to_payment_days": "invoice_to_payment_reduction_pct",
        }
        kwargs[mapping[candidate_bottleneck]] = 20
        scenario = simulate_stage_improvement(**kwargs)

    return {
        "workflow": "fixed_cycle_time_investigation_v1",
        "cycle_time_comparison": comparison,
        "stage_comparison": stage_comparison,
        "candidate_bottleneck": candidate_bottleneck,
        "illustrative_scenario": scenario,
        "note": (
            "Workflow v1 ranks stages by deterioration rather than absolute "
            "duration, but it does not autonomously choose segment/channel "
            "drill-downs or retrieve business context. Agent v1 is evaluated "
            "on those next-step decisions."
        ),
    }
