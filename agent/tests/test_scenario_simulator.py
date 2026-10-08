import pytest

from app.tools import scenario_simulator


def test_reduction_validation():
    with pytest.raises(ValueError):
        scenario_simulator._clamp_pct(-1)

    with pytest.raises(ValueError):
        scenario_simulator._clamp_pct(101)

    assert scenario_simulator._clamp_pct(20) == 20


def test_simulation_math(monkeypatch):
    monkeypatch.setattr(
        scenario_simulator,
        "get_stage_baseline",
        lambda start_date, end_date: {
            "record_count": 100,
            "order_to_ship_days": 4.0,
            "ship_to_invoice_days": 1.0,
            "invoice_to_payment_days": 15.0,
            "ship_to_delivery_days": 3.0,
            "observed_total_o2c_cycle_days": 20.0,
        },
    )

    result = scenario_simulator.simulate_stage_improvement(
        "2024-01-01",
        "2024-03-31",
        invoice_to_payment_reduction_pct=20,
    )

    assert result["baseline"]["modeled_cash_cycle_days"] == 20.0
    assert result["scenario"]["modeled_cash_cycle_days"] == 17.0
    assert result["scenario"]["days_saved"] == 3.0
    assert result["scenario"]["percent_improvement"] == 15.0
