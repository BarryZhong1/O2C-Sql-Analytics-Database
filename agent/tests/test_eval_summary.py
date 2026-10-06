from scripts.build_eval_summary import build_summary


def _benchmark():
    return {
        "scenario_id": "scenario_v1_marketplace_bottleneck",
        "status": "validated_reproducible",
        "baseline_period": {
            "label": "Q2 2024",
            "total_o2c_cycle_days": 33.28,
            "order_to_ship_days": 1.48,
            "invoice_to_payment_days": 30.76,
        },
        "problem_period": {
            "label": "Q3 2024",
            "total_o2c_cycle_days": 33.71,
            "order_to_ship_days": 2.09,
            "invoice_to_payment_days": 30.49,
        },
        "channel_order_to_ship_days": {
            "Q2": {"Marketplace": 1.45},
            "Q3": {"Marketplace": 4.62},
        },
    }


def test_build_summary_combines_trace_and_semantic_results():
    live = {
        "cases_requested": 1,
        "cases_completed": 1,
        "trace_checks_passed": 1,
        "trace_pass_rate": 1.0,
        "results": [
            {
                "case_id": "eval_001",
                "status": "completed",
                "deterministic_trace_eval": {
                    "trace_checks_passed": True,
                    "tool_sequence": ["compare_stage_performance"],
                    "checks": [
                        {"name": "trace_shape", "passed": True, "detail": "ok"}
                    ],
                },
            }
        ],
    }
    semantic = {
        "cases_completed": 1,
        "cases_passed": 1,
        "semantic_pass_rate": 1.0,
        "results": [
            {
                "case_id": "eval_001",
                "status": "completed",
                "semantic_eval": {
                    "passed": True,
                    "total_score": 13,
                    "maximum_score": 14,
                    "critical_failures": [],
                },
            }
        ],
    }

    output = build_summary(live, _benchmark(), semantic)

    assert "# Agent Evaluation Summary" in output
    assert "33.28 days" in output
    assert "`eval_001`" in output
    assert "PASS" in output
    assert "13/14" in output
    assert "compare_stage_performance" in output
    assert "No deterministic trace failures" in output
