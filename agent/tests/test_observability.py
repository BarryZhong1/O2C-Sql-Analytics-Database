from types import SimpleNamespace

from app.observability import aggregate_usage, response_observation, response_usage


class Usage:
    def model_dump(self, mode="json", exclude_none=True):
        assert mode == "json"
        assert exclude_none is True
        return {
            "input_tokens": 100,
            "output_tokens": 25,
            "total_tokens": 125,
            "input_tokens_details": {"cached_tokens": 40},
            "output_tokens_details": {"reasoning_tokens": 5},
        }


def test_response_usage_serializes_sdk_usage_object():
    response = SimpleNamespace(usage=Usage())

    assert response_usage(response)["total_tokens"] == 125


def test_response_observation_avoids_prompt_and_answer_content():
    response = SimpleNamespace(id="resp_123", usage=Usage())

    observation = response_observation(
        response,
        phase="initial",
        latency_ms=123.456,
        parent_response_id=None,
    )

    assert observation["response_id"] == "resp_123"
    assert observation["phase"] == "initial"
    assert observation["latency_ms"] == 123.46
    assert "input" not in observation
    assert "output" not in observation
    assert "answer" not in observation


def test_aggregate_usage_sums_model_calls():
    observations = [
        {
            "usage": {
                "input_tokens": 100,
                "output_tokens": 25,
                "total_tokens": 125,
                "input_tokens_details": {"cached_tokens": 40},
                "output_tokens_details": {"reasoning_tokens": 5},
            }
        },
        {
            "usage": {
                "input_tokens": 50,
                "output_tokens": 10,
                "total_tokens": 60,
                "input_tokens_details": {"cached_tokens": 20},
                "output_tokens_details": {"reasoning_tokens": 2},
            }
        },
        {"usage": {}},
    ]

    result = aggregate_usage(observations)

    assert result == {
        "input_tokens": 150,
        "output_tokens": 35,
        "total_tokens": 185,
        "cached_input_tokens": 60,
        "reasoning_tokens": 7,
        "model_calls_with_usage": 2,
    }
