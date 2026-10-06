from app import workflow


def test_workflow_targets_largest_deterioration(monkeypatch):
    monkeypatch.setattr(
        workflow,
        "analyze_process",
        lambda **kwargs: {
            "current": {"rows": [{"metric_value": 28.0}]},
            "comparison": {"rows": [{"metric_value": 23.0}]},
            "change": {"absolute": 5.0, "percent": 21.74},
        },
    )

    monkeypatch.setattr(
        workflow,
        "compare_stage_performance",
        lambda **kwargs: {
            "deterioration_rank": [
                {
                    "stage": "order_to_ship_days",
                    "current_days": 6.0,
                    "comparison_days": 2.0,
                    "absolute_change_days": 4.0,
                    "percent_change": 200.0,
                },
                {
                    "stage": "invoice_to_payment_days",
                    "current_days": 20.0,
                    "comparison_days": 19.0,
                    "absolute_change_days": 1.0,
                    "percent_change": 5.26,
                },
            ]
        },
    )

    captured = {}

    def fake_simulate(**kwargs):
        captured.update(kwargs)
        return {"scenario": {"modeled_cash_cycle_days": 25.0}}

    monkeypatch.setattr(workflow, "simulate_stage_improvement", fake_simulate)

    result = workflow.investigate_cycle_time(
        start_date="2024-07-01",
        end_date="2024-09-30",
        compare_start_date="2024-04-01",
        compare_end_date="2024-06-30",
    )

    assert result["candidate_bottleneck"] == "order_to_ship_days"
    assert captured["order_to_ship_reduction_pct"] == 20
    assert captured["invoice_to_payment_reduction_pct"] == 0


def test_workflow_skips_scenario_if_no_stage_worsened(monkeypatch):
    monkeypatch.setattr(
        workflow,
        "analyze_process",
        lambda **kwargs: {"change": {"absolute": -1.0, "percent": -5.0}},
    )

    monkeypatch.setattr(
        workflow,
        "compare_stage_performance",
        lambda **kwargs: {
            "deterioration_rank": [
                {
                    "stage": "order_to_ship_days",
                    "absolute_change_days": -0.1,
                }
            ]
        },
    )

    called = {"value": False}

    def fake_simulate(**kwargs):
        called["value"] = True
        return {}

    monkeypatch.setattr(workflow, "simulate_stage_improvement", fake_simulate)

    result = workflow.investigate_cycle_time(
        start_date="2024-07-01",
        end_date="2024-09-30",
        compare_start_date="2024-04-01",
        compare_end_date="2024-06-30",
    )

    assert result["candidate_bottleneck"] is None
    assert result["illustrative_scenario"] is None
    assert called["value"] is False
