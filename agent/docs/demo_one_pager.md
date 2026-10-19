# O2C Process Improvement Agent — Demo One-Pager

## Business problem

A dashboard can show that Order-to-Cash performance deteriorated, but a human analyst still has to decide:

- which process stage changed;
- where the deterioration is concentrated;
- which business context matters;
- what improvement to test;
- whether the evidence supports a causal claim;
- what should happen next.

This project turns that investigation into a bounded, traceable workflow.

## Main demo question

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

## Architecture

```text
Business user
     |
     v
FastAPI analyst UI
     |
     v
Model / orchestration boundary
(mock for free demo; OpenAI optional)
     |
     +-------------------+-------------------+-------------------+
     |                   |                   |                   |
     v                   v                   v                   v
Stage comparison    KPI drill-down      Context retrieval   Scenario simulator
MySQL / SQL         MySQL / SQL         Local docs          Python
     |                   |                   |                   |
     +-------------------+-------------------+-------------------+
                         |
                         v
             Evidence-backed recommendation
                         |
                         v
                  Human approval
```

## Validated Scenario V1 result

| Evidence | Q2 | Q3 | Change |
|---|---:|---:|---:|
| Total O2C cycle | 33.28 d | 33.71 d | +0.43 d |
| Order → Ship | 1.48 d | 2.09 d | **+0.61 d** |
| Ship → Invoice | 1.00 d | 1.00 d | 0.00 d |
| Invoice → Payment | 30.76 d | 30.49 d | -0.27 d |
| Marketplace Order → Ship | 1.45 d | 4.62 d | **+3.17 d** |

The benchmark intentionally keeps Invoice → Payment as the longest absolute stage while Order → Ship is the stage that deteriorates most.

## Retrieved business context

A manual Marketplace promotional-code review step was introduced on July 1, 2024.

The system treats that timing as relevant context, not proof of causality.

## Scenario

What if Q3 Order → Ship improves by 25%?

- modeled cash cycle: 33.58 → 33.06 days;
- modeled savings: 0.52 days;
- modeled improvement: 1.56%.

The 25% reduction is an assumption, not a guaranteed intervention effect.

## Recommended action

Run a targeted Marketplace order-release pilot, track Order → Ship time and exception rate, and compare an appropriate pilot/control or affected/unaffected cohort before broad rollout.

## Controls

- no free-form model-generated SQL;
- whitelisted metrics/dimensions;
- deterministic scenario calculations;
- evidence / hypothesis / assumption separation;
- due-date-normalized collections metrics;
- no operational write tools;
- human approval required for implementation;
- bounded session/preferences state;
- inspectable tool trace.

## Evaluation

Free integration path:

- 7 scripted behavior cases;
- deterministic tool/argument checks;
- controlled Scenario V1 calibration;
- Docker/API/UI smoke tests;
- dedicated end-to-end portfolio demo smoke test.

Real-model path remains optional and uses the same tools/cases through `MODEL_BACKEND=openai`.

## How to run

```bash
git checkout feature/process-improvement-agent
bash agent/scripts/start_demo.sh --open
```

Then choose **Full diagnosis** → **Run investigation**.
