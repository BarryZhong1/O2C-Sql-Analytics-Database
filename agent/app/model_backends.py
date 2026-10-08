from __future__ import annotations

import json
import re
import uuid
from dataclasses import dataclass
from typing import Any

from openai import OpenAI

from app.config import settings


SUPPORTED_BACKENDS = {"mock", "openai"}


@dataclass
class MockFunctionCall:
    name: str
    arguments: str
    call_id: str
    type: str = "function_call"


@dataclass
class MockResponse:
    id: str
    output: list[Any]
    output_text: str
    usage: dict[str, Any]


class ScriptedMockResponses:
    """
    Deterministic Responses-API-shaped mock used for free integration testing.

    It does not attempt to imitate model intelligence. It selects a small set of
    tool calls for the documented evaluation prompts so the real orchestration,
    SQL tools, scenario simulator, traces, state handling, and evaluators can run
    without paid API usage.
    """

    def __init__(self) -> None:
        self._state: dict[str, dict[str, Any]] = {}

    def _new_id(self) -> str:
        return f"mock_resp_{uuid.uuid4().hex}"

    def _call(self, name: str, arguments: dict[str, Any]) -> MockFunctionCall:
        return MockFunctionCall(
            name=name,
            arguments=json.dumps(arguments),
            call_id=f"mock_call_{uuid.uuid4().hex}",
        )

    @staticmethod
    def _is_tool_followup(items: Any) -> bool:
        return bool(
            isinstance(items, list)
            and items
            and isinstance(items[0], dict)
            and items[0].get("type") == "function_call_output"
        )

    @staticmethod
    def _question_from_input(items: Any) -> str:
        if not isinstance(items, list):
            return ""
        for item in items:
            if isinstance(item, dict) and item.get("role") == "user":
                return str(item.get("content", ""))
        return ""

    def _initial_plan(self, question: str) -> tuple[list[MockFunctionCall], str | None]:
        q = question.lower()
        q2 = {
            "start_date": "2024-07-01",
            "end_date": "2024-09-30",
            "compare_start_date": "2024-04-01",
            "compare_end_date": "2024-06-30",
        }

        if "automatically change the process" in q or "change the process and customer terms" in q:
            return [], (
                "[MOCK BACKEND] I can analyze and simulate options, but I cannot execute "
                "operational or payment-term changes. Implementation requires human approval."
            )

        if "promotional review" in q and "marketplace" in q:
            return [
                self._call(
                    "analyze_process",
                    {
                        "metric": "order_to_ship_days",
                        "start_date": "2024-07-01",
                        "end_date": "2024-09-30",
                        "group_by": "channel",
                        "compare_start_date": None,
                        "compare_end_date": None,
                    },
                )
            ], None

        if "paying late beyond" in q or "contractual terms" in q:
            return [
                self._call(
                    "analyze_process",
                    {
                        "metric": "payment_delay_vs_due_days",
                        "start_date": "2024-07-01",
                        "end_date": "2024-09-30",
                        "group_by": "segment",
                        "compare_start_date": None,
                        "compare_end_date": None,
                    },
                )
            ], None

        if "reduced by 25%" in q and "order-to-ship" in q:
            return [
                self._call(
                    "simulate_stage_improvement",
                    {
                        "start_date": "2024-07-01",
                        "end_date": "2024-09-30",
                        "order_to_ship_reduction_pct": 25,
                        "ship_to_invoice_reduction_pct": 0,
                        "invoice_to_payment_reduction_pct": 0,
                    },
                )
            ], None

        if "sales channel" in q or "disproportionately affected" in q:
            return [
                self._call(
                    "analyze_process",
                    {
                        "metric": "order_to_ship_days",
                        **q2,
                        "group_by": "channel",
                    },
                )
            ], None

        if (
            "cash-cycle stage deteriorated" in q
            or "longest stage" in q
            or ("q3 2024" in q and "q2 2024" in q and "slowdown" in q)
        ):
            return [
                self._call(
                    "compare_stage_performance",
                    q2,
                )
            ], None

        percent_match = re.search(r"(\d+(?:\.\d+)?)\s*%", q)
        if "what if" in q and "order-to-ship" in q and percent_match:
            pct = float(percent_match.group(1))
            return [
                self._call(
                    "simulate_stage_improvement",
                    {
                        "start_date": "2024-07-01",
                        "end_date": "2024-09-30",
                        "order_to_ship_reduction_pct": pct,
                        "ship_to_invoice_reduction_pct": 0,
                        "invoice_to_payment_reduction_pct": 0,
                    },
                )
            ], None

        return [], (
            "[MOCK BACKEND] No scripted tool plan matched this question. "
            "Use MODEL_BACKEND=openai with an API key to test open-ended model behavior."
        )

    def create(self, **kwargs: Any) -> MockResponse:
        items = kwargs.get("input")
        previous_id = kwargs.get("previous_response_id")

        if self._is_tool_followup(items):
            state = self._state.get(previous_id or "", {})
            question = state.get("question", "")
            tools_run = list(state.get("tools_run", []))
            phase = int(state.get("phase", 0)) + 1

            if "promotional review" in question.lower() and "retrieve_policy" not in tools_run:
                call = self._call(
                    "retrieve_policy",
                    {
                        "query": "Marketplace promotional review process change Q3 2024",
                        "top_k": 3,
                    },
                )
                response_id = self._new_id()
                self._state[response_id] = {
                    "question": question,
                    "phase": phase,
                    "tools_run": tools_run + ["retrieve_policy"],
                }
                return MockResponse(
                    id=response_id,
                    output=[call],
                    output_text="",
                    usage={"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
                )

            response_id = self._new_id()
            answer = (
                "[MOCK BACKEND] Scripted orchestration completed using real project tools. "
                f"Tool path: {' -> '.join(tools_run) if tools_run else 'none'}. "
                "This validates wiring, arguments, deterministic calculations, and trace "
                "evaluation; it is not evidence of real LLM reasoning or answer quality."
            )
            self._state[response_id] = {
                "question": question,
                "phase": phase,
                "tools_run": tools_run,
            }
            return MockResponse(
                id=response_id,
                output=[],
                output_text=answer,
                usage={"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
            )

        question = self._question_from_input(items)
        calls, direct_answer = self._initial_plan(question)
        response_id = self._new_id()
        tools_run = [call.name for call in calls]
        self._state[response_id] = {
            "question": question,
            "phase": 0,
            "tools_run": tools_run,
        }
        return MockResponse(
            id=response_id,
            output=calls,
            output_text=direct_answer or "",
            usage={"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
        )


class ScriptedMockClient:
    def __init__(self) -> None:
        self.responses = ScriptedMockResponses()


_MOCK_CLIENT = ScriptedMockClient()


def resolve_backend(backend: str | None = None) -> str:
    selected = (backend or settings.model_backend).strip().lower()
    if selected not in SUPPORTED_BACKENDS:
        raise ValueError(
            f"Unsupported MODEL_BACKEND={selected!r}. "
            f"Expected one of: {sorted(SUPPORTED_BACKENDS)}"
        )
    return selected


def backend_model_name(backend: str) -> str:
    return settings.openai_model if backend == "openai" else "scripted-mock-v1"


def create_model_client(backend: str | None = None) -> tuple[str, Any]:
    selected = resolve_backend(backend)
    if selected == "mock":
        return selected, _MOCK_CLIENT

    if not settings.openai_api_key:
        raise RuntimeError(
            "OPENAI_API_KEY is not configured. Use MODEL_BACKEND=mock for free "
            "scripted integration testing, or configure a key for MODEL_BACKEND=openai."
        )
    return selected, OpenAI(api_key=settings.openai_api_key)
