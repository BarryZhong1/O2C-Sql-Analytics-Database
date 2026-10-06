# Final Project Report Template

> Replace bracketed placeholders only after the corresponding live evidence exists. Do not invent evaluation results.

## 1. Executive summary

This project extends an Order-to-Cash analytical database into a deployable AI-assisted process-improvement system. A business analyst can ask an operational question in natural language; the agent chooses from approved analytics, business-context retrieval, and deterministic scenario tools; the system returns an evidence-backed recommendation while preserving human approval for operational changes.

Final live-evaluation result: **[insert trace pass rate]** deterministic trace pass rate and **[insert semantic pass rate]** semantic rubric pass rate across **[insert completed cases]** completed behavior cases.

## 2. Business problem

Traditional O2C dashboards expose KPIs but do not remove the analytical work of deciding:

- which stage changed;
- where to drill down;
- whether a process rule/change is relevant;
- how to normalize customer payment behavior;
- which improvement scenario is worth testing;
- what uncertainty remains before implementation.

The project targets operations analysts, business analysts, finance-operations analysts, and process-improvement managers.

## 3. System design

Reference `docs/architecture.md`.

Summarize:

- FastAPI service and lightweight analyst UI;
- Responses API orchestration loop;
- whitelisted read-only process analytics;
- local business-context retrieval;
- deterministic Python scenario simulation;
- persistent short-term session state;
- bounded long-term analyst preferences;
- layered evaluation and Docker deployment.

## 4. Controlled business scenario

Scenario V1 injects a reproducible Q3 2024 Marketplace fulfillment bottleneck plus a smaller collections-side confounder.

Validated benchmark:

| Metric | Q2 2024 | Q3 2024 | Change |
|---|---:|---:|---:|
| Total O2C cycle | 33.28 days | 33.71 days | +0.43 |
| Order-to-ship | 1.48 days | 2.09 days | +0.61 |
| Invoice-to-payment | 30.76 days | 30.49 days | -0.27 |
| Marketplace order-to-ship | 1.45 days | 4.62 days | +3.17 |

The benchmark deliberately makes invoice-to-payment the longest absolute stage while order-to-ship is the stage that deteriorates most. This tests whether the agent diagnoses change rather than simply selecting the largest absolute duration.

## 5. Agent behavior and tool design

Describe the approved tools:

### Process analytics

Purpose: deterministic KPI analysis, period comparison, and channel/segment drill-down.

Key design control: no arbitrary model-generated SQL is executed.

### Business-context retrieval

Purpose: retrieve SLA rules, guardrails, and process-change logs.

Key design control: retrieved change timing may support a hypothesis but is not treated as causal proof.

### Scenario simulator

Purpose: deterministic what-if calculations for stage-duration improvements.

Key design control: scenario reductions are explicit assumptions rather than guaranteed intervention effects.

## 6. State and memory design

Short-term state persists the latest Responses API response ID by named session so follow-up questions can continue an investigation.

Long-term analyst memory is restricted to whitelisted preferences:

- detail level;
- preferred breakdown;
- risk inclusion;
- scenario inclusion when relevant.

Explain why unrestricted customer-level long-term memory was intentionally excluded from the MVP.

## 7. Evaluation methodology

The evaluation stack has four layers:

1. Scenario calibration.
2. Deterministic trace/tool checks.
3. Semantic rubric aggregation.
4. Optional LLM-as-Judge for semantic answer quality.

Deterministic checks remain authoritative for KPI and tool-use facts.

Seven behavior cases cover:

- period deterioration detection;
- channel concentration;
- longest-stage shortcut resistance;
- payment-term normalization;
- scenario grounding;
- causal discipline;
- human approval boundaries.

## 8. Final live results

Paste or summarize `artifacts/evaluation_summary.md` here after running the full live suite.

### Overall results

- Model: **[model]**
- Cases requested: **[n]**
- Cases completed: **[n]**
- Deterministic trace pass rate: **[rate]**
- Semantic rubric pass rate: **[rate]**
- Critical semantic failures: **[none / list]**

### Per-case table

| Case | Deterministic trace | Semantic rubric | Main observation |
|---|---|---|---|
| eval_001 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_002 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_003 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_004 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_005 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_006 | [PASS/FAIL] | [PASS/FAIL] | [observation] |
| eval_007 | [PASS/FAIL] | [PASS/FAIL] | [observation] |

## 9. Failure analysis and iteration

For every failed case, document:

1. observed failure;
2. whether the failure was tool selection, tool arguments, synthesis, causal language, scenario framing, or approval-boundary behavior;
3. root cause hypothesis;
4. smallest prompt/tool/schema change attempted;
5. before/after result;
6. whether the change introduced regressions elsewhere.

Do not tune directly against hidden ground-truth wording. Use failure categories and public tool outputs.

## 10. Deployment and observability

Document:

- Docker/Compose stack;
- non-root agent container;
- MySQL health check;
- FastAPI health endpoint;
- analyst UI smoke test;
- tool trace returned with agent responses;
- evaluation artifacts uploaded by GitHub Actions.

## 11. Limitations

Suggested limitations to discuss accurately:

- synthetic rather than production O2C data;
- descriptive diagnosis rather than causal inference;
- simple local text retrieval rather than enterprise search/vector infrastructure;
- local SQLite state store rather than production multi-user state service;
- no authentication/authorization in the portfolio UI;
- no automatic operational execution;
- semantic judge is model-based and therefore advisory rather than ground truth.

## 12. Future work

Prioritize only extensions with a clear business need, for example:

- SKU/inventory drill-down for fulfillment delays;
- richer process-event data for queue/rework analysis;
- reproducible AR aging/DSO investigations;
- enterprise retrieval/MCP connectors;
- centralized tracing;
- authenticated multi-user deployment;
- multi-agent decomposition only if independent domains or parallel work make it beneficial.

## 13. Resume/interview translation

Example project description after live results are measured:

> Built a deployable AI-assisted Order-to-Cash process-improvement agent using FastAPI, OpenAI Responses API, MySQL, deterministic Python scenario modeling, bounded state/memory, and layered evaluation; designed a controlled business benchmark and evaluated tool-selection, causal-discipline, and approval-boundary behavior across seven test cases.

Add measured pass rates only after they are actually recorded.
