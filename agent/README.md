# AI Process Improvement & Scenario Planning Agent

A business-focused AI agent layered on top of the existing Order-to-Cash (O2C) analytics database.

## Product goal

Turn a vague operational question such as:

> "Why did our O2C cycle time get worse, where is the bottleneck, and which improvement would have the biggest impact?"

into an evidence-backed investigation:

1. measure the KPI,
2. identify which process stage actually deteriorated,
3. drill into likely business drivers,
4. retrieve relevant SLA/process-change context,
5. test improvement scenarios with deterministic calculations,
6. return findings, assumptions, risks, and a recommended next action.

The LLM is the **investigator/orchestrator**. SQL and Python tools perform quantitative work.

## Why this project

The existing repository already models the end-to-end O2C process and provides:
- order, customer, shipment, invoice, payment, return, product, and inventory data;
- an operational-performance view with stage-level cycle times;
- customer, product, cash-flow, and order summary views;
- business requirements and KPI definitions.

This agent extends that foundation from **descriptive analytics** to **AI-assisted process diagnosis and scenario planning**.

## MVP scope

### Supported investigation questions
- Why did total O2C cycle time increase?
- Which cash-cycle stage deteriorated the most versus a baseline period?
- Which customer segment or sales channel is driving a delay?
- Are customers actually paying late versus contractual due dates, or do they simply have longer terms?
- Is a known process change temporally consistent with the measured deterioration?
- What happens if order-to-ship, ship-to-invoice, or invoice-to-payment time improves by X%?

### Tools
1. **Process analytics** — whitelisted SQL metrics/dimensions with deterministic period comparisons and rankings.
2. **Scenario simulator** — deterministic Python calculations for process-improvement what-if analysis.
3. **Business-context retrieval** — local retrieval across SLA, guardrail, and process-change Markdown documents.

### Guardrails
- Read-only analytics only.
- No free-form model-generated SQL is executed.
- Metrics and dimensions are whitelisted.
- Scenario outputs are estimates, not causal guarantees.
- Recommendations distinguish observed evidence, assumptions, and hypotheses.
- Process change logs can support a hypothesis but are not causal proof.
- No operational change is applied automatically.

## Architecture

```text
Business user
     |
     v
FastAPI service
     |
     +--> optional persistent session state (SQLite)
     |
     v
AI investigator (Responses API)
     |
     +------------------+-----------------------+
     |                  |                       |
     v                  v                       v
Process analytics   Business context       Scenario simulator
(SQL / MySQL)       (local retrieval)       (deterministic Python)
     |                  |                       |
     +------------------+-----------------------+
                        |
                        v
            Evidence-backed recommendation
                        |
                        v
                 Human decision / approval
```

## Project structure

```text
agent/
├── app/
│   ├── agent.py                 # tool-calling loop + observable trace
│   ├── config.py                # environment settings
│   ├── db.py                    # O2C SQLAlchemy connection
│   ├── main.py                  # FastAPI endpoints
│   ├── state.py                 # persistent short-term session state
│   ├── workflow.py              # fixed Workflow v1 baseline
│   └── tools/
│       ├── process_analytics.py
│       ├── scenario_simulator.py
│       └── policy_retriever.py
├── data/
│   ├── scenario_v1_marketplace_bottleneck.sql
│   └── reset_scenario_v1.sql
├── docs/
│   ├── project_plan.md
│   ├── business_scenario_v1.md
│   ├── data_readiness_review.md
│   └── scenario_v1_benchmark.md
├── evals/
│   ├── README.md
│   ├── eval_cases.json
│   ├── trace_evaluator.py
│   ├── scenario_v1_ground_truth.json
│   └── scenario_v1_benchmark.json
├── policies/
│   ├── o2c_sla_policy.md
│   └── process_change_log.md
├── scripts/
│   ├── calibrate_scenario_v1.py
│   ├── evaluate_agent_run.py
│   └── run_live_evals.py
├── sql/
│   └── validate_scenario_v1.sql
└── tests/
    ├── test_policy_retriever.py
    ├── test_process_analytics.py
    ├── test_scenario_simulator.py
    ├── test_state.py
    ├── test_trace_evaluator.py
    └── test_workflow.py
```

## Quick start

From the repository root, start MySQL and build the deterministic O2C dataset:

```bash
docker compose up -d
docker compose exec -T db mysql -uroot -proot < sql/complete_setup.sql
```

Apply the controlled Scenario V1 overlay:

```bash
docker compose exec -T db mysql -uroot -proot < agent/data/scenario_v1_marketplace_bottleneck.sql
docker compose exec -T db mysql -uroot -proot < agent/sql/validate_scenario_v1.sql
```

Then start the agent service:

```bash
cd agent
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# add OPENAI_API_KEY to .env
uvicorn app.main:app --reload --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

To restore the base synthetic timestamps:

```bash
docker compose exec -T db mysql -uroot -proot < agent/data/reset_scenario_v1.sql
```

## Fixed workflow baseline

```bash
curl -X POST http://localhost:8000/workflow/investigate \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-07-01",
    "end_date": "2024-09-30",
    "compare_start_date": "2024-04-01",
    "compare_end_date": "2024-06-30"
  }'
```

## Stateless agent

```bash
curl -X POST http://localhost:8000/agent/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Investigate why O2C cycle time worsened in Q3 versus Q2. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario."
  }'
```

## Stateful investigation session

The service can persist the latest Responses API response ID for a named session. This provides short-term cross-request continuity without storing raw customer-level conversation data locally.

First turn:

```bash
curl -X POST http://localhost:8000/agent/session/demo-1/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Compare Q3 O2C performance with Q2 and identify the stage that deteriorated most."}'
```

Follow-up:

```bash
curl -X POST http://localhost:8000/agent/session/demo-1/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Now drill into the sales channel driving that deterioration."}'
```

Inspect/reset session state:

```bash
curl http://localhost:8000/agent/session/demo-1
curl -X DELETE http://localhost:8000/agent/session/demo-1
```

## Validated Scenario V1 benchmark

Repeated clean GitHub Actions runs reproduce the controlled benchmark:

- Q2 total O2C: **33.28 days**
- Q3 total O2C: **33.71 days**
- Order-to-ship: **1.48 → 2.09 days** (+0.61; +41.22%)
- Marketplace order-to-ship: **1.45 → 4.62 days** (+3.17)
- Web order-to-ship: 1.54 → 1.54 days
- InsideSales order-to-ship: 1.44 → 1.47 days

The longest absolute stage, invoice-to-payment, actually improves slightly (30.76 → 30.49 days). This deliberately tests whether the system distinguishes **deterioration** from **absolute duration**.

See `evals/scenario_v1_benchmark.json` and `docs/scenario_v1_benchmark.md`.

## Evaluation

Calibrate the controlled data benchmark:

```bash
cd agent
python scripts/calibrate_scenario_v1.py
```

Evaluate one captured agent response against deterministic trace requirements:

```bash
python scripts/evaluate_agent_run.py eval_005 path/to/agent_run.json
```

Run the live behavior set when the database and API key are configured:

```bash
python scripts/run_live_evals.py
```

The evaluation stack separates:
- deterministic numerical checks;
- deterministic tool/argument trace checks;
- later semantic/rubric evaluation for causal wording, evidence synthesis, and decision usefulness.

See `evals/eval_cases.json` and `evals/README.md`.

## Roadmap

- **P1 — Workflow baseline:** implemented and benchmarked.
- **P2 — Agent tools:** implemented; live behavior validation next.
- **P3 — Context/memory:** persistent short-term session state implemented; bounded long-term preferences next.
- **P4 — Quality:** calibration, trace checks, and CI implemented; semantic rubric/LLM judge next.
- **P5 — Deployment:** Dockerized agent API, lightweight analyst UI, and final demo/report.

See `docs/project_plan.md` for the detailed implementation plan.
