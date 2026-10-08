# Five-Minute Demo Script

## Demo goal

Show that the project is not a generic chatbot. It is a bounded business-analysis system that investigates an O2C process problem, chooses approved analytical tools, distinguishes evidence from hypothesis, models an improvement scenario, and leaves execution to a human decision-maker.

## Before recording

1. Run `bash agent/scripts/start_demo.sh` from the repository root.
2. Confirm the script reports that the API is healthy.
3. Open `http://localhost:8000/`.
4. Confirm the banner says **Free demo mode** / `mock` backend.
5. Click the **Full diagnosis** preset.

No OpenAI API key is required for this default presentation path.

Recommended demo prompt:

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, check relevant process context, and test a realistic improvement scenario.

## 0:00-0:40 — Business problem

Explain:

- The underlying repository is an end-to-end Order-to-Cash analytical database.
- A normal dashboard can show metrics, but an analyst still has to decide what changed, where to drill down, which process rule matters, and which scenario to test.
- This project adds an AI investigation layer while keeping quantitative calculations in deterministic SQL/Python tools.

Show the analyst UI and the read-only / scenario-planning / human-approval tags.

## 0:40-1:20 — Architecture

Briefly explain the flow:

```text
Business question
      ↓
Model/orchestration boundary
(mock for free demo; Responses API optional)
      ↓
Approved tools
  ├─ process analytics / MySQL
  ├─ business-context retrieval
  └─ deterministic scenario simulator
      ↓
Evidence-backed recommendation
      ↓
Human approval
```

Call out two design choices:

1. No model-generated SQL is executed directly.
2. The agent has no write tools for customer terms, orders, invoices, or process controls.

## 1:20-2:50 — Run the investigation

Click **Full diagnosis** and then **Run investigation**.

For the free demo, say explicitly that the investigation path at the model boundary is scripted, while the SQL queries, database values, retrieval results, scenario calculations, traces, API, and UI are real project components.

While the investigation runs, explain the hidden evaluation design without revealing hidden answers to the agent:

- Scenario V1 is a controlled synthetic overlay.
- The benchmark deliberately keeps invoice-to-payment as the longest absolute stage while another stage deteriorates more.
- This tests whether the agent reasons from period change rather than taking a longest-stage shortcut.

When the response returns, highlight:

- the identified deteriorating stage;
- the channel/segment drill-down;
- process-context retrieval if used;
- the modeled scenario impact;
- explicit uncertainty/causal wording;
- the recommended next human action.

## 2:50-3:35 — Show the trace

Expand **Inspect tool trace**.

Point out:

- tool calls are visible;
- arguments are bounded and inspectable;
- quantitative results come from tools rather than free-form model arithmetic;
- the trace can be evaluated automatically.

In mock mode, do **not** claim the path itself is emergent or agentic: it is scripted for zero-cost demonstration. Instead, explain that the same bounded tool loop can be switched to the OpenAI backend for unscripted tool selection without changing the business tools.

## 3:35-4:10 — State and memory

Show a follow-up question in the same session, for example:

> What evidence would I need before claiming the process change caused the Marketplace slowdown?

Explain:

- the state layer preserves response lineage/session continuity across the model-backend abstraction;
- in the real OpenAI backend, short-term continuity uses the Responses API `previous_response_id`;
- local state stores response IDs/timestamps rather than duplicating the raw O2C transcript;
- long-term memory is deliberately bounded to explicit analyst preferences such as detail level and preferred breakdown;
- preferences cannot override evidence or approval boundaries.

## 4:10-4:45 — Evaluation

Show the evaluation files or GitHub Actions page.

Explain the layered evaluation strategy:

1. deterministic Scenario V1 calibration;
2. deterministic trace/tool checks across seven behavior cases;
3. semantic rubric for evidence grounding, causal discipline, assumptions, decision usefulness, risks, and approval boundaries;
4. optional LLM-as-Judge for semantic criteria only.

Emphasize that deterministic checks remain authoritative for numerical/tool facts.

## 4:45-5:00 — Close

Suggested closing:

> The project moves an O2C database from descriptive reporting to a deployable AI-assisted investigation workflow. The model decides which approved analytical step to take next, but the system keeps calculations auditable, memory bounded, behavior evaluated, and business execution under human approval.

## Demo reliability / backup path

The recommended presentation already uses the local mock backend, so it does not depend on external model availability. If the local UI fails, use this fallback:

1. show the validated Scenario V1 benchmark;
2. show the latest `Agent mocked behavior evals` GitHub Actions run;
3. show its 7/7 deterministic trace pass result;
4. walk through the stored trace/evaluation summary;
5. show the fixed workflow endpoint as an additional deterministic baseline.

This keeps the demonstration honest: mocked integration evidence is not presented as real-model reasoning evidence.

## Interview follow-up talking points

Be ready to explain:

- why a fixed workflow baseline was built before the agent;
- why longest absolute stage and largest deterioration are different business questions;
- why payment-delay analysis is normalized to contractual due dates;
- why process-change timing is not causal proof;
- why deterministic scenario math is separated from LLM reasoning;
- why long-term memory is whitelisted rather than unrestricted;
- why multi-agent orchestration was not added without a real coordination need;
- how live eval failures would drive prompt/tool revisions.


See `docs/demo_quickstart.md` for the exact zero-cost startup commands and presenter wording.
