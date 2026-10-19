from pathlib import Path
import hashlib
import json
from typing import Literal

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy import text
from pydantic import BaseModel, Field

from app.agent import SYSTEM_PROMPT, TOOLS, ask_agent
from app.config import settings
from app.db import engine
from app.state import (
    clear_preferences,
    clear_session,
    get_preferences,
    get_session,
    set_preferences,
    upsert_session,
)
from app.tools.process_analytics import analyze_process, compare_stage_performance
from app.workflow import investigate_cycle_time


UI_PATH = Path(__file__).with_name("static") / "index.html"

app = FastAPI(
    title="O2C Process Improvement & Scenario Planning Agent",
    version="0.5.0",
)


class WorkflowRequest(BaseModel):
    start_date: str = Field(description="YYYY-MM-DD")
    end_date: str = Field(description="YYYY-MM-DD")
    compare_start_date: str = Field(description="YYYY-MM-DD")
    compare_end_date: str = Field(description="YYYY-MM-DD")


class AgentRequest(BaseModel):
    question: str = Field(min_length=10)
    profile_id: str | None = Field(
        default=None,
        max_length=128,
        description=(
            "Optional analyst profile whose bounded reporting preferences should be applied."
        ),
    )


class PreferenceRequest(BaseModel):
    detail_level: Literal["executive", "balanced", "detailed"] | None = None
    preferred_breakdown: Literal["segment", "channel", "none"] | None = None
    include_risks: bool | None = None
    include_scenario_if_relevant: bool | None = None


def _validate_id(value: str, label: str) -> str:
    normalized = value.strip()
    if not normalized:
        raise HTTPException(status_code=400, detail=f"{label} cannot be empty")
    if len(normalized) > 128:
        raise HTTPException(status_code=400, detail=f"{label} must be <= 128 characters")
    return normalized


def _request_preferences(profile_id: str | None) -> dict:
    if profile_id is None:
        return {}
    normalized = _validate_id(profile_id, "profile_id")
    return get_preferences(normalized)


@app.get("/", response_class=HTMLResponse)
def analyst_ui() -> HTMLResponse:
    if not UI_PATH.exists():
        raise HTTPException(status_code=404, detail="analyst UI not found")
    return HTMLResponse(UI_PATH.read_text(encoding="utf-8"))


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "model_backend": settings.model_backend}


@app.get("/demo/design")
def demo_design() -> dict:
    """Expose the bounded agent design used by the running application."""
    rules = []
    for line in SYSTEM_PROMPT.splitlines():
        stripped = line.strip()
        if stripped and stripped[0].isdigit() and ". " in stripped:
            rules.append(stripped.split(". ", 1)[1])

    tool_catalog = [
        {
            "name": tool["name"],
            "description": tool["description"],
            "strict": bool(tool.get("strict")),
            "required_parameters": list(
                (tool.get("parameters") or {}).get("required", [])
            ),
        }
        for tool in TOOLS
    ]

    prompt_hash = hashlib.sha256(SYSTEM_PROMPT.encode("utf-8")).hexdigest()[:12]
    tools_hash = hashlib.sha256(
        json.dumps(TOOLS, sort_keys=True).encode("utf-8")
    ).hexdigest()[:12]

    return {
        "backend": settings.model_backend,
        "role": (
            "AI business process improvement analyst focused on the "
            "Order-to-Cash process"
        ),
        "system_prompt_version": prompt_hash,
        "tool_catalog_version": tools_hash,
        "instruction_rules": rules,
        "tools": tool_catalog,
        "boundaries": {
            "database_access": (
                "Approved parameterized analytics tools only; no free-form "
                "model-generated SQL is executed."
            ),
            "scenario_math": (
                "Numerical what-if calculations are handled by deterministic "
                "Python tools."
            ),
            "causality": (
                "Descriptive patterns and change logs may support hypotheses "
                "but do not establish causality."
            ),
            "execution": (
                "The agent has no operational write tools; implementation "
                "requires human approval."
            ),
        },
        "full_system_prompt": SYSTEM_PROMPT,
    }


@app.get("/demo/status")
def demo_status() -> dict:
    """
    Return presentation-readiness information without exposing hidden eval ground truth.

    This endpoint is intentionally read-only and uses the same analytical layer as
    the demo. It helps a presenter verify that the database and Scenario V1 are
    loaded before starting the investigation.
    """
    try:
        with engine.connect() as conn:
            order_count = int(conn.execute(text("SELECT COUNT(*) FROM orders")).scalar() or 0)
            scenario_row = conn.execute(
                text(
                    """
                    SELECT scenario_id, applied_at, primary_order_count, secondary_invoice_count
                    FROM agent_scenario_registry
                    WHERE scenario_id = 'scenario_v1_marketplace_bottleneck'
                    """
                )
            ).mappings().first()

        stages = compare_stage_performance(
            start_date="2024-07-01",
            end_date="2024-09-30",
            compare_start_date="2024-04-01",
            compare_end_date="2024-06-30",
        )
        channels = analyze_process(
            metric="order_to_ship_days",
            start_date="2024-07-01",
            end_date="2024-09-30",
            group_by="channel",
            compare_start_date="2024-04-01",
            compare_end_date="2024-06-30",
        )

        top_stage = (stages.get("deterioration_rank") or [{}])[0]
        top_channel = (
            (channels.get("group_change_summary") or {}).get("deterioration_rank")
            or [{}]
        )[0]

        return {
            "ready": bool(order_count and scenario_row),
            "model_backend": settings.model_backend,
            "database": {
                "connected": True,
                "order_count": order_count,
            },
            "scenario": {
                "applied": scenario_row is not None,
                "scenario_id": scenario_row["scenario_id"] if scenario_row else None,
                "applied_at": (
                    scenario_row["applied_at"].isoformat()
                    if scenario_row and scenario_row.get("applied_at")
                    else None
                ),
            },
            "benchmark": {
                "q2_total_o2c_days": (stages.get("comparison_period") or {}).get(
                    "observed_total_o2c_cycle_days"
                ),
                "q3_total_o2c_days": (stages.get("current_period") or {}).get(
                    "observed_total_o2c_cycle_days"
                ),
                "largest_stage_deterioration": top_stage.get("stage"),
                "strongest_channel_deterioration": top_channel.get("dimension_value"),
            },
        }
    except Exception as exc:
        return {
            "ready": False,
            "model_backend": settings.model_backend,
            "database": {"connected": False, "order_count": 0},
            "scenario": {"applied": False, "scenario_id": None, "applied_at": None},
            "benchmark": {},
            "error": str(exc),
        }


@app.post("/workflow/investigate")
def workflow_investigate(request: WorkflowRequest) -> dict:
    try:
        return investigate_cycle_time(**request.model_dump())
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/agent/ask")
def agent_ask(request: AgentRequest) -> dict:
    """Run one stateless business-process investigation."""
    try:
        preferences = _request_preferences(request.profile_id)
        return ask_agent(request.question, preferences=preferences)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/agent/session/{session_id}/ask")
def session_agent_ask(session_id: str, request: AgentRequest) -> dict:
    """Continue an investigation using the prior Responses API state for the session."""
    normalized = _validate_id(session_id, "session_id")
    try:
        session = get_session(normalized)
        previous_response_id = (
            session.get("previous_response_id") if session else None
        )
        preferences = _request_preferences(request.profile_id)
        result = ask_agent(
            request.question,
            previous_response_id=previous_response_id,
            preferences=preferences,
        )
        session_state = upsert_session(normalized, result["response_id"])
        return {
            **result,
            "session": session_state,
            "profile_id": request.profile_id,
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/agent/session/{session_id}")
def session_status(session_id: str) -> dict:
    normalized = _validate_id(session_id, "session_id")
    session = get_session(normalized)
    if session is None:
        raise HTTPException(status_code=404, detail="session not found")
    return session


@app.delete("/agent/session/{session_id}")
def session_reset(session_id: str) -> dict:
    normalized = _validate_id(session_id, "session_id")
    deleted = clear_session(normalized)
    return {
        "session_id": normalized,
        "cleared": deleted,
    }


@app.get("/agent/profile/{profile_id}/preferences")
def profile_preferences(profile_id: str) -> dict:
    normalized = _validate_id(profile_id, "profile_id")
    return {
        "profile_id": normalized,
        "preferences": get_preferences(normalized),
    }


@app.put("/agent/profile/{profile_id}/preferences")
def profile_preferences_update(
    profile_id: str,
    request: PreferenceRequest,
) -> dict:
    normalized = _validate_id(profile_id, "profile_id")
    try:
        preferences = set_preferences(
            normalized,
            request.model_dump(exclude_unset=True),
        )
        return {
            "profile_id": normalized,
            "preferences": preferences,
        }
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.delete("/agent/profile/{profile_id}/preferences")
def profile_preferences_reset(profile_id: str) -> dict:
    normalized = _validate_id(profile_id, "profile_id")
    deleted = clear_preferences(normalized)
    return {
        "profile_id": normalized,
        "cleared": deleted,
    }
