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
- Agent never executes business changes.

### Technical
- No model-generated SQL is executed directly.
- Tool arguments use bounded schemas and whitelisted metrics/dimensions.
- Scenario math is deterministic and unit tested.
- API exposes fixed workflow, stateless agent, and stateful-session endpoints.
- Controlled Scenario V1 has a reproducible hidden ground truth.
- Deterministic evals check tool choice/arguments before semantic judging.

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

### P2 — Agent v1 — implemented / validating
Goal: allow the model to choose the next analysis step from tool results.

Implemented:
- Responses API tool-calling loop;
- analytics, business-context retrieval, and simulator tools;
- stage-deterioration ranking rather than longest-stage shortcut;
- grouped period-over-period drill-down calculations outside the LLM;
- inspectable tool trace;
- max-turn stop condition;
- explicit human-approval and causal-language guardrails.

Remaining:
- run the full live eval set against a configured API key;
- tune prompt/tool descriptions only from observed failures.

### P3 — Stateful context — in progress
Goal: make repeated investigations useful without stuffing full history into every prompt.

Implemented P3a:
- persistent local SQLite session store;
- Responses API `previous_response_id` persisted by session;
- stateful `/agent/session/{session_id}/ask` endpoint;
- session inspection/reset endpoints;
- local state DB excluded from version control.

Next P3b candidate memory:
- preferred KPI definitions;
- preferred comparison windows;
- approved scenario assumptions;
- reporting/detail preferences;
- compact summaries of prior investigations.

Do not store sensitive customer-level details by default. Long-term preference memory should be explicit, bounded, inspectable, and separable from raw conversation history.

### P4 — Observability and evaluation — in progress
Goal: prove that agent v1 improves on the fixed workflow for ambiguous questions.

Implemented:
- reproducible controlled Scenario V1;
- validated benchmark values and hidden ground truth;
- unit/integration GitHub Actions;
- tool-call trace with turn/call metadata;
- machine-checkable trace requirements in `eval_cases.json`;
- deterministic trace evaluator;
- single-run and batch live-eval CLI scripts.

Evaluation dimensions:
- tool-selection correctness;
- KPI numerical consistency;
- evidence grounding;
- assumption labeling;
- policy/context use;
- causality discipline;
- human-approval compliance;
- unnecessary-tool-call rate;
- completion rate.

Next:
- add a documented semantic rubric;
- optionally add LLM-as-Judge only for criteria that cannot be graded deterministically;
- retain deterministic calculations as authoritative for numeric/tool facts.

### P5 — Deployment and demo
Goal: present a deployable business system rather than a notebook.

Planned:
- Dockerfile for the agent service;
- production FastAPI configuration;
- lightweight analyst UI;
- demo script and architecture diagram;
- final evaluation report;
- optional multi-agent extension only if a real coordination need emerges.

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
- stateful investigation continuity.

Out of scope for the MVP:
- automatic operational actions;
- free-form write access to the O2C database;
- causal inference claims;
- optimization with unvalidated cost/capacity assumptions;
- unrestricted enterprise-wide analytics;
- autonomous multi-agent orchestration.

## 8. Extension ideas

After the MVP is stable:
- add product/SKU drill-down for fulfillment delays;
- connect inventory availability to order-to-ship performance;
- add reproducible AR aging/DSO investigations;
- add richer process-event data for rework and queue analysis;
- upgrade business-context retrieval to embeddings/vector search;
- build a TO-BE process recommendation schema;
- generate an implementation backlog with owner, KPI, dependency, and risk fields.
