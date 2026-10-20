# Project Plan — AI Process Improvement & Scenario Planning Agent

## 1. Business problem

Traditional O2C dashboards describe performance but still require a human analyst to decide:
- which metric to inspect;
- where to drill down;
- what business rule or process change is relevant;
- which intervention should be tested;
- how to communicate the trade-off.

The project adds an AI investigation layer while keeping quantitative calculations deterministic and auditable.

## 2. Primary user

Operations analyst, business analyst, finance operations analyst, or process-improvement manager.

## 3. Core user story

> As an operations analyst, I want to describe an O2C performance problem in business language and receive an evidence-backed investigation, so that I can identify bottlenecks and compare improvement options without manually running every query.

## 4. Success criteria

### Product
- User can ask a natural-language O2C process question.
- Agent selects from approved analytics, context-retrieval, and simulation tools.
- Final answer uses measured values returned by tools.
- Agent distinguishes observation, hypothesis, and assumption.
- Agent can continue a prior investigation through explicit session state.
- Analyst reporting preferences can persist through a bounded, inspectable profile.
- User can run the system through a lightweight browser UI or API.
- Agent never executes business changes.

### Technical
- No model-generated SQL is executed directly.
- Tool arguments use bounded schemas and whitelisted metrics/dimensions.
- Scenario math is deterministic and unit tested.
- API exposes fixed workflow, stateless agent, stateful-session, and preference endpoints.
- Controlled Scenario V1 has a reproducible hidden ground truth.
- Deterministic evals check tool choice/arguments before semantic judging.
- Deployment is containerized and smoke tested without requiring model API calls.
- Live model behavior can be evaluated manually in GitHub Actions with stored artifacts.

## 5. Version plan

### P1 — Workflow baseline — implemented
Goal: demonstrate the problem can be solved with a fixed workflow before adding agent autonomy.

Implemented:
- FastAPI skeleton;
- process KPI query tool;
- stage comparison tool;
- deterministic scenario simulator;
- fixed cycle-time investigation endpoint;
- deterministic Scenario V1 dataset/benchmark.

### P2 — Agent v1 — implemented / awaiting recorded live results
Goal: allow the model to choose the next analysis step from tool results.

Implemented:
- Responses API tool-calling loop;
- analytics, business-context retrieval, and simulator tools;
- stage-deterioration ranking rather than longest-stage shortcut;
- grouped period-over-period drill-down calculations outside the LLM;
- inspectable tool trace;
- max-turn stop condition;
- explicit human-approval and causal-language guardrails.

Remaining evidence milestone:
- run the full live eval set against a configured API key;
- tune prompt/tool descriptions only from observed failures.

### P3 — Stateful context and bounded memory — implemented
Goal: make repeated investigations useful without stuffing full history into every prompt or storing unrestricted memory.

Implemented short-term state:
- persistent local SQLite session store;
- Responses API `previous_response_id` persisted by session;
- stateful `/agent/session/{session_id}/ask` endpoint;
- session inspection/reset endpoints.

Implemented bounded long-term analyst preferences:
- `detail_level`;
- `preferred_breakdown`;
- `include_risks`;
- `include_scenario_if_relevant`;
- explicit profile inspect/update/reset API;
- unknown memory keys rejected;
- preferences cannot override evidence, KPI definitions, current instructions, or approval boundaries.

The state store is not used as a second copy of raw customer-level transactional data or unrestricted conversation history.

### P4 — Observability and evaluation — implemented / awaiting live artifact
Goal: prove that agent v1 follows the intended business reasoning and safety boundaries on a controlled benchmark.

Implemented:
- reproducible controlled Scenario V1;
- validated benchmark values and hidden ground truth;
- unit/integration GitHub Actions;
- tool-call trace with turn/call metadata;
- machine-checkable trace requirements in `eval_cases.json`;
- deterministic trace evaluator;
- single-run and batch live-eval CLI scripts;
- seven-dimension semantic rubric;
- deterministic rubric aggregation and critical-dimension failure rule;
- optional LLM-as-Judge layer that does not receive hidden Scenario V1 ground truth;
- manual API-backed GitHub Actions workflow;
- Markdown evaluation-summary generator.

Evaluation dimensions:
- tool-selection correctness;
- KPI numerical consistency;
- evidence grounding;
- assumption labeling;
- policy/context use;
- causality discipline;
- human-approval compliance;
- completion rate;
- semantic decision usefulness and uncertainty communication.

Remaining evidence milestone:
- capture the first complete seven-case live report and semantic report;
- retain those artifacts for the final portfolio evaluation discussion.

### P5 — Deployment and demo — mostly implemented
Goal: present a deployable business system rather than a notebook.

Implemented:
- non-root agent Dockerfile;
- Compose agent + MySQL + Adminer stack;
- persistent agent-state volume;
- service health checks;
- automatic Docker build/API/UI smoke test;
- lightweight analyst UI served by FastAPI;
- explicit trace and response-metadata inspection in the UI;
- deployment guide;
- five-minute demo script;
- evaluation-summary generator.

Remaining:
- record a complete API-backed evaluation result;
- turn the generated evaluation summary into the final project report after observed live results are available.

## 6. Validated demo case

Business question:

> "O2C cycle time worsened in Q3 2024 versus Q2 2024. Investigate the strongest driver, identify the bottleneck, and test a realistic process improvement."

Validated Scenario V1 signature:
- Q2 total O2C: 33.28 days;
- Q3 total O2C: 33.71 days;
- order-to-ship: 1.48 → 2.09 days (+0.61; +41.22%);
- Marketplace order-to-ship: 1.45 → 4.62 days (+3.17);
- Web and InsideSales remain approximately flat;
- invoice-to-payment is still the longest absolute stage but slightly improves, creating a deliberate longest-stage-vs-deterioration test.

Ideal agent trace:
1. compare stage deterioration across Q3 vs Q2;
2. identify order-to-ship as the deteriorating stage;
3. drill into channel;
4. identify Marketplace concentration;
5. retrieve relevant SLA/process-change context;
6. distinguish temporal/context evidence from causal proof;
7. run a transparent what-if scenario;
8. present evidence, hypothesis, scenario impact, unknowns, and next action.

## 7. Scope boundaries

In scope:
- descriptive process analytics;
- diagnostic drill-down;
- business-rule and process-change retrieval;
- transparent scenario modeling;
- recommendation drafting;
- stateful investigation continuity;
- bounded analyst preferences;
- deployment and evaluation tooling.

Out of scope for the MVP:
- automatic operational actions;
- free-form write access to the O2C database;
- causal inference claims;
- optimization with unvalidated cost/capacity assumptions;
- unrestricted enterprise-wide analytics;
- unrestricted long-term memory;
- autonomous multi-agent orchestration without a demonstrated coordination need.

## 8. Extension ideas

After the MVP is stable:
- add product/SKU drill-down for fulfillment delays;
- connect inventory availability to order-to-ship performance;
- add reproducible AR aging/DSO investigations;
- add richer process-event data for rework and queue analysis;
- upgrade business-context retrieval to embeddings/vector search;
- build a TO-BE process recommendation schema;
- generate an implementation backlog with owner, KPI, dependency, and risk fields.
