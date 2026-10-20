# Scenario V1 Benchmark — Validated Results

## Status

**Validated and reproducible.**

Scenario V1 was run from a clean MySQL setup twice in GitHub Actions and produced the same benchmark metrics in both runs:

- Run `37421942102`
- Run `37422033397`

This benchmark is the reference for Workflow v1 and future Agent v1 evaluation.

## Business question

> O2C cycle time worsened in Q3 versus Q2. Investigate where the deterioration occurred, identify the strongest operational driver, and compare improvement scenarios.

## Aggregate result

| Metric | Q2 2024 | Q3 2024 | Change |
|---|---:|---:|---:|
| Records | 200 | 280 | — |
| Total O2C cycle | 33.28 d | 33.71 d | **+0.43 d** |
| Order → Ship | 1.48 d | 2.09 d | **+0.61 d (+41.22%)** |
| Ship → Invoice | 1.00 d | 1.00 d | 0.00 d |
| Invoice → Payment | 30.76 d | 30.49 d | -0.27 d |

The aggregate deterioration is intentionally modest. A useful investigator must compare stages instead of selecting the longest absolute stage.

## Channel drill-down

| Channel | Q2 Order → Ship | Q3 Order → Ship | Change |
|---|---:|---:|---:|
| Marketplace | 1.45 d | **4.62 d** | **+3.17 d** |
| Web | 1.54 d | 1.54 d | 0.00 d |
| InsideSales | 1.44 d | 1.47 d | +0.03 d |

Marketplace is the clear concentrated operational signal.

## Injected cohorts

- Primary affected cohort: **40 of 52 Q3 Marketplace orders** (76.92%).
- Primary injection: +4 days to shipment timing, with downstream dates shifted together to preserve chronology.
- Secondary confounder: **8 Q3 Enterprise paid invoices** receive +2 days payment delay.

The secondary injection does not need to make the aggregate invoice-to-payment KPI worse. It adds background complexity without dominating the primary fulfillment signal.

## Fixed Workflow v1 result

The fixed workflow correctly selects `order_to_ship_days` as the candidate bottleneck.

Its illustrative scenario applies a 20% reduction to Q3 order-to-ship duration:

| Scenario metric | Value |
|---|---:|
| Modeled baseline cash cycle | 33.58 d |
| Modeled scenario cash cycle | 33.16 d |
| Modeled days saved | **0.42 d** |
| Modeled improvement | **1.24%** |

This is a what-if calculation, not a causal forecast.

## Why this benchmark is useful

The benchmark is intentionally **strong but non-trivial**:

1. Total O2C worsens only modestly (+0.43 days).
2. The longest absolute stage, invoice-to-payment, actually improves slightly.
3. The stage that deteriorates most is order-to-ship.
4. The deterioration becomes obvious only after a channel drill-down.
5. Marketplace changes sharply while Web and InsideSales remain essentially flat.

This tests whether the agent can distinguish absolute duration from deterioration, company-wide performance from subgroup concentration, evidence from causal explanation, and measured impact from scenario assumptions.

## Reproducibility

The synthetic generator now uses valid customer IDs and deterministic benchmark-critical timing/mix logic. Two clean CI runs produced identical metrics.

Machine-readable values are stored in `agent/evals/scenario_v1_benchmark.json`.

## Next evaluation milestone

Freeze this benchmark and evaluate Agent v1 against it:
- choose stage comparison before recommending a fix;
- select a useful channel drill-down;
- identify Marketplace from tool results rather than hidden ground truth;
- avoid presenting the promotional-review hypothesis as proven cause;
- use the simulator for quantitative what-if claims.
