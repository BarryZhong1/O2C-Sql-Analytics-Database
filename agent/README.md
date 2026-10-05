# AI Process Improvement & Scenario Planning Agent

A business-focused AI agent layered on top of the existing Order-to-Cash (O2C) analytics database.

## Product goal

Turn a vague operational question such as:

> "Why did our O2C cycle time get worse, where is the bottleneck, and which improvement would have the biggest impact?"

into an evidence-backed investigation:

1. measure the KPI,
2. drill into likely drivers,
3. retrieve business rules and SLA context,
4. test improvement scenarios with deterministic calculations,
5. return findings, assumptions, risks, and a recommended next action.

The LLM is the **investigator/orchestrator**. SQL and Python tools perform the quantitative work.

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
- Which customer segment or sales channel is driving a delay?
- Which O2C stage is the current bottleneck?
- What happens if order-to-ship, ship-to-invoice, or invoice-to-payment time improves by X%?

### Tools
1. **Process analytics** — queries approved O2C analytical views using whitelisted metrics and dimensions.
2. **Scenario simulator** — deterministic Python calculations for process-improvement what-if analysis.
3. **Policy retriever** — retrieves relevant O2C SLA/business-rule context from local policy documents.

### Guardrails
- Read-only analytics only.
- No free-form model-generated SQL is executed.
- Metrics and dimensions are whitelisted.
- Scenario outputs are estimates, not causal guarantees.
- Recommendations must distinguish observed evidence, assumptions, and hypotheses.
- No operational change is applied automatically.

## Architecture

```text
Business user
     |
     v
FastAPI service
     |
     v
AI investigator (OpenAI Responses API)
     |
     +------------------+-------------------+
     |                  |                   |
     v                  v                   v
Process analytics   Policy retrieval   Scenario simulator
(SQL / MySQL)       (local knowledge)   (deterministic Python)
     |                  |                   |
     +------------------+-------------------+
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
│   ├── agent.py                 # Responses API tool-calling loop
│   ├── config.py                # environment settings
│   ├── db.py                    # SQLAlchemy connection
│   ├── main.py                  # FastAPI endpoints
│   ├── workflow.py              # fixed Workflow v1 baseline
│   └── tools/
│       ├── process_analytics.py
│       ├── scenario_simulator.py
│       └── policy_retriever.py
├── docs/
│   └── project_plan.md
├── evals/
│   └── eval_cases.json
├── policies/
│   └── o2c_sla_policy.md
├── tests/
│   └── test_scenario_simulator.py
├── .env.example
└── requirements.txt
```

## Quick start

From the repository root, start MySQL and load the existing O2C database:

```bash
docker compose up -d
docker compose exec -T db mysql -uroot -proot < sql/complete_setup.sql
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

### Apply the controlled demo scenario

Scenario V1 injects a reproducible Q3 Marketplace fulfillment bottleneck plus a smaller Enterprise payment-delay confounder.

From the repository root:

```bash
docker compose exec -T db mysql -uroot -proot < agent/data/scenario_v1_marketplace_bottleneck.sql
docker compose exec -T db mysql -uroot -proot < agent/sql/validate_scenario_v1.sql
```

To restore the base synthetic data timestamps:

```bash
docker compose exec -T db mysql -uroot -proot < agent/data/reset_scenario_v1.sql
```

See `docs/business_scenario_v1.md` for the business story and `docs/data_readiness_review.md` for why a controlled overlay is used.

Fixed workflow baseline:

```bash
curl -X POST http://localhost:8000/workflow/investigate \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-04-01",
    "end_date": "2024-06-30",
    "compare_start_date": "2024-01-01",
    "compare_end_date": "2024-03-31"
  }'
```

Agent:

```bash
curl -X POST http://localhost:8000/agent/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Investigate why O2C cycle time worsened in Q2 versus Q1. Drill down into the strongest driver and test a realistic improvement scenario."
  }'
```

## Evaluation direction

The initial eval set focuses on:
- correct tool selection;
- grounded use of database evidence;
- numerical consistency with deterministic tools;
- correct separation of observation vs. hypothesis;
- policy/SLA grounding;
- safe behavior when the user asks the agent to make an operational change.

See `evals/eval_cases.json`.

## Roadmap

- **P1 — Workflow baseline:** fixed process-analysis workflow + API.
- **P2 — Agent tools:** dynamic tool selection and multi-step investigation.
- **P3 — Context/memory:** remember user KPI preferences and prior investigations.
- **P4 — Quality:** tracing, failure analysis, automated evaluation set.
- **P5 — Deployment:** Dockerized API, UI/demo, optional multi-agent extension only if justified.

See `docs/project_plan.md` for the detailed implementation plan.
