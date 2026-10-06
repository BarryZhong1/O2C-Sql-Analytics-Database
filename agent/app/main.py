from typing import Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.agent import ask_agent
from app.state import (
    clear_preferences,
    clear_session,
    get_preferences,
    get_session,
    set_preferences,
    upsert_session,
)
from app.workflow import investigate_cycle_time


app = FastAPI(
    title="O2C Process Improvement & Scenario Planning Agent",
    version="0.3.0",
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


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


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
