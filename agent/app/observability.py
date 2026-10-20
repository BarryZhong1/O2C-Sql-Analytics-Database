from __future__ import annotations

from typing import Any


TOKEN_FIELDS = ("input_tokens", "output_tokens", "total_tokens")


def _model_dump(value: Any) -> dict[str, Any]:
    if value is None:
        return {}
    if isinstance(value, dict):
        return value
    model_dump = getattr(value, "model_dump", None)
    if callable(model_dump):
        return model_dump(mode="json", exclude_none=True)
    return {}


def response_usage(response: Any) -> dict[str, Any]:
    """Return the Responses API usage object as a JSON-safe dictionary."""
    return _model_dump(getattr(response, "usage", None))


def response_observation(
    response: Any,
    *,
    phase: str,
    latency_ms: float,
    parent_response_id: str | None,
) -> dict[str, Any]:
    """Capture model-call metadata without storing prompt or answer content."""
    return {
        "response_id": getattr(response, "id", None),
        "parent_response_id": parent_response_id,
        "phase": phase,
        "latency_ms": round(latency_ms, 2),
        "usage": response_usage(response),
    }


def aggregate_usage(observations: list[dict[str, Any]]) -> dict[str, Any]:
    """Aggregate token usage across all Responses API calls in one agent run."""
    totals = {field: 0 for field in TOKEN_FIELDS}
    cached_input_tokens = 0
    reasoning_tokens = 0
    calls_with_usage = 0

    for observation in observations:
        usage = observation.get("usage") or {}
        if not usage:
            continue
        calls_with_usage += 1
        for field in TOKEN_FIELDS:
            value = usage.get(field)
            if isinstance(value, int):
                totals[field] += value

        input_details = usage.get("input_tokens_details") or {}
        cached = input_details.get("cached_tokens")
        if isinstance(cached, int):
            cached_input_tokens += cached

        output_details = usage.get("output_tokens_details") or {}
        reasoning = output_details.get("reasoning_tokens")
        if isinstance(reasoning, int):
            reasoning_tokens += reasoning

    return {
        **totals,
        "cached_input_tokens": cached_input_tokens,
        "reasoning_tokens": reasoning_tokens,
        "model_calls_with_usage": calls_with_usage,
    }
