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
