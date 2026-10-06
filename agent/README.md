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

The repository already models the end-to-end O2C process with order, customer, shipment, invoice, payment, return, product, and inventory data plus analytical views and KPI definitions.

This agent extends that foundation from **descriptive analytics** to **AI-assisted process diagnosis and scenario planning** while retaining deterministic calculations, explicit approval boundaries, evaluation, memory design, and deployability.

## Supported business questions

- Why did total O2C cycle time increase?
- Which cash-cycle stage deteriorated the most versus a baseline period?
- Which customer segment or sales channel is driving a delay?
- Are customers actually paying late versus contractual due dates, or do they simply have longer terms?
- Is a known process change temporally consistent with the measured deterioration?
- What happens if order-to-ship, ship-to-invoice, or invoice-to-payment time improves by X%?

## Architecture

```text
Business user / analyst UI
          |
          v
      FastAPI service
          |
          +--> short-term session state (SQLite + previous_response_id)
          +--> bounded analyst preferences
          |
          v
AI investigator (OpenAI Responses API)
          |
          +------------------+-----------------------+
          |                  |                       |
          v                  v                       v
 Process analytics     Business context       Scenario simulator
 (SQL / MySQL)         (local retrieval)       (deterministic Python)
          |                  |                       |
          +------------------+-----------------------+
                             |
                             v
                 Evidence-backed recommendation
                             |
                             v
                      Human approval
```

See `docs/architecture.md` for component boundaries, sequence diagrams, deterministic/model/human responsibility zones, and the evaluation architecture.

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
- Process-change logs can support a hypothesis but are not causal proof.
- No operational or policy change is applied automatically.

## Project structure

```text
agent/
├── app/
│   ├── agent.py                 # Responses API tool loop + trace
│   ├── config.py                # environment settings
│   ├── db.py                    # O2C SQLAlchemy connection
│   ├── main.py                  # FastAPI API + analyst UI route
│   ├── state.py                 # sessions + bounded preferences
│   ├── static/index.html        # lightweight analyst UI
│   ├── workflow.py              # fixed Workflow v1 baseline
│   └── tools/
│       ├── process_analytics.py
│       ├── scenario_simulator.py
│       └── policy_retriever.py
├── data/
│   ├── scenario_v1_marketplace_bottleneck.sql
│   └── reset_scenario_v1.sql
├── docs/
│   ├── architecture.md
│   ├── project_plan.md
│   ├── business_scenario_v1.md
│   ├── data_readiness_review.md
│   ├── scenario_v1_benchmark.md
│   ├── memory_design.md
│   ├── deployment.md
│   ├── demo_script.md
│   └── final_report_template.md
├── evals/
│   ├── README.md
│   ├── eval_cases.json
│   ├── trace_evaluator.py
│   ├── semantic_evaluator.py
│   ├── semantic_rubric.json
│   ├── llm_judge.py
│   ├── scenario_v1_ground_truth.json
│   └── scenario_v1_benchmark.json
├── policies/
│   ├── o2c_sla_policy.md
│   └── process_change_log.md
├── scripts/
│   ├── calibrate_scenario_v1.py
│   ├── evaluate_agent_run.py
│   ├── run_live_evals.py
│   ├── run_semantic_judge.py
│   └── build_eval_summary.py
├── sql/
│   └── validate_scenario_v1.sql
├── Dockerfile
└── tests/
```

## Quick start with Docker

From the repository root:

```bash
export OPENAI_API_KEY="..."
docker compose up -d --build db agent adminer
```

Build the deterministic O2C dataset and apply the controlled Scenario V1 overlay:

```bash
docker compose exec -T db mysql -uroot -proot < sql/complete_setup.sql
docker compose exec -T db mysql -uroot -proot < agent/data/scenario_v1_marketplace_bottleneck.sql
```

Open the analyst UI:

```text
http://localhost:8000/
```

Other useful endpoints:

```text
http://localhost:8000/health
http://localhost:8000/docs
http://localhost:8080   # Adminer
```

See `docs/deployment.md` for the full deployment guide.

## Stateful investigations and bounded preferences

A named session stores only the latest Responses API response ID and timestamps so follow-up questions can continue the investigation without duplicating the raw transcript in the local state database.

Example:

```bash
curl -X POST http://localhost:8000/agent/session/demo-1/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Compare Q3 O2C performance with Q2 and identify the stage that deteriorated most.",
    "profile_id": "analyst-demo"
  }'
```

Longer-lived analyst memory is deliberately bounded to four whitelisted preferences:

- `detail_level`
- `preferred_breakdown`
- `include_risks`
- `include_scenario_if_relevant`

Preferences affect presentation/default drill-down style only. They cannot override evidence, KPI definitions, current user instructions, or human-approval boundaries.

See `docs/memory_design.md`.

## Validated Scenario V1 benchmark

Repeated clean GitHub Actions runs reproduce the controlled benchmark:

- Q2 total O2C: **33.28 days**
- Q3 total O2C: **33.71 days**
- Order-to-ship: **1.48 → 2.09 days** (+0.61; +41.22%)
- Marketplace order-to-ship: **1.45 → 4.62 days** (+3.17)
- Web order-to-ship: **1.54 → 1.54 days**
- InsideSales order-to-ship: **1.44 → 1.47 days**
- Invoice-to-payment: **30.76 → 30.49 days**

The longest absolute stage, invoice-to-payment, slightly improves. This deliberately tests whether the system distinguishes **largest deterioration** from **longest absolute duration**.

See `evals/scenario_v1_benchmark.json` and `docs/scenario_v1_benchmark.md`.

## Evaluation stack

The project uses layered evaluation rather than one subjective score:

1. **Scenario calibration** — verifies the injected benchmark is strong and reproducible.
2. **Deterministic trace evaluation** — checks required tools, arguments, forbidden actions, and bounded behavior.
3. **Semantic rubric** — scores evidence grounding, diagnostic reasoning, causal discipline, scenario transparency, decision usefulness, risks, and approval boundaries.
4. **Optional LLM-as-Judge** — applies the documented rubric to live answers while leaving numerical/tool truth to deterministic checks.

Run all live behavior cases after configuring the database and API key:

```bash
cd agent
python scripts/run_live_evals.py
python scripts/run_semantic_judge.py
python scripts/build_eval_summary.py
```

A manual GitHub Actions workflow, **Agent live behavior evals**, rebuilds Scenario V1, recalibrates it, runs all seven live cases, optionally applies the semantic judge, generates a Markdown evaluation summary, and uploads the artifacts. It is manual-only to avoid API cost on every push.

See `evals/README.md`.

## Demo and final report

- `docs/demo_script.md` provides a five-minute portfolio walkthrough plus a backup path if the external model API is unavailable during a presentation.
- `docs/final_report_template.md` is intentionally result-gated: measured live pass rates are added only after the full seven-case evaluation has actually run.

## CI / deployment validation

The branch includes separate workflows for:

- Python compilation and unit tests;
- deterministic Scenario V1 integration calibration;
- Docker/Compose build and API/UI smoke testing;
- manually triggered API-backed live behavior evaluation.

The automatic Docker smoke test does **not** call the model API.

## Roadmap status

- **P1 — Workflow baseline:** implemented and benchmarked.
- **P2 — Agent tools:** implemented with dynamic tool selection and observable traces.
- **P3 — Context/memory:** short-term session state and bounded analyst preferences implemented.
- **P4 — Quality:** deterministic calibration/trace checks, semantic rubric, optional LLM judge, live-eval runner, and summary generator implemented; full API-backed results still need to be recorded.
- **P5 — Deployment/demo:** Dockerized API, analyst UI, architecture documentation, demo script, and result-gated final report template implemented.

The next evidence-generating milestone is the full live seven-case evaluation against Scenario V1, followed by prompt/tool tuning only where the recorded failures justify it.
