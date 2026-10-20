# Data Readiness Review for the Agent Project

## Purpose

Review the existing O2C synthetic-data design specifically for the AI Process Improvement & Scenario Planning Agent.

This is not a full audit of the original database project. The goal is to determine whether the current data can support a convincing, reproducible agent investigation.

## Overall assessment

**Current suitability: 6.5/10 for an agent demo without modification.**

The database is a strong structural foundation: it has a full O2C chain, useful analytical views, multiple customer segments/channels, and enough synthetic orders for portfolio-scale analysis.

However, the existing generator was designed for broad BI realism, not for controlled process-improvement evaluation. Most process times are random within fixed ranges and are not tied to a deliberate business event. As a result, an agent may find patterns, but we would not know whether it found a real injected mechanism or random noise.

A controlled scenario overlay is therefore recommended.

## What is already strong

### End-to-end process coverage

The schema supports:
- customers;
- orders;
- order items;
- shipments;
- invoices;
- payments;
- returns;
- inventory.

This is enough to tell an end-to-end business-process story rather than a single-table analytics story.

### Useful process timestamps

The current operational view exposes:
- order timestamp;
- shipment timestamp;
- delivery timestamp;
- invoice timestamp;
- first payment timestamp.

It also calculates:
- order-to-ship;
- ship-to-delivery;
- ship-to-invoice;
- invoice-to-payment;
- total O2C cycle time.

This is a strong starting point for bottleneck analysis.

### Natural business dimensions

The existing view already includes:
- customer segment;
- sales channel.

Those two dimensions are enough for Scenario V1.

## Gaps that matter for the agent project

### 1. No known period-specific deterioration

Shipment processing time is generated from a common random 1–3 day range.

Payment behavior is also generated from a common probability structure around the invoice due date.

There is no deliberate event such as:
- a channel backlog;
- a policy change;
- a warehouse-capacity issue;
- a billing migration;
- a collections breakdown.

Therefore Q2-vs-Q3 differences are currently driven mainly by random variation and composition effects.

**Recommendation:** use a separate deterministic scenario overlay.

### 2. Raw invoice-to-payment time can be misleading

Customers have different payment terms such as Net15, Net30, and Net45.

Therefore a segment can have a longer invoice-to-payment interval while still paying according to contract.

For process diagnosis, the project should eventually distinguish:
- invoice-to-payment duration;
- payment delay relative to due date.

This is important for avoiding the false conclusion that longer contractual terms represent poor collections performance.

**MVP decision:** retain invoice-to-payment for the cash-cycle model, but use policy context and add a due-date-relative metric before making collections-focused recommendations.

### 3. Current view has limited operational drill-down

The operational view currently supports segment and channel but does not expose several fields useful for later diagnosis, including:
- ship-from warehouse;
- carrier;
- region;
- product/category.

These would improve later versions but are not required for the first controlled scenario.

**Recommendation:** do not expand the dimensional model until Scenario V1 is validated.

### 4. The random date-generation logic is not a controlled benchmark

The generator uses multiple independent RAND() calls inside the date-selection CASE expression.

This produces broad seasonal variation but not a precise, reproducible percentage by period.

That is acceptable for general BI sample data, but weak for evaluating whether an agent reliably detects a known change.

**Recommendation:** inject the benchmark after generation rather than trying to make the entire base generator deterministic.

### 5. Historical AR metrics should avoid current-date dependence

The cash-flow view uses CURDATE() for days-past-due and aging buckets.

Because the synthetic transactions are historical, running the project years later can make all open invoices appear extremely old.

**Recommendation:** for reproducible demo/eval cases, calculate aging relative to an explicit as-of date rather than wall-clock current date.

### 6. Existing generator contains items outside the immediate agent scope

During review, one return-generation INSERT appears to pass the returned product ID into the first column where the order ID is expected.

This should be verified separately before relying on return analytics.

It does not block Scenario V1 because the first agent demo does not depend on return data.

**Recommendation:** log as a base-data cleanup item rather than expanding the current feature scope.

## Recommended data strategy

Do not rewrite the original generator yet.

Use a layered design:

```text
Base synthetic O2C dataset
          |
          v
Controlled scenario overlay
          |
          v
Known ground truth
          |
          +----> fixed workflow baseline
          |
          +----> agent investigation
          |
          +----> evaluation
```

This gives the project both:
- realistic background variability;
- known benchmark conditions.

## Scenario V1 recommendation

Use the Marketplace fulfillment bottleneck defined in `business_scenario_v1.md`.

Primary signal:
- Q3 Marketplace order-to-ship delay.

Secondary confounder:
- smaller Q3 Enterprise payment delay.

This is preferable to a pure collections scenario for the first demo because:
- the operational mechanism is easier to explain;
- the existing view already supports channel drill-down;
- payment-term differences do not dominate the main finding;
- scenario planning can directly test order-to-ship improvements.

## Evaluation implication

A strong agent should not merely identify the stage with the largest absolute duration.

It should identify the stage with the largest **period deterioration** and then find the affected subgroup.

This distinction should become a core evaluation case.

## Recommended next build step

Before adding memory or more agent tools:

1. implement the deterministic Scenario V1 SQL overlay;
2. create a reset/rebuild procedure;
3. add period/stage/channel validation queries;
4. record actual post-injection benchmark values;
5. update eval expectations using measured values;
6. only then tune Agent v1.

This keeps evaluation grounded in data rather than in expected narratives.
