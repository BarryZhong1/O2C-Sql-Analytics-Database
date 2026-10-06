from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.agent import ask_agent
from app.state import clear_session, get_session, upsert_session
from app.workflow import investigate_cycle_time


app = FastAPI(
    title="O2C Process Improvement & Scenario Planning Agent",
    version="0.2.0",
)


class WorkflowRequest(BaseModel):
    start_date: str = Field(description="YYYY-MM-DD")
    end_date: str = Field(description="YYYY-MM-DD")
    compare_start_date: str = Field(description="YYYY-MM-DD")
    compare_end_date: str = Field(description="YYYY-MM-DD")


class AgentRequest(BaseModel):
    question: str = Field(min_length=10)


def _validate_session_id(session_id: str) -> str:
    normalized = session_id.strip()
    if not normalized:
        raise HTTPException(status_code=400, detail="session_id cannot be empty")
    if len(normalized) > 128:
        raise HTTPException(status_code=400, detail="session_id must be <= 128 characters")
    return normalized


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
        return ask_agent(request.question)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/agent/session/{session_id}/ask")
def session_agent_ask(session_id: str, request: AgentRequest) -> dict:
    """Continue an investigation using the prior Responses API state for the session."""
    normalized = _validate_session_id(session_id)
    try:
        session = get_session(normalized)
        previous_response_id = (
            session.get("previous_response_id") if session else None
        )
        result = ask_agent(
            request.question,
            previous_response_id=previous_response_id,
        )
        state = upsert_session(normalized, result["response_id"])
        return {
            **result,
            "session": state,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/agent/session/{session_id}")
def session_status(session_id: str) -> dict:
    normalized = _validate_session_id(session_id)
    session = get_session(normalized)
    if session is None:
        raise HTTPException(status_code=404, detail="session not found")
    return session


@app.delete("/agent/session/{session_id}")
def session_reset(session_id: str) -> dict:
    normalized = _validate_session_id(session_id)
    deleted = clear_session(normalized)
    return {
        "session_id": normalized,
        "cleared": deleted,
    }
