# Process Improvement Case: AS-IS → TO-BE

## Business case

Scenario V1 represents a Q3 2024 deterioration in the Order-to-Cash process concentrated in Marketplace fulfillment.

The objective is not merely to identify a slow KPI. The project demonstrates a structured process-improvement lifecycle:

**current state → bottleneck diagnosis → contextual hypothesis → intervention scenario → pilot plan → success metrics → human decision gate**

## AS-IS process

```text
Customer order
    ↓
Order validation / release
    ↓
Shipment
    ↓
Invoice
    ↓
Payment
```

Observed Q3 issue:

- total O2C cycle increases from 33.28 to 33.71 days;
- Order → Ship increases from 1.48 to 2.09 days;
- Marketplace Order → Ship increases from 1.45 to 4.62 days;
- Invoice → Payment remains the longest absolute stage but improves slightly.

A process-change log records a manual Marketplace promotional-code review step beginning July 1, 2024.

## Root-cause framing

### Observed evidence

- period-over-period stage deterioration;
- channel-level concentration in Marketplace;
- documented timing of a new review step.

### Hypothesis

The Marketplace promotional-review workflow may be contributing to order-release delay.

### What is not yet proven

The available descriptive evidence does not establish that the new review step caused the slowdown.

Potential confounders include:

- changing order mix;
- staffing/capacity changes;
- exception rate;
- incomplete documentation;
- concurrent process changes;
- promotional volume.

## TO-BE concept

A plausible future-state intervention is a more targeted Marketplace order-release workflow.

```text
Marketplace order
    ↓
Pre-validation / rules check
    ↓
┌─────────────────────┐
│ Standard case       │──→ accelerated release
└─────────────────────┘
           |
           └──── exception / high-risk case
                         ↓
                  manual review queue
                         ↓
                      release
```

This is a proposed process concept, not an implemented production change.

## Scenario tested

The deterministic simulator tests:

> What if Q3 Order → Ship time were reduced by 25%?

Modeled result:

- cash-cycle baseline: 33.58 days;
- scenario: 33.06 days;
- days saved: 0.52;
- modeled improvement: 1.56%.

The simulator does not claim that pre-validation will necessarily produce a 25% reduction. The reduction is an explicit planning assumption.

## Pilot plan

### Scope

Marketplace order-release / promotional-review workflow.

### Candidate intervention

Route standard cases through pre-validation and reserve manual review for exceptions or higher-risk cases.

### Primary success metrics

- Order → Ship duration;
- on-time ship rate;
- exception/rework rate;
- Marketplace SLA attainment;
- total O2C cycle time.

### Guardrail metrics

- incorrect release / false-negative exception rate;
- downstream cancellation/return anomalies;
- compliance exceptions;
- manual-review backlog.

### Dependencies

- review-queue timestamps;
- exception reason coding;
- reliable affected/control cohort definition;
- process-owner agreement on pilot rules;
- technical implementation of the pre-validation step.

### Decision gate

Do not roll out broadly until pilot evidence is reviewed by the process owner and relevant stakeholders.

## Measurement approach

Preferred evidence hierarchy:

1. controlled pilot with comparable treatment/control cohorts;
2. quasi-experimental affected-vs-unaffected comparison;
3. queue-level timestamp and exception analysis;
4. descriptive before/after timing alone.

The project explicitly avoids treating level 4 as sufficient causal proof.

## Stakeholders

| Stakeholder | Interest / responsibility |
|---|---|
| Operations manager | O2C speed and SLA performance |
| Marketplace operations | order-release workflow |
| Finance / AR | end-to-end cash-cycle impact |
| Compliance / policy owner | review requirements |
| Data / analytics | KPI measurement and evaluation |
| Engineering / systems | implementation and instrumentation |

## Implementation risks

| Risk | Mitigation |
|---|---|
| Faster release increases exceptions | pilot + guardrail metrics |
| Correlation mistaken for causation | controlled comparison / pilot |
| Scenario benefits overstated | label reductions as assumptions |
| KPI definition drift | deterministic tool definitions |
| Agent recommends unauthorized action | human-approval boundary |
| Model invents numbers | SQL/Python tool grounding |

## Portfolio interpretation

This case is designed to show more than analytics.

It demonstrates:

- AS-IS process understanding;
- KPI definition;
- root-cause framing;
- evidence vs hypothesis separation;
- TO-BE process design;
- scenario planning;
- requirements/dependencies;
- pilot planning;
- success metrics;
- risk management;
- governance and approval gates.
