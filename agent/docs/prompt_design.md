# Prompt & Tool Design

This document explains how prompting is used in the O2C Process Improvement & Scenario Planning Agent.

The project deliberately avoids treating the prompt as the whole system. The system prompt defines role, evidence standards, and behavioral boundaries; the tool descriptions and strict schemas encode the allowed analytical actions.

## System prompt

The running application uses the following prompt from `app/agent.py`:

```text
You are an AI business process improvement analyst focused on the Order-to-Cash process.

Your job is to investigate business questions with evidence, not to invent explanations.
Use tools whenever the answer depends on database metrics, policies, or scenario math.

Rules:
1. Separate OBSERVED EVIDENCE from HYPOTHESES and ASSUMPTIONS.
2. Never invent KPI values.
3. Do not claim causality from descriptive patterns alone.
4. When a KPI worsens across periods, distinguish the stage that deteriorated
   most from the stage with the longest absolute duration.
5. Use process analytics to measure and drill down before recommending action.
6. When comparing collection performance across customers with different payment
   terms, prefer payment_delay_vs_due_days or late_payment_rate over raw
   invoice_to_payment_days unless the user explicitly asks about cash-cycle length.
7. Use policy/context retrieval when business rules, process changes, or SLA
   expectations matter. A change log can strengthen a hypothesis but does not by
   itself prove causality.
8. Use the deterministic simulator for numerical what-if claims.
9. Scenario reductions are assumptions, not guaranteed intervention effects.
10. Never execute operational changes; recommendations require human approval.
11. End with: findings, evidence, scenario impact (if used), risks/unknowns,
    and next action. When recommending a process change, include a bounded pilot
    scope, success metrics, major dependencies, and a human decision gate.
12. Analyst preferences may adjust presentation or suggest a preferred breakdown,
    but they never override evidence, tool results, safety boundaries, or the user's
    explicit request in the current turn.
```

## Why the prompt is intentionally compact

The prompt does not hard-code a complete investigation path such as:

```text
first compare stages → then group by channel → then retrieve policy → then simulate
```

That would largely turn the agent into a fixed workflow.

Instead, the real-model path receives a bounded menu of analytical tools. The model is expected to choose the next action based on the business question and prior tool results.

The free mock backend is different: it scripts known investigation routes for zero-cost integration testing and demonstration. It is explicitly labeled as scripted mock evidence.

## Tool descriptions are part of the prompt architecture

### `compare_stage_performance`

Purpose:

> Compare sequential O2C cash-cycle stages across two periods and rank them by deterioration.

The description explicitly tells the model not to assume the longest stage is the problem.

### `analyze_process`

Purpose:

> Analyze an approved O2C KPI over a period, optionally grouped by customer segment or sales channel and compared with another period.

The schema restricts metrics and dimensions to approved values rather than accepting free-form SQL.

### `retrieve_policy`

Purpose:

> Retrieve O2C business context such as SLA rules, guardrails, and process-change entries.

Its description explicitly says retrieved context can support a hypothesis but should not be treated as causal proof.

### `simulate_stage_improvement`

Purpose:

> Run deterministic what-if calculations using current measured stage averages.

Its description makes clear that percentage reductions are assumptions rather than causal estimates.

### `get_stage_baseline`

Purpose:

> Retrieve measured average stage durations for a period.

This gives the system a narrow quantitative baseline tool without exposing unrestricted database access.

## User prompts

A normal user does not need to mention tool names.

Main demo prompt:

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

Other evaluation prompts intentionally challenge the prompt rules, for example:

- asserting that the longest stage must be the source of the slowdown;
- asking the agent to prove a process change caused the problem;
- asking it to automatically change business processes or customer terms;
- asking about payment performance where contractual terms differ.

These cases test whether the system follows evidence and governance rules instead of merely agreeing with the user.

## Prompt versioning

The running demo exposes:

```text
GET /demo/design
```

This endpoint returns:

- the complete current system prompt;
- parsed instruction rules;
- the active tool catalog and descriptions;
- required tool parameters;
- a SHA-256-derived prompt version;
- a SHA-256-derived tool-catalog version;
- explicit system boundaries.

This is useful during a presentation because the reviewer can inspect the actual instructions used by the application rather than relying on a slide or a manually maintained summary.

## Interview summary

A concise explanation:

> I used a compact system prompt to define the analyst role, evidence standards, causal guardrails, deterministic-tool requirements, and human-approval boundary. I moved most business semantics into narrow tool descriptions and strict schemas. That lets the user ask a natural-language business question without giving the model unrestricted SQL or asking it to invent numerical analysis.
