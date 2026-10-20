# O2C Process Improvement Agent — User & Mechanics Manual

Version: **0.5.0 portfolio MVP**

This manual explains both **how to use the application** and **how it works internally**.

The project combines an Order-to-Cash (O2C) analytics database with a bounded AI-assisted process-improvement agent. The system is designed to investigate business-process deterioration, identify the stage and business dimension where the change is concentrated, retrieve relevant operating context, test transparent what-if scenarios, and return a recommendation that still requires human approval.

---

# 1. What the system is for

Use the application when you want to answer questions such as:

> Why did O2C cycle time worsen in Q3 2024 versus Q2 2024?

> Which process stage deteriorated the most?

> Is the issue concentrated in Marketplace, Web, InsideSales, or a customer segment?

> What business rule or process change might be relevant?

> What would happen to the modeled cash cycle if Order → Ship time improved by 10%, 25%, or another assumption?

The system is designed as **decision support**, not as an autonomous operations system.

It can:

- read approved O2C analytics;
- compare periods;
- rank stage deterioration;
- drill into approved business dimensions;
- retrieve local business context;
- run deterministic scenario calculations;
- maintain bounded session state;
- return a recommendation and pilot plan;
- expose a trace of the tools used.

It cannot:

- execute arbitrary SQL;
- change orders, invoices, payments, or customer terms;
- send messages to customers or suppliers;
- change policy;
- commit spend;
- implement a process change automatically.

---

# 2. Fastest way to run the demo

## Requirements

You need:

- Docker Desktop or Docker Engine;
- Docker Compose v2;
- Git;
- a terminal.

The free demo does **not** require an OpenAI API key.

## Recommended command

From the repository root:

```bash
make demo-open
```

Equivalent direct command:

```bash
bash agent/scripts/start_demo.sh --open
```

The launcher:

1. checks Docker and Docker Compose;
2. removes old demo containers/volumes unless `--keep-data` is used;
3. starts MySQL and the FastAPI service;
4. loads the O2C database;
5. applies controlled Scenario V1;
6. waits for the API;
7. checks demo readiness;
8. opens the browser when `--open` is used.

The main page is:

```text
http://localhost:8000/
```

FastAPI documentation is available at:

```text
http://localhost:8000/docs
```

---

# 3. The first screen

When the application opens, check the four readiness indicators.

## Database

Should show an order count.

This confirms that MySQL is connected and the O2C data is loaded.

## Scenario V1

Should show:

> Applied

This confirms that the controlled Marketplace bottleneck benchmark has been injected.

## Backend

By default it should show:

> mock · v0.5.0

The mock backend is the free demonstration backend.

## Demo status

Should show:

> Ready to present

Do not start a formal demo until this indicator is green.

---

# 4. Main interface

The page is divided into several functional areas.

## 4.1 Architecture flow

Near the top you will see:

```text
Business question
    ↓
Model boundary
    ↓
Approved tools
    ↓
Evidence package
    ↓
Human decision
```

This is the core design of the system.

The model does not directly control the database or business process. It selects from a bounded set of analytical tools.

---

# 5. Investigation controls

## Business question box

You can type a natural-language O2C question.

Example:

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

The user does not need to know SQL or tool names.

## Preset buttons

### Full diagnosis

Runs the main portfolio investigation.

Use this first during a demo.

Expected path:

```text
compare_stage_performance
→ analyze_process by channel
→ retrieve_policy
→ simulate_stage_improvement
→ recommendation
```

### Channel drill-down

Focuses on Order → Ship performance by sales channel.

Use this when you want to isolate where the stage deterioration is concentrated.

### 25% what-if

Runs the deterministic scenario simulator with a 25% Order → Ship improvement assumption.

### Approval guardrail

Tests the system with an unsafe/unauthorized business request such as automatically changing the process or customer terms.

The system should refuse execution and keep the recommendation behind human approval.

### Causality follow-up

Use this **after Full diagnosis** in the same session.

The system explains what additional evidence would be needed before claiming that the Marketplace promotional-review change caused the slowdown.

In mock mode, this follow-up reuses the prior structured investigation evidence and does not rerun the entire analytical tool chain.

---

# 6. Custom scenario control

You can enter a percentage under:

> Custom Order → Ship improvement assumption (%)

Allowed range:

```text
0–100
```

Then click:

> Set custom what-if

This prepares a natural-language scenario question.

Example:

```text
10%
```

The resulting question is approximately:

> What if Q3 2024 Order-to-Ship time were reduced by 10%? What happens to the modeled cash cycle?

Then click:

> Run investigation

Scenario calculations are performed in deterministic Python, not by the language model.

---

# 7. Session and profile controls

These controls are shown outside Presentation Mode.

## Session ID

Example:

```text
demo-1
```

A session preserves response lineage so follow-up questions can continue from prior investigation context.

## Analyst profile ID

Example:

```text
analyst-demo
```

This stores only bounded reporting preferences.

## Continue a stateful investigation session

Keep this checked if you want follow-up questions to reuse the previous response context.

Uncheck it if you want the question treated as a fresh request.

---

# 8. Reporting preferences

The profile can store only a small whitelist of preferences.

## Detail level

Options:

- Executive
- Balanced
- Detailed

## Preferred breakdown

Options:

- Channel
- Customer segment
- No preference

## Include risks

Controls whether risk discussion is preferred in the answer.

## Include scenario

Controls whether scenario planning should be included when relevant.

These preferences do **not** override:

- measured evidence;
- tool outputs;
- safety rules;
- the current user request;
- human-approval boundaries.

---

# 9. Run investigation

Click:

> Run investigation

The application sends the question to the configured backend.

Depending on the question, the backend may return a direct answer or call one or more approved tools.

The tool results are then sent back into the orchestration loop until the final answer is produced or the maximum turn limit is reached.

---

# 10. How to read the results

## 10.1 Process flow

The process strip shows:

```text
Order → Ship
Ship → Invoice
Invoice → Payment
```

After Full diagnosis, the stage that deteriorated the most is highlighted.

In Scenario V1, this should be:

> Order → Ship

This is important because Invoice → Payment is still the longest absolute stage, but it is **not** the stage that worsened.

---

# 11. KPI cards

## Q3 O2C cycle

Shows the current-period average total O2C cycle time.

Expected Scenario V1 value:

```text
33.71 days
```

## Largest stage deterioration

Expected:

```text
Order → Ship
```

Expected period change:

```text
1.48 → 2.09 days
+0.61 days
```

## Strongest channel driver

Expected:

```text
Marketplace
```

Expected Order → Ship change:

```text
1.45 → 4.62 days
+3.17 days
```

## Scenario days saved

For the default 25% Order → Ship assumption:

```text
about 0.52 modeled days
```

## Evidence status

This card indicates the evidence interpretation.

Possible examples:

### Descriptive

The answer is grounded in measured analytical results.

### Hypothesis

Retrieved process context is relevant, but causal proof is still missing.

This card is intentionally included to prevent a process-change log from being displayed as if it proves causation.

---

# 12. Evidence tables

## Stage comparison

Shows Q2, Q3, and change for:

- Order → Ship;
- Ship → Invoice;
- Invoice → Payment.

Expected Scenario V1 values:

| Stage | Q2 | Q3 | Change |
|---|---:|---:|---:|
| Order → Ship | 1.48 | 2.09 | +0.61 |
| Ship → Invoice | 1.00 | 1.00 | 0.00 |
| Invoice → Payment | 30.76 | 30.49 | -0.27 |

## Channel deterioration

Expected Order → Ship values:

| Channel | Q2 | Q3 | Change |
|---|---:|---:|---:|
| Marketplace | 1.45 | 4.62 | +3.17 |
| InsideSales | 1.44 | 1.47 | +0.03 |
| Web | 1.54 | 1.54 | 0.00 |

---

# 13. Investigation path

This section shows the business-friendly tool sequence.

For Full diagnosis, expect something close to:

```text
STEP 1 — Compare stages
Rank period-over-period deterioration

STEP 2 — Drill down
Analyze channel pattern

STEP 3 — Retrieve context
Ground interpretation in business context

STEP 4 — Run scenario
Calculate transparent what-if impact
```

This is useful during interviews because it demonstrates that the system is not returning an untraceable chatbot answer.

---

# 14. Agent answer

The answer is organized into business-oriented sections.

Typical structure:

- Finding
- Evidence
- Business interpretation
- Scenario impact
- Risks / unknowns
- Next action
- Proposed implementation plan

When a process change is recommended, the prompt now requires:

- bounded pilot scope;
- success metrics;
- major dependencies;
- human decision gate.

---

# 15. Inspect tool trace

Expand:

> Inspect tool trace

This shows the technical tool calls and results.

Typical trace item contains:

- tool name;
- arguments;
- tool result;
- turn;
- latency.

Use this for technical interviews, debugging, and evaluation.

---

# 16. Response metadata

Expand:

> Inspect response metadata

This includes information such as:

- backend;
- model;
- response ID;
- parent response ID;
- tool call count;
- model call count;
- elapsed time;
- usage metadata;
- applied preferences.

---

# 17. Prompt and tool inspection

Outside Presentation Mode, expand:

> Inspect agent instructions & tool catalog

This panel loads directly from the running application.

It shows:

- parsed system-prompt rules;
- all five approved tools;
- tool descriptions;
- required parameters;
- system-prompt version hash;
- tool-catalog version hash;
- full system prompt.

This is useful when someone asks:

> What prompt did you use?

or:

> What tools can the agent call?

The panel shows the actual running design instead of a manually copied document.

---

# 18. Workflow v1 baseline

Click:

> Run Workflow v1 baseline

This demonstrates the difference between a deterministic workflow and Agent v1.

## Workflow v1 behavior

Fixed sequence:

```text
total-cycle comparison
→ stage comparison
→ illustrative 20% scenario
```

It can:

- measure cycle-time change;
- rank stage deterioration;
- choose the most deteriorated stage;
- run an illustrative scenario.

It intentionally cannot:

- decide which business dimension to drill into;
- decide whether policy/context retrieval is needed;
- dynamically select the next business investigation step.

## Agent v1 behavior

Agent v1 can select among bounded tools based on the question and prior results.

The portfolio story is:

> Workflow v1 proves the deterministic baseline. Agent v1 adds bounded next-step selection.

---

# 19. Presentation Mode

Click:

> Presentation mode

This hides technical controls such as:

- session configuration;
- profile preferences;
- API docs link;
- prompt/tool panel;
- workflow baseline controls;
- response metadata.

Use Presentation Mode for a cleaner 3–5 minute demo.

Exit Presentation Mode when you want to explain the architecture or implementation.

---

# 20. Exporting results

## Download Markdown report

Exports a human-readable report containing:

- business question;
- KPI summary;
- stage table;
- channel table;
- retrieved context;
- scenario result;
- agent answer;
- tool path;
- mock/real-backend disclosure;
- governance note.

## Download raw JSON

Exports the complete machine-readable agent response.

Use this when a technical reviewer wants the full tool trace and metadata.

---

# 21. Terminal fallback

If the browser is unavailable but the API is running:

```bash
make demo-cli
```

Equivalent:

```bash
python3 agent/scripts/run_demo_cli.py
```

To save the raw result:

```bash
python3 agent/scripts/run_demo_cli.py \
  --output agent/artifacts/local_demo_response.json
```

---

# 22. Stopping and resetting

## Stop and keep data

```bash
make demo-stop
```

Equivalent:

```bash
docker compose down
```

## Stop and remove demo data/state

```bash
make demo-reset
```

Equivalent:

```bash
docker compose down -v --remove-orphans
```

## Start while keeping existing data

```bash
make demo-keep
```

Equivalent:

```bash
bash agent/scripts/start_demo.sh --keep-data --open
```

---

# 23. Internal mechanics

## 23.1 Model boundary

The application supports two backends.

### Mock

Default.

Purpose:

- free demonstration;
- integration testing;
- deterministic portfolio walkthrough;
- no API key required.

The mock backend scripts known investigation routes.

It is not presented as proof that an LLM independently reasoned through the case.

### OpenAI

Optional.

Set:

```bash
MODEL_BACKEND=openai
OPENAI_API_KEY=...
```

The OpenAI backend receives the same:

- system prompt;
- tool catalog;
- analytical tool implementations;
- state mechanism;
- evaluation cases.

The model then selects tools through the Responses API.

---

# 24. System prompt mechanics

The system prompt defines the model as:

> an AI business process improvement analyst focused on the Order-to-Cash process

Core rules include:

1. separate observed evidence from hypotheses and assumptions;
2. never invent KPI values;
3. do not claim causality from descriptive patterns alone;
4. distinguish stage deterioration from absolute stage length;
5. measure and drill down before recommending;
6. normalize collection performance against contractual due dates when appropriate;
7. retrieve policy/process context when relevant;
8. use deterministic tools for numerical scenarios;
9. treat scenario reductions as assumptions;
10. never execute operational changes;
11. include findings, evidence, scenario impact, risks, next action, and—when recommending process change—pilot scope, metrics, dependencies, and a human decision gate;
12. preferences cannot override evidence or safeguards.

---

# 25. Approved tools

The model can call only five business tools.

## 25.1 `compare_stage_performance`

Purpose:

Compare the three sequential cash-cycle stages between two periods.

Stages:

- Order → Ship
- Ship → Invoice
- Invoice → Payment

The tool computes:

- current duration;
- comparison duration;
- absolute change;
- percentage change;
- deterioration ranking.

The ranking is based on **change**, not absolute duration.

---

# 26. `analyze_process`

Purpose:

Analyze an approved KPI over a period.

Supported metrics include:

- total O2C cycle days;
- Order → Ship days;
- Ship → Delivery days;
- Ship → Invoice days;
- Invoice → Payment days;
- payment delay vs due date;
- late-payment rate;
- on-time delivery rate;
- on-time ship rate.

Supported dimensions:

- segment;
- channel.

The model cannot provide arbitrary SQL.

The tool uses parameterized SQL over whitelisted metrics and dimensions.

---

# 27. `get_stage_baseline`

Returns average stage durations for a selected period.

It is also used by the scenario simulator.

The cash-cycle path is modeled as:

```text
Order
→ Shipment
→ Invoice
→ First payment
```

Delivery is tracked separately because fulfillment delivery can overlap with billing/collection activity and should not automatically be added to the cash-cycle path.

---

# 28. `retrieve_policy`

Searches local Markdown business-context files.

Current implementation uses lightweight keyword overlap.

It returns:

- source file;
- heading;
- paragraph;
- score.

It is intended to retrieve:

- SLA rules;
- process notes;
- guardrails;
- change-log entries.

Important rule:

> retrieved timing/context can support a hypothesis but cannot prove causality.

---

# 29. `simulate_stage_improvement`

Runs deterministic Python scenario calculations.

Inputs:

- period;
- Order → Ship reduction percentage;
- Ship → Invoice reduction percentage;
- Invoice → Payment reduction percentage.

Each reduction must be:

```text
0–100%
```

The simulator calculates:

- modeled baseline cash cycle;
- modeled scenario cash cycle;
- days saved;
- percent improvement;
- per-stage scenario durations.

No LLM arithmetic is required.

---

# 30. How the agent loop works

A simplified version:

```text
1. User asks a business question.
2. Backend receives system prompt + approved tools.
3. Model/backend returns either:
   a. direct answer, or
   b. function/tool call.
4. Application validates and dispatches the tool.
5. Tool returns deterministic evidence.
6. Tool result is sent back to the backend.
7. Backend decides the next tool or final answer.
8. Loop ends when no more function calls are returned.
```

The application currently limits the loop to a bounded number of turns.

---

# 31. Why no free-form SQL

The model is not allowed to generate SQL and execute it directly.

Instead:

```text
Natural-language question
        ↓
approved metric/tool
        ↓
whitelisted SQL expression
        ↓
parameterized query
        ↓
result
```

Benefits:

- better security;
- easier evaluation;
- predictable KPI definitions;
- easier debugging;
- less hallucinated SQL;
- clearer business semantics.

---

# 32. Why deterministic scenario math

The model is responsible for deciding whether a scenario is useful.

The Python tool is responsible for the arithmetic.

This separates:

```text
reasoning about what to test
```

from:

```text
calculation of what the assumption means
```

This is important because an LLM-generated number is harder to audit than deterministic code.

---

# 33. Scenario V1 mechanics

Scenario V1 is a controlled benchmark.

Baseline:

```text
Q2 2024
2024-04-01 through 2024-06-30
```

Problem period:

```text
Q3 2024
2024-07-01 through 2024-09-30
```

Primary controlled effect:

- approximately 70% of selected Q3 Marketplace orders receive a +4-day shift before shipment.

Related timestamps are shifted so the primary deterioration remains concentrated in Order → Ship rather than creating artificial downstream stage inflation.

Secondary confounder:

- a smaller subset of Q3 Enterprise payments receives an additional delay.

Purpose:

The agent must identify the dominant deterioration without being distracted by the longest absolute stage or a smaller confounding signal.

---

# 34. Causality mechanics

The project deliberately separates:

## Observation

Example:

> Marketplace Order → Ship increased from 1.45 to 4.62 days.

## Context

Example:

> A manual Marketplace promotional-code review step was introduced on July 1.

## Hypothesis

Example:

> The new review step may be contributing to the slowdown.

## Causal proof

Not established by the current data.

Stronger evidence would include:

- affected vs unaffected cohorts;
- queue timestamps;
- exception/rework data;
- control for concurrent changes;
- controlled pilot;
- quasi-experimental design.

---

# 35. Payment-term mechanics

Raw Invoice → Payment duration can be misleading.

Example:

A Net45 Enterprise customer may take longer to pay than a Net15 SMB customer while still paying on time.

Therefore the agent prompt prefers:

- payment_delay_vs_due_days;
- late_payment_rate;

when evaluating collection performance across customers with different terms.

Use raw Invoice → Payment duration when the question is specifically about cash-cycle length.

---

# 36. State mechanics

## Short-term session state

Each session stores the latest response lineage ID.

This supports follow-up questions.

In mock mode, the causal follow-up can reuse structured results stored in the mock response state.

In OpenAI mode, the application supplies `previous_response_id` to the Responses API.

## Long-term preferences

Only bounded presentation preferences are persisted.

The system intentionally does not create unrestricted business memory.

---

# 37. Observability mechanics

The agent records:

- response IDs;
- parent response ID;
- backend/model;
- model call count;
- tool turns;
- tool call count;
- elapsed time;
- usage information;
- model response trace;
- tool trace.

This allows the agent to be evaluated as a system instead of only reading the final answer.

---

# 38. Evaluation mechanics

The project has several testing layers.

## Unit tests

Validate individual Python components.

Run:

```bash
make agent-test
```

## Docker smoke test

Validates:

- Compose configuration;
- agent image build;
- database startup;
- API health;
- UI availability;
- session endpoint.

## Mocked behavior evaluation

Runs seven scripted integration cases.

Current retained result:

```text
7/7 deterministic trace checks passed
```

This validates the integration and expected tool behavior.

It is **not** presented as 100% LLM reasoning accuracy.

## Portfolio demo smoke test

Validates the actual documented presentation path, including:

- launcher;
- Makefile commands;
- readiness endpoint;
- app version;
- prompt/tool design endpoint;
- Workflow v1;
- Agent v1 four-tool investigation;
- Markdown report generation;
- custom scenario;
- CLI fallback;
- stateful causal follow-up;
- frontend JavaScript syntax.

---

# 39. Recommended demo sequence

For a 3–5 minute interview demo:

## Step 1

Run:

```bash
make demo-open
```

## Step 2

Confirm all readiness indicators are green.

## Step 3

Enable Presentation Mode.

## Step 4

Click Full diagnosis.

## Step 5

Click Run investigation.

## Step 6

Point out:

- Q3 total O2C deterioration;
- Order → Ship as the most deteriorated stage;
- Marketplace concentration;
- process-change context;
- evidence status = hypothesis rather than causal proof;
- 25% scenario impact;
- recommended pilot and decision gate.

## Step 7

Optionally exit Presentation Mode and show:

- tool trace;
- prompt/tool catalog;
- Workflow v1 baseline;
- stateful causal follow-up.

---

# 40. Recommended explanation during a demo

A concise narration:

> The system starts from a business question rather than a SQL query. The model boundary cannot access arbitrary SQL; it chooses among five bounded tools. The database and Python layers perform the numerical work. In this example, the agent compares stages and finds that Order-to-Ship deteriorated the most, then drills into channel and finds Marketplace. It retrieves a July process change as context but labels it as hypothesis rather than causal proof. The scenario simulator then models a 25% improvement, and the final output recommends a bounded pilot with metrics, dependencies, and a human decision gate.

---

# 41. Troubleshooting

## Docker command not found

Install Docker Desktop or Docker Engine.

## Docker daemon unavailable

Start Docker Desktop/Engine and retry.

## Demo status says setup incomplete

Run a clean reset:

```bash
make demo-reset
make demo-open
```

## Scenario V1 says not applied

The controlled overlay did not load.

Run the launcher again without `--keep-data`.

## Browser does not open

Open manually:

```text
http://localhost:8000/
```

## UI works but question returns mock fallback message

The free mock backend recognizes documented demo routes and common paraphrases but is not a general natural-language model.

Use a preset, or configure the OpenAI backend for open-ended behavior.

## Need to see whether the API is alive

Open:

```text
http://localhost:8000/health
```

## Need to inspect readiness

Open:

```text
http://localhost:8000/demo/status
```

## Need to inspect prompt/tool design

Open:

```text
http://localhost:8000/demo/design
```

---

# 42. Mock vs real OpenAI usage

## Free mock mode

Use when:

- demonstrating the engineering;
- testing database/tool integration;
- showing the controlled benchmark;
- avoiding API cost;
- rehearsing a portfolio presentation.

Safe description:

> The mock is at the model/orchestration boundary. The database queries, retrieval, scenario calculations, API, state, traces, and evaluation infrastructure are real project components.

## OpenAI mode

Use when:

- testing real model tool selection;
- measuring semantic performance;
- exploring unseen questions.

Do not claim real-model performance until it has actually been measured.

---

# 43. Project mechanics summary

The full mechanics can be summarized as:

```text
Controlled business data
        ↓
Natural-language question
        ↓
System prompt + bounded tools
        ↓
Model decides next approved action
        ↓
SQL / retrieval / Python executes deterministic work
        ↓
Tool evidence returns to model
        ↓
Model interprets evidence
        ↓
Scenario + risk + pilot recommendation
        ↓
Human approval
        ↓
Trace + report + evaluation
```

The design principle is:

> Let the model decide **which approved analytical action to take**, but keep important data access, calculations, business boundaries, and evaluation outside the model.

---

# 44. Useful commands

```bash
make help
```

Start clean demo:

```bash
make demo
```

Start and open browser:

```bash
make demo-open
```

Reuse current data:

```bash
make demo-keep
```

Run CLI demo:

```bash
make demo-cli
```

Stop:

```bash
make demo-stop
```

Full reset:

```bash
make demo-reset
```

Run agent tests:

```bash
make agent-test
```

Validate Compose:

```bash
make compose-check
```

---

# 45. Related documentation

For deeper detail, see:

- `docs/business_requirements.md`
- `docs/process_improvement_case.md`
- `docs/requirements_traceability.md`
- `docs/prompt_design.md`
- `docs/architecture.md`
- `docs/memory_design.md`
- `docs/testing_modes.md`
- `docs/mock_evaluation_report.md`
- `docs/demo_quickstart.md`
- `docs/demo_script.md`
- `docs/demo_interview_qa.md`
- `docs/portfolio_final_report.md`

---

# 46. One-sentence description

> The O2C Process Improvement Agent is a bounded business-analysis system that uses natural-language orchestration to select approved SQL, retrieval, and Python tools, diagnose process deterioration, test transparent scenarios, and produce an auditable recommendation without giving the model unrestricted data or operational control.
