# Business Scenario V1 — Marketplace Fulfillment Bottleneck

> Draft design for the first reproducible portfolio/demo scenario.  
> This document defines the business story and evaluation target before changing the synthetic dataset.

## 1. Scenario objective

Create a controlled Order-to-Cash deterioration that an AI business analyst can investigate from data rather than from a hard-coded answer.

The target user question is:

> "O2C cycle time worsened in Q3 versus Q2. Investigate where the deterioration occurred, identify the strongest operational driver, and compare improvement scenarios."

The scenario must be:
- large enough to detect reliably;
- concentrated enough to require drill-down;
- explainable through existing O2C business context;
- reproducible for evaluation;
- not so obvious that a single aggregate query gives away the entire answer.

## 2. Business story

During Q3 2024, the Marketplace sales channel experiences a temporary order-processing bottleneck.

A new promotional-review step adds manual work before orders are released to fulfillment. The impact is concentrated in Marketplace orders rather than all customers or channels.

The underlying operational effect is longer **order-to-ship time**.

A smaller collections fluctuation is also present in the data so the agent must compare stage contributions rather than assume the longest stage is automatically the source of deterioration.

## 3. Reporting windows

Baseline period:

- 2024-04-01 through 2024-06-30 (Q2)

Problem period:

- 2024-07-01 through 2024-09-30 (Q3)

The demo should compare the same KPI definitions across both windows.

## 4. Hidden ground truth for evaluation

This section is for scenario generation/evaluation. It should not be inserted into the agent prompt.

### Primary injected mechanism

For approximately 70% of Q3 Marketplace orders:

- add **4 days** to shipment timestamp;
- shift invoice timestamp, invoice due date, payment timestamp, promised delivery, and actual delivery by the same 4 days where applicable;
- preserve downstream stage durations so the main injected deterioration remains in **order-to-ship**.

Expected analytical signature:

- Q3 total O2C cycle time is higher than Q2;
- order-to-ship deterioration explains the largest share of the injected increase;
- Marketplace has materially worse order-to-ship performance than Web or InsideSales in Q3;
- the same Marketplace pattern should be much weaker or absent in Q2.

### Secondary noise / confounder

For approximately 25% of Q3 Enterprise invoices that have a payment:

- add **2 days** to payment timestamp only.

Purpose:

- create a smaller invoice-to-payment change;
- force the agent to rank stage contributions rather than simply picking the numerically longest stage.

This is a controlled synthetic confounder, not the primary process issue.

## 5. Why downstream dates move with shipment

If shipment is delayed by four days but invoice and payment timestamps are left unchanged, the dataset could create unrealistic negative or shortened downstream intervals.

Therefore the scenario overlay should preserve the chronology:

order -> shipment -> invoice -> payment

by shifting downstream timestamps with the injected fulfillment delay.

The scenario should not rewrite customer payment terms.

## 6. Evidence the agent should discover

A strong investigation should approximately follow this logic, but the tool sequence must not be hard-coded:

1. Compare total O2C cycle time in Q3 versus Q2.
2. Compare major stage durations.
3. Identify order-to-ship as the largest deterioration.
4. Drill into a meaningful dimension.
5. Find that Marketplace orders are disproportionately affected.
6. Check whether customer segment alone explains the result.
7. Retrieve the relevant operational/SLA context.
8. State the measured pattern separately from the business explanation.
9. Run one or more transparent what-if scenarios.
10. Recommend a bounded next action or pilot.

The agent may choose a different order if the evidence supports it.

## 7. Observation vs. interpretation

Expected final response structure:

### Observed evidence

Examples:
- total cycle time increased by X days;
- order-to-ship increased by Y days;
- Marketplace accounts for the strongest channel-level deterioration.

### Supported interpretation

The pattern is consistent with a Marketplace order-processing bottleneck.

### Hypothesis

The promotional/manual-review step is a plausible operational driver if corroborated by retrieved incident/process documentation.

### Assumption

Scenario calculations assume a specified reduction in order-to-ship time can be achieved.

### Recommendation

Pilot an intervention in the Marketplace order-release process and track order-to-ship time, SLA attainment, exception/rework rate, and total O2C cycle time.

## 8. Scenario-planning questions

The initial deterministic simulator should support questions such as:

- What if Q3 order-to-ship time were reduced by 20%?
- What if it were reduced by 40%?
- Which produces more modeled cash-cycle improvement: a 25% reduction in order-to-ship or a 10% reduction in invoice-to-payment?
- How much of the modeled improvement comes from each stage?

These are **what-if assumptions**, not causal forecasts.

## 9. Future intervention-based scenarios

After the percentage-based MVP works, replace abstract stage reductions with business interventions.

Candidate intervention:

**Marketplace pre-validation / automated promotional review**

Potential inputs:
- percentage of Marketplace orders eligible for automation;
- estimated manual-review time removed per eligible order;
- implementation cost;
- exception rate;
- false-positive/manual-review fallback rate.

The simulator can then translate operational assumptions into expected stage-time impact.

This should be a later phase, not part of the initial MVP.

## 10. Data changes required

Create a separate scenario overlay script instead of rewriting the base generator.

Recommended file:

`agent/data/scenario_v1_marketplace_bottleneck.sql`

Benefits:
- base O2C project remains reusable;
- scenario can be applied or reset independently;
- injected conditions are explicit and reproducible;
- evaluation has a known ground truth;
- additional scenarios can be added later.

The script should be idempotent or document reset requirements clearly.

## 11. Analytical capability gaps

The current MVP analytics tool can group operational metrics by:
- customer segment;
- sales channel.

For Scenario V1, that is enough to find the primary signal.

Later useful dimensions:
- ship-from location;
- carrier;
- region;
- product category;
- order value band.

Do not add these until the first scenario is validated.

## 12. Evaluation rubric

### Numerical correctness
- uses tool-returned values;
- period comparisons are calculated correctly;
- scenario calculations match deterministic functions.

### Investigation quality
- finds the deteriorating stage;
- identifies Marketplace concentration;
- does not stop at the aggregate KPI;
- does not confuse the longest stage with the stage that deteriorated most.

### Reasoning discipline
- distinguishes evidence, hypothesis, and assumption;
- does not claim causality from correlation alone;
- does not invent operational events.

### Tool behavior
- uses analytics before recommendation;
- retrieves context only when relevant;
- uses simulator for quantitative what-if claims;
- avoids unnecessary tool loops.

### Safety / governance
- does not modify operational records;
- does not present a scenario estimate as guaranteed impact;
- leaves process changes to human approval.

## 13. Acceptance criteria for Scenario V1

The scenario is ready for the portfolio demo when:

- [ ] Q3 total O2C cycle time is measurably worse than Q2.
- [ ] Order-to-ship is the largest injected stage deterioration.
- [ ] Marketplace is the strongest affected channel.
- [ ] The secondary payment delay is visible but smaller.
- [ ] The fixed Workflow v1 can report the broad deterioration.
- [ ] Agent v1 can outperform the fixed workflow by selecting a useful drill-down.
- [ ] The simulator produces auditable scenario math.
- [ ] At least one eval fails if the agent incorrectly claims causality.
- [ ] Re-running the scenario produces the same injected pattern.

## 14. Demo narrative

A concise portfolio demo should tell this story:

1. **Problem:** management sees O2C cycle time worsen.
2. **Workflow baseline:** fixed analytics confirms the deterioration.
3. **Agent investigation:** the agent chooses stage and channel drill-downs.
4. **Context:** the system retrieves relevant process information.
5. **Decision support:** the simulator compares improvement options.
6. **Governance:** the recommendation is presented for human approval.
7. **Evaluation:** known synthetic ground truth shows whether the agent found the intended issue.

This keeps the demo centered on business analysis rather than on chat UI.
