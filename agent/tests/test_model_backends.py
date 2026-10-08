import json

from app.model_backends import ScriptedMockResponses


def test_mock_routes_stage_comparison():
    mock = ScriptedMockResponses()
    response = mock.create(
        input=[
            {
                "role": "user",
                "content": (
                    "Compare O2C performance in Q3 2024 with Q2 2024. "
                    "Which cash-cycle stage deteriorated the most?"
                ),
            }
        ]
    )

    assert len(response.output) == 1
    call = response.output[0]
    assert call.type == "function_call"
    assert call.name == "compare_stage_performance"
    args = json.loads(call.arguments)
    assert args["start_date"] == "2024-07-01"
    assert args["compare_start_date"] == "2024-04-01"


def test_mock_routes_scenario_with_correct_percentage():
    mock = ScriptedMockResponses()
    response = mock.create(
        input=[
            {
                "role": "user",
                "content": (
                    "If Q3 2024 order-to-ship time were reduced by 25%, "
                    "what happens to the modeled cash cycle?"
                ),
            }
        ]
    )

    call = response.output[0]
    assert call.name == "simulate_stage_improvement"
    args = json.loads(call.arguments)
    assert args["order_to_ship_reduction_pct"] == 25
    assert args["ship_to_invoice_reduction_pct"] == 0
    assert args["invoice_to_payment_reduction_pct"] == 0


def test_mock_causal_case_requires_context_followup():
    mock = ScriptedMockResponses()
    first = mock.create(
        input=[
            {
                "role": "user",
                "content": (
                    "Marketplace has the worst Q3 2024 order-to-ship time. "
                    "Prove the new promotional review caused the slowdown."
                ),
            }
        ]
    )
    assert first.output[0].name == "analyze_process"

    second = mock.create(
        previous_response_id=first.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": first.output[0].call_id,
                "output": "{}",
            }
        ],
    )
    assert second.output[0].name == "retrieve_policy"

    third = mock.create(
        previous_response_id=second.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": second.output[0].call_id,
                "output": "{}",
            }
        ],
    )
    assert third.output == []
    assert "[MOCK BACKEND]" in third.output_text


def test_mock_refuses_automatic_operational_change():
    mock = ScriptedMockResponses()
    response = mock.create(
        input=[
            {
                "role": "user",
                "content": (
                    "If you find the bottleneck, automatically change the process "
                    "and customer terms to fix it."
                ),
            }
        ]
    )

    assert response.output == []
    assert "human approval" in response.output_text.lower()


def test_mock_showcase_runs_four_step_demo_plan():
    mock = ScriptedMockResponses()
    question = (
        "Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. "
        "Identify the stage that deteriorated most, drill into the strongest driver, "
        "and test a realistic improvement scenario."
    )

    first = mock.create(input=[{"role": "user", "content": question}])
    assert first.output[0].name == "compare_stage_performance"

    second = mock.create(
        previous_response_id=first.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": first.output[0].call_id,
                "output": json.dumps(
                    {
                        "current_period": {"observed_total_o2c_cycle_days": 33.71},
                        "comparison_period": {"observed_total_o2c_cycle_days": 33.28},
                        "deterioration_rank": [
                            {
                                "stage": "order_to_ship_days",
                                "comparison_days": 1.48,
                                "current_days": 2.09,
                                "absolute_change_days": 0.61,
                            }
                        ],
                    }
                ),
            }
        ],
    )
    assert second.output[0].name == "analyze_process"

    third = mock.create(
        previous_response_id=second.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": second.output[0].call_id,
                "output": json.dumps(
                    {
                        "group_change_summary": {
                            "deterioration_rank": [
                                {
                                    "dimension_value": "Marketplace",
                                    "comparison_value": 1.45,
                                    "current_value": 4.62,
                                    "absolute_change": 3.17,
                                }
                            ]
                        }
                    }
                ),
            }
        ],
    )
    assert third.output[0].name == "retrieve_policy"

    fourth = mock.create(
        previous_response_id=third.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": third.output[0].call_id,
                "output": json.dumps(
                    {
                        "matches": [
                            {
                                "paragraph": (
                                    "A manual promotional-code review step was introduced "
                                    "for Marketplace orders beginning July 1, 2024."
                                )
                            }
                        ]
                    }
                ),
            }
        ],
    )
    assert fourth.output[0].name == "simulate_stage_improvement"

    final = mock.create(
        previous_response_id=fourth.id,
        input=[
            {
                "type": "function_call_output",
                "call_id": fourth.output[0].call_id,
                "output": json.dumps(
                    {
                        "baseline": {"modeled_cash_cycle_days": 33.3},
                        "scenario": {
                            "modeled_cash_cycle_days": 32.78,
                            "days_saved": 0.52,
                            "percent_improvement": 1.56,
                        },
                    }
                ),
            }
        ],
    )

    assert final.output == []
    assert "FINDING" in final.output_text
    assert "Marketplace" in final.output_text
    assert "0.52" in final.output_text
    assert "scripted" in final.output_text.lower()
