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
    Deterministic Responses-API-shaped mock used for free integration testing
    and the portfolio demo.

    The mock does not imitate general LLM intelligence. It scripts investigation
    plans for documented O2C questions while still exercising the real agent
    loop, MySQL analytics, policy retrieval, scenario simulator, traces, state,
    and deterministic evaluators.
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

    @staticmethod
    def _is_showcase_question(question: str) -> bool:
        q = question.lower()
        return (
            "q3 2024" in q
            and "q2 2024" in q
            and (
                "investigate why o2c cycle time worsened" in q
                or (
                    "stage that deteriorated most" in q
                    and ("driver" in q or "drill" in q)
                    and "scenario" in q
                )
            )
        )

    @staticmethod
    def _tool_results(items: list[dict[str, Any]], state: dict[str, Any]) -> dict[str, Any]:
        results = dict(state.get("results", {}))
        pending = dict(state.get("pending_calls", {}))
        for item in items:
            call_id = item.get("call_id")
            tool_name = pending.get(call_id)
            if not tool_name:
                continue
            raw = item.get("output", "{}")
            try:
                parsed = json.loads(raw)
            except (TypeError, json.JSONDecodeError):
                parsed = {"raw_output": str(raw)}
            results[tool_name] = parsed
        return results

    @staticmethod
    def _fmt(value: Any, digits: int = 2) -> str:
        if value is None:
            return "N/A"
        try:
            return f"{float(value):.{digits}f}"
        except (TypeError, ValueError):
            return str(value)

    def _showcase_answer(self, results: dict[str, Any]) -> str:
        stages = results.get("compare_stage_performance", {})
        channel = results.get("analyze_process", {})
        policy = results.get("retrieve_policy", {})
        scenario = results.get("simulate_stage_improvement", {})

        current_total = (stages.get("current_period") or {}).get(
            "observed_total_o2c_cycle_days"
        )
        comparison_total = (stages.get("comparison_period") or {}).get(
            "observed_total_o2c_cycle_days"
        )
        ranked_stages = stages.get("deterioration_rank") or []
        top_stage = ranked_stages[0] if ranked_stages else {}

        group_rank = (
            (channel.get("group_change_summary") or {}).get("deterioration_rank")
            or []
        )
        top_channel = group_rank[0] if group_rank else {}

        matches = policy.get("matches") or []
        context = matches[0] if matches else {}

        scenario_result = scenario.get("scenario") or {}
        baseline = scenario.get("baseline") or {}

        context_text = context.get("paragraph", "No matching process context was retrieved.")
        # Keep the demo readable even if the retrieved paragraph contains a heading.
        context_text = " ".join(str(context_text).split())
        if len(context_text) > 280:
            context_text = context_text[:277] + "..."

        return f"""[MOCK DEMO — scripted orchestration; SQL, retrieval, and scenario outputs are real project results]

FINDING
Q3 average O2C cycle time is {self._fmt(current_total)} days versus {self._fmt(comparison_total)} days in Q2. The stage with the largest deterioration is {top_stage.get("stage", "N/A")}: {self._fmt(top_stage.get("comparison_days"))} → {self._fmt(top_stage.get("current_days"))} days ({self._fmt(top_stage.get("absolute_change_days"))} days).

STRONGEST DRIVER
The largest channel-level deterioration is {top_channel.get("dimension_value", "N/A")}: {self._fmt(top_channel.get("comparison_value"))} → {self._fmt(top_channel.get("current_value"))} days, a change of {self._fmt(top_channel.get("absolute_change"))} days.

BUSINESS CONTEXT
Retrieved context: {context_text}

This timing is consistent with the observed Marketplace slowdown, but it is contextual evidence rather than proof that the process change caused the deterioration.

WHAT-IF SCENARIO
A 25% reduction in Q3 order-to-ship time changes the modeled cash cycle from {self._fmt(baseline.get("modeled_cash_cycle_days"))} to {self._fmt(scenario_result.get("modeled_cash_cycle_days"))} days, saving about {self._fmt(scenario_result.get("days_saved"))} days ({self._fmt(scenario_result.get("percent_improvement"))}% modeled improvement).

RISKS / UNKNOWNS
The scenario assumes the stage-time reduction can actually be achieved. Descriptive timing and a change log do not establish causality; stronger evidence would include affected-vs-unaffected order comparisons, review-queue timestamps, exception/rework data, or a controlled pilot.

NEXT ACTION
Pilot a targeted Marketplace order-release improvement, track order-to-ship time and exception rate, and compare the pilot cohort with an appropriate baseline before changing policy broadly. Human approval is required for implementation.

DEMO NOTE
This free mock mode proves the application flow and uses real database/tool results, but the investigation path above is scripted. Switch MODEL_BACKEND=openai later to test unscripted model reasoning with the same tools and evaluation cases."""

    def _simple_answer(
        self,
        question: str,
        tools_run: list[str],
        results: dict[str, Any],
    ) -> str:
        q = question.lower()

        if "cash-cycle stage deteriorated" in q or "longest stage" in q:
            result = results.get("compare_stage_performance", {})
            ranked = result.get("deterioration_rank") or []
            top = ranked[0] if ranked else {}
            return (
                "[MOCK BACKEND] Period comparison completed with the real analytics tool. "
                f"The largest deterioration is {top.get('stage', 'N/A')}: "
                f"{self._fmt(top.get('comparison_days'))} → "
                f"{self._fmt(top.get('current_days'))} days "
                f"({self._fmt(top.get('absolute_change_days'))} days). "
                "The longest absolute stage should not be assumed to be the stage that worsened most."
            )

        if "sales channel" in q or "disproportionately affected" in q:
            result = results.get("analyze_process", {})
            ranked = (
                (result.get("group_change_summary") or {}).get("deterioration_rank")
                or []
            )
            top = ranked[0] if ranked else {}
            return (
                "[MOCK BACKEND] Channel comparison completed with real SQL results. "
                f"The strongest deterioration is {top.get('dimension_value', 'N/A')}: "
                f"{self._fmt(top.get('comparison_value'))} → "
                f"{self._fmt(top.get('current_value'))} days "
                f"({self._fmt(top.get('absolute_change'))} days). "
                "This is descriptive evidence, not causal proof."
            )

        if "paying late beyond" in q or "contractual terms" in q:
            result = results.get("analyze_process", {})
            rows = (result.get("current") or {}).get("rows") or []
            if rows:
                worst = max(
                    rows,
                    key=lambda row: (
                        row.get("metric_value") is not None,
                        float(row.get("metric_value") or float("-inf")),
                    ),
                )
                segment = worst.get("dimension_value", "N/A")
                value = self._fmt(worst.get("metric_value"))
            else:
                segment, value = "N/A", "N/A"
            return (
                "[MOCK BACKEND] Payment performance was normalized against contractual due "
                f"dates. The highest average payment delay in Q3 is {segment} at {value} days "
                "relative to due date. Raw invoice-to-payment duration is not used as the "
                "collection-performance judgment because payment terms differ."
            )

        if "order-to-ship" in q and ("25%" in q or "what if" in q):
            result = results.get("simulate_stage_improvement", {})
            scenario = result.get("scenario") or {}
            baseline = result.get("baseline") or {}
            return (
                "[MOCK BACKEND] Deterministic scenario completed. Modeled cash cycle: "
                f"{self._fmt(baseline.get('modeled_cash_cycle_days'))} → "
                f"{self._fmt(scenario.get('modeled_cash_cycle_days'))} days; "
                f"{self._fmt(scenario.get('days_saved'))} days saved. "
                "The 25% stage reduction is a what-if assumption, not a guaranteed effect."
            )

        if "promotional review" in q and "marketplace" in q:
            analytics = results.get("analyze_process", {})
            rows = (analytics.get("current") or {}).get("rows") or []
            marketplace = next(
                (row for row in rows if row.get("dimension_value") == "Marketplace"),
                {},
            )
            policy = results.get("retrieve_policy", {})
            matches = policy.get("matches") or []
            context = " ".join(str((matches[0] if matches else {}).get("paragraph", "")).split())
            return (
                "[MOCK BACKEND] Marketplace Q3 order-to-ship averages "
                f"{self._fmt(marketplace.get('metric_value'))} days. Retrieved process context "
                f"records the promotional-review change: {context[:220]}. "
                "The temporal alignment supports a hypothesis but does not prove causality. "
                "Additional cohort/queue-level evidence or a controlled pilot would strengthen it."
            )

        return (
            "[MOCK BACKEND] Scripted orchestration completed using real project tools. "
            f"Tool path: {' -> '.join(tools_run) if tools_run else 'none'}. "
            "This validates wiring, arguments, deterministic calculations, and trace "
            "evaluation; it is not evidence of real LLM reasoning quality."
        )

    def _initial_plan(self, question: str) -> tuple[list[MockFunctionCall], str | None]:
        q = question.lower()
        period_args = {
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

        if self._is_showcase_question(question):
            return [self._call("compare_stage_performance", period_args)], None

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
                        **period_args,
                        "group_by": "channel",
                    },
                )
            ], None

        if (
            "cash-cycle stage deteriorated" in q
            or "longest stage" in q
            or ("q3 2024" in q and "q2 2024" in q and "slowdown" in q)
        ):
            return [self._call("compare_stage_performance", period_args)], None

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

        if "what evidence" in q and "caus" in q:
            return [], (
                "[MOCK BACKEND] To strengthen a causal claim, compare affected and unaffected "
                "orders over the same period, inspect review-queue timestamps and exceptions, "
                "control for channel mix and other concurrent changes, and ideally run a bounded "
                "pilot or quasi-experimental comparison. Timing alone is not proof."
            )

        return [], (
            "[MOCK BACKEND] No scripted tool plan matched this question. "
            "Use one of the demo presets, or switch MODEL_BACKEND=openai with an API key "
            "to test open-ended model behavior."
        )

    def _next_showcase_call(
        self,
        tools_run: list[str],
    ) -> MockFunctionCall | None:
        if "compare_stage_performance" not in tools_run:
            return None
        if "analyze_process" not in tools_run:
            return self._call(
                "analyze_process",
                {
                    "metric": "order_to_ship_days",
                    "start_date": "2024-07-01",
                    "end_date": "2024-09-30",
                    "group_by": "channel",
                    "compare_start_date": "2024-04-01",
                    "compare_end_date": "2024-06-30",
                },
            )
        if "retrieve_policy" not in tools_run:
            return self._call(
                "retrieve_policy",
                {
                    "query": "Marketplace promotional review process change Q3 2024",
                    "top_k": 3,
                },
            )
        if "simulate_stage_improvement" not in tools_run:
            return self._call(
                "simulate_stage_improvement",
                {
                    "start_date": "2024-07-01",
                    "end_date": "2024-09-30",
                    "order_to_ship_reduction_pct": 25,
                    "ship_to_invoice_reduction_pct": 0,
                    "invoice_to_payment_reduction_pct": 0,
                },
            )
        return None

    def create(self, **kwargs: Any) -> MockResponse:
        items = kwargs.get("input")
        previous_id = kwargs.get("previous_response_id")

        if self._is_tool_followup(items):
            state = self._state.get(previous_id or "", {})
            question = state.get("question", "")
            tools_run = list(state.get("tools_run", []))
            results = self._tool_results(items, state)
            phase = int(state.get("phase", 0)) + 1

            if self._is_showcase_question(question):
                next_call = self._next_showcase_call(tools_run)
                if next_call is not None:
                    response_id = self._new_id()
                    self._state[response_id] = {
                        "question": question,
                        "phase": phase,
                        "tools_run": tools_run + [next_call.name],
                        "pending_calls": {next_call.call_id: next_call.name},
                        "results": results,
                    }
                    return MockResponse(
                        id=response_id,
                        output=[next_call],
                        output_text="",
                        usage={"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
                    )
                answer = self._showcase_answer(results)
            elif "promotional review" in question.lower() and "retrieve_policy" not in tools_run:
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
                    "pending_calls": {call.call_id: call.name},
                    "results": results,
                }
                return MockResponse(
                    id=response_id,
                    output=[call],
                    output_text="",
                    usage={"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
                )
            else:
                answer = self._simple_answer(question, tools_run, results)

            response_id = self._new_id()
            self._state[response_id] = {
                "question": question,
                "phase": phase,
                "tools_run": tools_run,
                "pending_calls": {},
                "results": results,
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
            "pending_calls": {call.call_id: call.name for call in calls},
            "results": {},
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
