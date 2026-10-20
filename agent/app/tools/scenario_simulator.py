from __future__ import annotations

from typing import Any

from app.tools.process_analytics import get_stage_baseline


CASH_CYCLE_STAGES = (
    "order_to_ship_days",
    "ship_to_invoice_days",
    "invoice_to_payment_days",
)


def _clamp_pct(value: float) -> float:
    if value < 0 or value > 100:
        raise ValueError("Reduction percentages must be between 0 and 100.")
    return value


def simulate_stage_improvement(
    start_date: str,
    end_date: str,
    order_to_ship_reduction_pct: float = 0,
    ship_to_invoice_reduction_pct: float = 0,
    invoice_to_payment_reduction_pct: float = 0,
) -> dict[str, Any]:
    """
    Deterministic what-if simulation.

    This is intentionally transparent: each stage duration is reduced by the
    requested percentage. It estimates directional process impact; it does not
    claim that a particular operational intervention will cause that reduction.
    """
    reductions = {
        "order_to_ship_days": _clamp_pct(order_to_ship_reduction_pct),
        "ship_to_invoice_days": _clamp_pct(ship_to_invoice_reduction_pct),
        "invoice_to_payment_days": _clamp_pct(invoice_to_payment_reduction_pct),
    }

    baseline = get_stage_baseline(start_date, end_date)

    baseline_path = 0.0
    scenario_path = 0.0
    stage_results: dict[str, Any] = {}

    for stage in CASH_CYCLE_STAGES:
        raw = baseline.get(stage)
        if raw is None:
            stage_results[stage] = {
                "baseline_days": None,
                "reduction_pct": reductions[stage],
                "scenario_days": None,
            }
            continue

        base_days = float(raw)
        scenario_days = base_days * (1 - reductions[stage] / 100)
        baseline_path += base_days
        scenario_path += scenario_days
        stage_results[stage] = {
            "baseline_days": round(base_days, 2),
            "reduction_pct": reductions[stage],
            "scenario_days": round(scenario_days, 2),
            "days_saved": round(base_days - scenario_days, 2),
        }

    return {
        "period": {"start_date": start_date, "end_date": end_date},
        "baseline": {
            "modeled_cash_cycle_days": round(baseline_path, 2),
            "observed_total_o2c_cycle_days": baseline.get(
                "observed_total_o2c_cycle_days"
            ),
            "record_count": baseline.get("record_count"),
        },
        "scenario": {
            "modeled_cash_cycle_days": round(scenario_path, 2),
            "days_saved": round(baseline_path - scenario_path, 2),
            "percent_improvement": (
                round((baseline_path - scenario_path) / baseline_path * 100, 2)
                if baseline_path
                else None
            ),
        },
        "stages": stage_results,
        "assumption": (
            "Stage reductions are user/model-specified what-if assumptions. "
            "The simulation does not establish that any proposed intervention "
            "will causally produce those reductions."
        ),
    }
