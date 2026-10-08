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


def test_group_change_summary_calculates_and_ranks_changes():
    current = {
        "rows": [
            {"dimension_value": "Marketplace", "record_count": 30, "metric_value": 5.5},
            {"dimension_value": "Web", "record_count": 40, "metric_value": 1.7},
            {"dimension_value": "InsideSales", "record_count": 30, "metric_value": 1.6},
        ]
    }
    comparison = {
        "rows": [
            {"dimension_value": "Marketplace", "record_count": 25, "metric_value": 1.5},
            {"dimension_value": "Web", "record_count": 45, "metric_value": 1.5},
            {"dimension_value": "InsideSales", "record_count": 30, "metric_value": 1.5},
        ]
    }

    result = process_analytics._group_change_summary(current, comparison)

    ranked = result["deterioration_rank"]
    assert ranked[0]["dimension_value"] == "Marketplace"
    assert ranked[0]["absolute_change"] == 4.0
    assert ranked[0]["percent_change"] == 266.67
    assert ranked[1]["dimension_value"] == "Web"
    assert ranked[1]["absolute_change"] == 0.2


def test_group_change_summary_handles_missing_dimension_without_inventing_change():
    current = {
        "rows": [
            {"dimension_value": "Marketplace", "record_count": 12, "metric_value": 4.0},
        ]
    }
    comparison = {
        "rows": [
            {"dimension_value": "Web", "record_count": 9, "metric_value": 2.0},
        ]
    }

    result = process_analytics._group_change_summary(current, comparison)
    by_dimension = {
        row["dimension_value"]: row
        for row in result["changes"]
    }

    assert by_dimension["Marketplace"]["comparison_value"] is None
    assert by_dimension["Marketplace"]["absolute_change"] is None
    assert by_dimension["Web"]["current_value"] is None
    assert by_dimension["Web"]["absolute_change"] is None
