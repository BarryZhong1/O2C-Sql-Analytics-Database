from __future__ import annotations

from app.tools.process_analytics import analyze_process, get_stage_baseline
from app.tools.scenario_simulator import simulate_stage_improvement


def investigate_cycle_time(
    start_date: str,
    end_date: str,
    compare_start_date: str,
    compare_end_date: str,
) -> dict:
    """
    Workflow v1: fixed sequence used as a baseline before agentic orchestration.

    It measures total cycle-time change, retrieves stage baselines, and runs a
    simple 20% improvement scenario on the currently slowest cash-cycle stage.
    """
    comparison = analyze_process(
        metric="total_o2c_cycle_days",
        start_date=start_date,
        end_date=end_date,
        compare_start_date=compare_start_date,
        compare_end_date=compare_end_date,
    )
    baseline = get_stage_baseline(start_date, end_date)

    stages = {
        "order_to_ship_days": baseline.get("order_to_ship_days"),
        "ship_to_invoice_days": baseline.get("ship_to_invoice_days"),
        "invoice_to_payment_days": baseline.get("invoice_to_payment_days"),
    }
    valid_stages = {k: float(v) for k, v in stages.items() if v is not None}

    scenario = None
    bottleneck = None
    if valid_stages:
        bottleneck = max(valid_stages, key=valid_stages.get)
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
        kwargs[mapping[bottleneck]] = 20
        scenario = simulate_stage_improvement(**kwargs)

    return {
        "workflow": "fixed_cycle_time_investigation_v1",
        "cycle_time_comparison": comparison,
        "stage_baseline": baseline,
        "candidate_bottleneck": bottleneck,
        "illustrative_scenario": scenario,
        "note": (
            "The bottleneck is selected from average stage duration only. "
            "Agent v1 should investigate multiple dimensions before recommending action."
        ),
    }
