# Demo Interview Q&A

Use this as presenter preparation for the O2C Process Improvement & Scenario Planning Agent.

## 30-second project explanation

> I extended an Order-to-Cash analytics database into a bounded process-improvement agent. A business user can ask why a KPI deteriorated, the system can compare process stages, drill into a segment or channel, retrieve operating context, run transparent what-if scenarios, and return a recommendation. Quantitative calculations remain in SQL/Python tools, and operational changes stay behind human approval.

## What instructions did you give the agent?

> I used a compact system prompt that defines the role, evidence standards, causal guardrails, tool-use expectations, and human-approval boundary. I deliberately avoided a long fixed "first A, then B, then C" reasoning script. Instead, I put business semantics into narrow tool descriptions and strict schemas so the model has bounded actions.

Key instruction themes:

- act as an O2C process-improvement analyst;
- use tools for KPI values, policies, and scenario calculations;
- never invent KPI values;
- distinguish observed evidence, hypotheses, and assumptions;
- do not claim causality from descriptive timing alone;
- distinguish the stage that deteriorated most from the stage with the longest absolute duration;
- normalize collections analysis against contractual due dates when appropriate;
- use deterministic Python for what-if calculations;
- do not execute operational changes;
- end with findings, evidence, scenario impact, risks/unknowns, and next action; for process changes, include pilot scope, success metrics, dependencies, and a human decision gate.

## What does a user prompt look like?

The main demo prompt is intentionally natural language:

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

The user does not need to know SQL, tool names, or which KPI drill-down to call.

## Why not just put all the steps in the prompt?

> If I hard-coded every step in the prompt, the system would mostly be a workflow disguised as an agent. I wanted a fixed workflow baseline for comparison, but the real model path is designed to choose among bounded tools based on the question and tool results.

For the **free portfolio demo**, be precise:

> The mock backend does use a scripted investigation path so I can demonstrate the full system without API cost. I do not present that as emergent model reasoning. The OpenAI backend uses the same system prompt, tool schemas, database, and evaluation cases for unscripted tool selection when API access is available.

## What tools are available?

### compare_stage_performance

Compares sequential cash-cycle stages across two periods and ranks them by deterioration.

Why it exists:

> The longest stage is not necessarily the stage responsible for a recent slowdown.

### analyze_process

Queries approved KPIs over a date range and can group them by customer segment or sales channel.

The metric and dimension values are whitelisted. The model cannot send arbitrary SQL.

### retrieve_policy

Retrieves local O2C business context such as SLA rules, approval boundaries, and process-change entries.

Important guardrail:

> Retrieved timing/context can support a hypothesis but does not prove causality.

### simulate_stage_improvement

Runs deterministic Python what-if calculations using measured stage baselines.

Important guardrail:

> A 25% reduction is an assumption for scenario planning, not a causal forecast or guaranteed intervention effect.

### get_stage_baseline

Returns measured average stage durations for a requested period.

## Why no model-generated SQL?

> I wanted business questions to be flexible without giving the model unrestricted database access. The tool layer maps a controlled metric/dimension vocabulary to parameterized SQL. That improves auditability and reduces both correctness and security risks.

## How do you prevent hallucinated business numbers?

> The system prompt forbids invented KPI values, and numerical claims should come from tool outputs. I also evaluate traces deterministically, so I can verify that required calculations came from the expected tool with the expected arguments.

## How do you handle causality?

> The agent separates observation from hypothesis. For example, the benchmark contains a Marketplace slowdown and a July process change. The change log is relevant context, but temporal alignment alone is not treated as proof. The recommended follow-up is to compare affected and unaffected cohorts, inspect queue/exception data, or run a controlled pilot.

## Why normalize payments against due dates?

> Enterprise, Mid-market, and SMB customers can have different contractual payment terms. Raw invoice-to-payment duration can therefore make a compliant Net45 customer look worse than a Net15 customer. When the question is collection performance, I use payment delay relative to the due date or late-payment rate instead.

## What is mocked and what is real in the free demo?

### Scripted

- the model-side selection of the known demo investigation path;
- the final mock-mode narrative template.

### Real project components

- MySQL O2C database;
- controlled Scenario V1 overlay;
- parameterized analytical queries;
- KPI and period-change calculations;
- local business-context retrieval;
- deterministic scenario simulator;
- FastAPI service;
- state/session layer;
- bounded preferences;
- tool trace;
- evaluation harness;
- Docker deployment;
- UI.

Recommended phrasing:

> The mock is at the model boundary, not at the database or analytical-tool layer.

## How does the stateful follow-up work?

> The application stores the latest response lineage ID per session. In the free mock demo, the scripted causal follow-up can retrieve the prior structured tool results associated with that response ID and answer without rerunning the analytical chain. In real OpenAI mode, the same session endpoint passes the previous response ID back to the Responses API for conversational continuity.

The local state database stores lineage metadata rather than duplicating the raw O2C transcript.

## How would real API mode differ?

> I switch `MODEL_BACKEND=mock` to `MODEL_BACKEND=openai` and provide an API key. The UI and business tools do not change. The real model receives the same system instructions and tool schemas, then chooses tool calls through the Responses API.

## How did you evaluate it?

There are several layers:

1. controlled synthetic business benchmark with known injected conditions;
2. deterministic data calibration;
3. seven behavior cases with expected tool calls/arguments;
4. deterministic trace evaluation;
5. semantic rubric for grounding, diagnosis, causal discipline, assumptions, decision usefulness, risks, and approval boundaries;
6. optional LLM-as-Judge only for semantic criteria;
7. Docker/API/UI/demo smoke tests.

Do not say the mock 7/7 pass means the LLM itself has 100% reasoning accuracy.

Correct phrasing:

> The free mocked suite has a 100% deterministic trace pass rate across seven scripted integration cases. Real-model semantic performance remains a separate optional validation.

## Why not use multiple agents?

> I did not add multi-agent orchestration just to make the architecture look more complex. The current problem has one clear investigator/orchestrator and a small set of bounded tools. I would only introduce multiple agents if there were genuinely separable responsibilities with coordination value, such as independent financial, operational, and compliance analyses.

## What would you build next?

Strong answer:

> I would first use real-model evaluation failures to decide what to change rather than adding features blindly. After that, I would expand the scenario engine from abstract percentage reductions to intervention-based assumptions such as automation coverage, exception rate, implementation cost, and capacity impact.

## One-minute demo narration

> Management sees O2C cycle time deteriorate from Q2 to Q3. I submit that business question without specifying SQL or a tool path. In the free demo the routing is scripted, but all analytical outputs are live. The system first compares stage changes rather than simply selecting the longest stage. It finds Order-to-Ship deteriorated most, drills down and finds Marketplace is concentrated, retrieves the July Marketplace review change as context, and then uses deterministic Python to model a 25% Order-to-Ship improvement. The final recommendation labels the scenario as an assumption, preserves causal uncertainty, and proposes a human-approved pilot. I can expand the trace to show every tool call and its arguments.
