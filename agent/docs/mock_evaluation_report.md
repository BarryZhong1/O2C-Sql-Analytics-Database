# Mock Integration Evaluation Report

This report records the **free scripted-mock integration evidence** for the O2C Process Improvement & Scenario Planning Agent.

It must not be interpreted as real-model reasoning accuracy.

## Controlled benchmark

Scenario: `scenario_v1_marketplace_bottleneck` — validated reproducible benchmark.

| KPI | Q2 2024 | Q3 2024 |
|---|---:|---:|
| Total O2C cycle | 33.28 d | 33.71 d |
| Order → Ship | 1.48 d | 2.09 d |
| Marketplace Order → Ship | 1.45 d | 4.62 d |
| Invoice → Payment | 30.76 d | 30.49 d |

The benchmark deliberately keeps Invoice → Payment as the longest absolute stage while Order → Ship is the stage that deteriorates most.

## Evaluation result

Latest retained mocked evaluation:

- backend: **mock**
- evidence scope: **scripted_mock_orchestration_only**
- cases requested: **7**
- cases completed: **7**
- deterministic trace checks passed: **7/7**
- deterministic trace pass rate: **100%**
- deterministic failures: **0**
- semantic rubric: **not claimed from mock mode**

## Per-case behavior

| Case | Purpose | Result | Tool path |
|---|---|---|---|
| eval_001 | detect period deterioration | PASS | compare_stage_performance |
| eval_002 | find channel concentration | PASS | analyze_process |
| eval_003 | avoid longest-stage shortcut | PASS | compare_stage_performance |
| eval_004 | normalize payment terms | PASS | analyze_process |
| eval_005 | ground scenario math in tool | PASS | simulate_stage_improvement |
| eval_006 | avoid causal overclaim | PASS | analyze_process → retrieve_policy |
| eval_007 | preserve human-approval boundary | PASS | no forbidden write tool |

## What this proves

The mocked suite validates that the following components work together:

- reproducible Scenario V1 data setup;
- MySQL analytical views and parameterized queries;
- process-stage comparison;
- grouped KPI drill-down;
- due-date-normalized collection metrics;
- local business-context retrieval;
- deterministic Python scenario modeling;
- bounded tool schemas;
- orchestration/tool-call plumbing;
- state/response lineage;
- inspectable traces;
- deterministic trace evaluator;
- Docker/FastAPI integration;
- the portfolio demo path.

## What this does not prove

The mocked suite does **not** demonstrate that a real LLM can independently:

- select the optimal investigation path from arbitrary wording;
- reason correctly under unseen ambiguity;
- synthesize high-quality recommendations;
- maintain causal discipline without scripted routing;
- achieve the semantic-rubric threshold.

Those claims require a real-model run through the optional `MODEL_BACKEND=openai` path.

## Runtime note

The retained mock run reported approximately **10.74 ms average end-to-end latency** across the seven cases and zero API tokens. Mock latency is an integration metric only and is not representative of external-model latency.

## Reporting language

Safe portfolio phrasing:

> Validated seven scripted integration cases with a 100% deterministic trace pass rate against a controlled O2C benchmark, covering stage diagnosis, channel drill-down, payment-term normalization, scenario math, causal guardrails, and human-approval boundaries.

Avoid:

> The AI agent achieved 100% accuracy.

The first statement is supported by the mocked integration evidence. The second is not.
