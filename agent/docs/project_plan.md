# Project Plan — AI Process Improvement & Scenario Planning Agent

## 1. Business problem

Traditional O2C dashboards describe performance but still require a human analyst to decide:
- which metric to inspect;
- where to drill down;
- what business rule is relevant;
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
- Agent selects from approved analytics, policy, and simulation tools.
- Final answer cites measured values returned by tools.
- Agent distinguishes observation, hypothesis, and assumption.
- Agent never executes business changes.

### Technical
- No model-generated SQL is executed directly.
- Tool arguments use bounded schemas and whitelisted metrics/dimensions.
- Scenario math is deterministic and unit tested.
- API exposes both fixed workflow and agent endpoints.
- At least five eval cases cover correctness and safety.

## 5. Version plan

### P1 — Workflow baseline
Goal: demonstrate the problem can be solved with a fixed workflow before adding agent autonomy.

Deliverables:
- FastAPI skeleton;
- process KPI query tool;
- stage baseline tool;
- deterministic scenario simulator;
- fixed cycle-time investigation endpoint.

### P2 — Agent v1
Goal: allow the model to choose the next analysis step from tool results.

Deliverables:
- Responses API tool-calling loop;
- analytics, policy retrieval, and simulator tools;
- tool trace returned with each response;
- max-turn stop condition;
- failure handling.

### P3 — Stateful context
Goal: make repeated investigations more useful without stuffing full history into every prompt.

Candidate memory:
- preferred KPI definitions;
- preferred comparison windows;
- previously investigated issues;
- approved scenario assumptions;
- user/reporting preferences.

Do not store sensitive customer-level details by default.

### P4 — Observability and evaluation
Goal: prove that agent v1 is better than the fixed workflow for ambiguous questions.

Evaluation dimensions:
- tool-selection correctness;
- KPI numerical consistency;
- evidence grounding;
- assumption labeling;
- policy compliance;
- unnecessary-tool-call rate;
- completion rate.

Add structured trace logging and an automated judge only after deterministic checks are in place.

### P5 — Deployment and demo
Goal: present a deployable business system rather than a notebook.

Deliverables:
- Dockerfile;
- production FastAPI configuration;
- lightweight web UI;
- sample synthetic business cases;
- demo script;
- architecture diagram;
- final evaluation report.

## 6. Recommended demo case

Business question:

> "O2C cycle time worsened in Q2 versus Q1. Investigate the strongest driver, identify the bottleneck, and test a realistic process improvement."

Ideal trace:
1. compare total O2C cycle time;
2. inspect stage baselines;
3. drill into segment/channel if needed;
4. retrieve policy context if an SLA or business rule matters;
5. run a transparent what-if scenario;
6. present evidence, hypothesis, scenario impact, unknowns, and next action.

## 7. Scope boundaries

In scope:
- descriptive process analytics;
- diagnostic drill-down;
- business-rule retrieval;
- transparent scenario modeling;
- recommendation drafting.

Out of scope for the MVP:
- automatic operational actions;
- free-form write access to the database;
- causal inference claims;
- optimization with unvalidated cost/capacity assumptions;
- unrestricted enterprise-wide analytics;
- multi-agent orchestration unless a real coordination need emerges.

## 8. Extension ideas

After the MVP is stable:
- add product/SKU drill-down for fulfillment delays;
- connect inventory availability to order-to-ship performance;
- add AR aging/DSO investigation;
- add richer process-event data for rework and queue analysis;
- upgrade policy retrieval to vector search;
- build a TO-BE process recommendation schema;
- generate an implementation backlog with owner, KPI, dependency, and risk fields.
