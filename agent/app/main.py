from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.agent import ask_agent
from app.workflow import investigate_cycle_time


app = FastAPI(
    title="O2C Process Improvement & Scenario Planning Agent",
    version="0.1.0",
)


class WorkflowRequest(BaseModel):
    start_date: str = Field(description="YYYY-MM-DD")
    end_date: str = Field(description="YYYY-MM-DD")
    compare_start_date: str = Field(description="YYYY-MM-DD")
    compare_end_date: str = Field(description="YYYY-MM-DD")


class AgentRequest(BaseModel):
    question: str = Field(min_length=10)


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
    try:
        return ask_agent(request.question)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
