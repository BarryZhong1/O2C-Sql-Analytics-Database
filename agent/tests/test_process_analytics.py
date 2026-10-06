from app.tools import process_analytics


def test_compare_stage_performance_ranks_deterioration_not_duration(monkeypatch):
    baselines = iter(
        [
            {
                "record_count": 100,
                "order_to_ship_days": 6.0,
                "ship_to_invoice_days": 1.0,
                "invoice_to_payment_days": 20.0,
                "ship_to_delivery_days": 3.0,
                "payment_delay_vs_due_days": 2.0,
                "observed_total_o2c_cycle_days": 27.0,
            },
            {
                "record_count": 100,
                "order_to_ship_days": 2.0,
                "ship_to_invoice_days": 1.0,
                "invoice_to_payment_days": 19.0,
                "ship_to_delivery_days": 3.0,
                "payment_delay_vs_due_days": 1.0,
                "observed_total_o2c_cycle_days": 22.0,
            },
        ]
    )

    monkeypatch.setattr(
        process_analytics,
        "get_stage_baseline",
        lambda start_date, end_date: next(baselines),
    )

    result = process_analytics.compare_stage_performance(
        "2024-07-01",
        "2024-09-30",
        "2024-04-01",
        "2024-06-30",
    )

    assert result["deterioration_rank"][0]["stage"] == "order_to_ship_days"
    assert result["deterioration_rank"][0]["absolute_change_days"] == 4.0
    assert result["deterioration_rank"][1]["stage"] == "invoice_to_payment_days"
    assert result["deterioration_rank"][1]["absolute_change_days"] == 1.0
