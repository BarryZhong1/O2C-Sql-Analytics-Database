# System Architecture

## High-level architecture

```mermaid
flowchart TD
    U[Business analyst] --> UI[Analyst web UI]
    U --> API[FastAPI endpoints]
    UI --> API

    API --> WF[Fixed workflow baseline]
    API --> AG[Responses API agent]
    API --> ST[(SQLite state store)]

    AG --> PA[Process analytics tool]
    AG --> PR[Business-context retrieval]
    AG --> SS[Scenario simulator]

    PA --> DB[(MySQL O2C database)]
    PR --> DOCS[SLA + process-change documents]
    SS --> CALC[Deterministic Python calculations]

    AG --> REC[Evidence-backed recommendation]
    REC --> H[Human approval / decision]

    EV[Evaluation layer] --> WF
    EV --> AG
    EV --> PA
    EV --> SS
```

## Responsibility boundaries

| Component | Responsibility | Explicitly does not do |
|---|---|---|
| Analyst UI | Collect business questions, session/profile IDs, and display answers/traces | Reimplement business logic or calculate KPIs |
| FastAPI | Request validation, routing, session/profile endpoints | Decide business conclusions |
| Responses API agent | Decide which approved tool to call next and synthesize findings | Execute arbitrary SQL, write operational records, or claim unsupported causality |
| Process analytics | Deterministic KPI queries and grouped comparisons | Free-form SQL generation |
| Business-context retrieval | Retrieve SLA, guardrail, and process-change context | Treat timing/correlation as causal proof |
| Scenario simulator | Deterministic what-if arithmetic | Estimate causal intervention effects |
| SQLite state | Session response IDs, timestamps, bounded analyst preferences | Store unrestricted raw O2C history or unrestricted memory |
| MySQL O2C DB | Synthetic transactional source and analytical views | Accept agent write actions |
| Evaluation layer | Calibration, trace checks, semantic rubric, reporting | Override deterministic KPI/tool truth with subjective scoring |

## Request flow

### Stateless question

```mermaid
sequenceDiagram
    participant User
    participant API as FastAPI
    participant Agent
    participant Tool as Approved tool
    participant DB as MySQL / Context / Simulator

    User->>API: POST /agent/ask
    API->>Agent: question + optional preferences
    Agent->>Tool: bounded function call
    Tool->>DB: deterministic read/calculation
    DB-->>Tool: result
    Tool-->>Agent: structured evidence
    Agent-->>API: final answer + tool trace
    API-->>User: evidence-backed response
```

### Stateful follow-up

```mermaid
sequenceDiagram
    participant User
    participant API as FastAPI
    participant State as SQLite
    participant Agent

    User->>API: POST /agent/session/{id}/ask
    API->>State: read previous_response_id
    State-->>API: prior response ID
    API->>Agent: question + previous_response_id
    Agent-->>API: answer + new response_id
    API->>State: persist latest response_id
    API-->>User: answer + trace + session metadata
```

## Data and control boundaries

### Deterministic zone

The following are deliberately outside model free-form reasoning:

- SQL KPI calculations;
- period-over-period arithmetic;
- grouped metric comparison;
- stage ranking returned by analytical tools;
- scenario arithmetic;
- trace-rule checks;
- semantic-score aggregation.

### Model reasoning zone

The model is used for:

- interpreting the analyst's business question;
- deciding which approved tool to call next;
- deciding whether another drill-down is needed;
- synthesizing evidence and business context;
- expressing uncertainty and assumptions;
- drafting a bounded recommendation.

### Human approval zone

The agent may analyze, simulate, and recommend, but it does not have tools to:

- change customer payment terms;
- update orders, invoices, shipments, or payments;
- send customer/supplier communications;
- approve spending;
- modify operating policy;
- implement a process change.

## Evaluation architecture

```mermaid
flowchart LR
    S[Scenario V1] --> C[Calibration]
    S --> A[Live agent run]
    A --> T[Tool trace evaluator]
    A --> J[Semantic rubric / optional LLM judge]
    C --> R[Evaluation report]
    T --> R
    J --> R
```

The hidden Scenario V1 ground truth is used only for evaluation design/calibration. It is not provided to the agent or semantic judge as context.

## Why a single agent

A single orchestrating agent is sufficient for the current problem because all tools participate in one bounded O2C investigation loop. Multi-agent orchestration would add coordination cost without a demonstrated business need. It remains an optional extension only if a future version introduces independently owned domains or parallel research tasks that materially benefit from separate agents.
