from __future__ import annotations

import json
from typing import Any

from openai import OpenAI

from app.config import settings
from app.tools.policy_retriever import retrieve_policy
from app.tools.process_analytics import (
    analyze_process,
    compare_stage_performance,
    get_stage_baseline,
)
from app.tools.scenario_simulator import simulate_stage_improvement


SYSTEM_PROMPT = """
You are an AI business process improvement analyst focused on the Order-to-Cash process.

Your job is to investigate business questions with evidence, not to invent explanations.
Use tools whenever the answer depends on database metrics, policies, or scenario math.

Rules:
1. Separate OBSERVED EVIDENCE from HYPOTHESES and ASSUMPTIONS.
2. Never invent KPI values.
3. Do not claim causality from descriptive patterns alone.
4. When a KPI worsens across periods, distinguish the stage that deteriorated
   most from the stage with the longest absolute duration.
5. Use process analytics to measure and drill down before recommending action.
6. When comparing collection performance across customers with different payment
   terms, prefer payment_delay_vs_due_days or late_payment_rate over raw
   invoice_to_payment_days unless the user explicitly asks about cash-cycle length.
7. Use policy retrieval when business rules or SLA expectations matter.
8. Use the deterministic simulator for numerical what-if claims.
9. Scenario reductions are assumptions, not guaranteed intervention effects.
10. Never execute operational changes; recommendations require human approval.
11. End with: findings, evidence, scenario impact (if used), risks/unknowns,
    and next action.
""".strip()


TOOLS = [
    {
        "type": "function",
        "name": "analyze_process",
        "description": (
            "Analyze an approved O2C process KPI over a date range, optionally "
            "grouped by segment or channel and optionally compared with another period. "
            "Use due-date-relative payment metrics when judging collection performance "
            "across different contractual terms."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "metric": {
                    "type": "string",
                    "enum": [
                        "total_o2c_cycle_days",
                        "order_to_ship_days",
                        "ship_to_delivery_days",
                        "ship_to_invoice_days",
                        "invoice_to_payment_days",
                        "payment_delay_vs_due_days",
                        "late_payment_rate",
                        "on_time_delivery_rate",
                        "on_time_ship_rate",
                    ],
                },
                "start_date": {"type": "string", "description": "YYYY-MM-DD"},
                "end_date": {"type": "string", "description": "YYYY-MM-DD"},
                "group_by": {
                    "type": ["string", "null"],
                    "enum": ["segment", "channel", None],
                },
                "compare_start_date": {
                    "type": ["string", "null"],
                    "description": "YYYY-MM-DD",
                },
                "compare_end_date": {
                    "type": ["string", "null"],
                    "description": "YYYY-MM-DD",
                },
            },
            "required": [
                "metric",
                "start_date",
                "end_date",
                "group_by",
                "compare_start_date",
                "compare_end_date",
            ],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "compare_stage_performance",
        "description": (
            "Compare sequential O2C cash-cycle stages across two periods and rank "
            "them by deterioration. Use this when diagnosing which stage changed, "
            "rather than assuming the longest stage is the problem."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "start_date": {"type": "string", "description": "Current/problem period start YYYY-MM-DD"},
                "end_date": {"type": "string", "description": "Current/problem period end YYYY-MM-DD"},
                "compare_start_date": {"type": "string", "description": "Baseline period start YYYY-MM-DD"},
                "compare_end_date": {"type": "string", "description": "Baseline period end YYYY-MM-DD"},
            },
            "required": [
                "start_date",
                "end_date",
                "compare_start_date",
                "compare_end_date",
            ],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_stage_baseline",
        "description": "Get average O2C stage durations for a date range.",
        "parameters": {
            "type": "object",
            "properties": {
                "start_date": {"type": "string", "description": "YYYY-MM-DD"},
                "end_date": {"type": "string", "description": "YYYY-MM-DD"},
            },
            "required": ["start_date", "end_date"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "simulate_stage_improvement",
        "description": (
            "Run a deterministic what-if scenario using current database stage averages. "
            "Percent reductions are assumptions, not causal estimates."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "start_date": {"type": "string", "description": "YYYY-MM-DD"},
                "end_date": {"type": "string", "description": "YYYY-MM-DD"},
                "order_to_ship_reduction_pct": {"type": "number", "minimum": 0, "maximum": 100},
                "ship_to_invoice_reduction_pct": {"type": "number", "minimum": 0, "maximum": 100},
                "invoice_to_payment_reduction_pct": {"type": "number", "minimum": 0, "maximum": 100},
            },
            "required": [
                "start_date",
                "end_date",
                "order_to_ship_reduction_pct",
                "ship_to_invoice_reduction_pct",
                "invoice_to_payment_reduction_pct",
            ],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "retrieve_policy",
        "description": "Retrieve O2C SLA, business-rule, and guardrail context.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "top_k": {"type": "integer", "minimum": 1, "maximum": 5},
            },
            "required": ["query", "top_k"],
            "additionalProperties": False,
        },
        "strict": True,
    },
]


def _dispatch(name: str, args: dict[str, Any]) -> dict[str, Any]:
    if name == "analyze_process":
        return analyze_process(**args)
    if name == "compare_stage_performance":
        return compare_stage_performance(**args)
    if name == "get_stage_baseline":
        return get_stage_baseline(**args)
    if name == "simulate_stage_improvement":
        return simulate_stage_improvement(**args)
    if name == "retrieve_policy":
        return retrieve_policy(**args)
    raise ValueError(f"Unknown tool: {name}")


def ask_agent(question: str, max_turns: int = 8) -> dict[str, Any]:
    if not settings.openai_api_key:
        raise RuntimeError("OPENAI_API_KEY is not configured.")

    client = OpenAI(api_key=settings.openai_api_key)
    response = client.responses.create(
        model=settings.openai_model,
        instructions=SYSTEM_PROMPT,
        tools=TOOLS,
        input=[{"role": "user", "content": question}],
    )

    trace: list[dict[str, Any]] = []

    for _ in range(max_turns):
        calls = [item for item in response.output if item.type == "function_call"]
        if not calls:
            return {
                "response_id": response.id,
                "answer": response.output_text,
                "tool_trace": trace,
            }

        tool_outputs = []
        for call in calls:
            args = json.loads(call.arguments)
            result = _dispatch(call.name, args)
            trace.append({"tool": call.name, "arguments": args, "result": result})
            tool_outputs.append(
                {
                    "type": "function_call_output",
                    "call_id": call.call_id,
                    "output": json.dumps(result, default=str),
                }
            )

        response = client.responses.create(
            model=settings.openai_model,
            instructions=SYSTEM_PROMPT,
            tools=TOOLS,
            previous_response_id=response.id,
            input=tool_outputs,
        )

    raise RuntimeError("Agent exceeded max tool turns.")
