# Sample Portfolio Demo Output

This file is a **reference snapshot** of the zero-cost portfolio demo using the controlled Scenario V1 dataset and `MODEL_BACKEND=mock`.

It is not a substitute for running the demo. The mock backend scripts the investigation path; the SQL analytics, retrieval, scenario calculations, API, trace, and benchmark values shown below are real project outputs.

## Business question

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

## Executive result

### Finding

Q3 average O2C cycle time is **33.71 days** versus **33.28 days** in Q2.

The stage with the largest deterioration is **Order → Ship**:

| Stage | Q2 | Q3 | Change |
|---|---:|---:|---:|
| Order → Ship | 1.48 | 2.09 | **+0.61** |
| Ship → Invoice | 1.00 | 1.00 | 0.00 |
| Invoice → Payment | 30.76 | 30.49 | -0.27 |

This deliberately demonstrates why the longest absolute stage is not necessarily the stage responsible for a recent slowdown.

### Strongest driver

Order-to-ship by sales channel:

| Channel | Q2 | Q3 | Change |
|---|---:|---:|---:|
| Marketplace | 1.45 | 4.62 | **+3.17** |
| InsideSales | 1.44 | 1.47 | +0.03 |
| Web | 1.54 | 1.54 | 0.00 |

Marketplace is therefore the strongest channel-level concentration of the deterioration.

### Business context

The retrieval tool returns:

> A manual promotional-code review step was introduced for Marketplace orders beginning July 1, 2024.

The system treats this as contextual evidence that strengthens a hypothesis, **not causal proof**.

## What-if scenario

Assumption:

> Reduce Q3 Order → Ship time by 25%.

Deterministic simulator result:

- modeled cash cycle: **33.58 → 33.06 days**
- modeled days saved: **0.52 days**
- modeled improvement: **1.56%**

The 25% reduction is an input assumption. The project does not claim that a particular operational intervention will necessarily achieve it.

## Risks / unknowns

The demo recommendation calls out that stronger evidence would include:

- affected-vs-unaffected order comparisons;
- review-queue timestamps;
- exception/rework data;
- a controlled or quasi-experimental pilot.

## Recommended next action

Pilot a targeted Marketplace order-release improvement, track Order → Ship time and exception rate, and compare the pilot cohort with an appropriate baseline before broad policy changes.

Implementation remains subject to human approval.

## Tool trace

The main demo uses the following real tool path:

1. `compare_stage_performance`
2. `analyze_process` — `order_to_ship_days`, grouped by `channel`
3. `retrieve_policy`
4. `simulate_stage_improvement`

The latest observed mock-mode run completed four tool turns and four tool calls in approximately tens of milliseconds inside CI. Mock latency is not representative of external-model latency.

## Presenter note

Recommended wording:

> The free demo scripts the model-side investigation path so it can run without API cost. The business data, SQL calculations, policy retrieval, Python scenario simulation, API, state, traces, and evaluation harness are live project components. The same business tools can be orchestrated through the optional OpenAI backend later for real-model evaluation.
