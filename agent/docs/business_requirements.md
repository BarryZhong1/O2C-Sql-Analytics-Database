# Agent Business Requirements & Acceptance Criteria

## 1. Problem statement

The existing Order-to-Cash database provides transactional and analytical data, but a business analyst still has to manually decide which metric changed, where to drill down, which operating context matters, and how to evaluate an improvement option.

The agent layer should reduce that investigation effort without giving a language model unrestricted database or operational access.

## 2. Primary users

### Business analyst / operations analyst

Needs to investigate O2C deterioration, compare periods, isolate drivers, and communicate evidence-backed recommendations.

### Operations manager

Needs a concise explanation of what changed, expected impact of a proposed improvement, risks, and a next action.

### Solution / technical reviewer

Needs to inspect the tool path, prompt rules, database boundaries, API behavior, and evaluation evidence.

## 3. Business goals

1. Diagnose a meaningful O2C deterioration from a natural-language business question.
2. Keep quantitative calculations deterministic and auditable.
3. Distinguish observed evidence from hypotheses and assumptions.
4. Prevent causal overclaiming when only descriptive data is available.
5. Evaluate transparent what-if scenarios.
6. Keep execution of operational or policy changes under human approval.
7. Produce a demonstrable, reproducible portfolio workflow.

## 4. Functional requirements

### FR-01 — Natural-language investigation

The user can submit an O2C business question without knowing SQL or tool names.

**Acceptance criteria**

- `POST /agent/ask` accepts a natural-language question.
- The main portfolio prompt completes through the configured model backend.
- The response includes an answer and inspectable tool trace.

### FR-02 — Process-stage comparison

The system can compare sequential O2C cash-cycle stages across two periods.

**Acceptance criteria**

- Order → Ship, Ship → Invoice, and Invoice → Payment are measured.
- Results include period values and absolute/percentage change.
- Stages are ranked by deterioration rather than absolute duration.

### FR-03 — Business-driver drill-down

The system can analyze approved KPIs by an approved business dimension.

**Acceptance criteria**

- Supported dimensions include channel and customer segment.
- Grouped comparisons calculate changes outside the LLM.
- The Scenario V1 demo identifies Marketplace as the strongest channel-level Order → Ship deterioration.

### FR-04 — Business-context retrieval

The system can retrieve relevant local operating context.

**Acceptance criteria**

- Context retrieval returns source, heading, paragraph, and ranking score.
- Heading-only blocks are not returned as useful evidence.
- Process-change timing is described as context/hypothesis support rather than causal proof.

### FR-05 — Scenario planning

The system can quantify a transparent stage-improvement assumption.

**Acceptance criteria**

- Scenario math runs in deterministic Python.
- Reduction percentages are bounded from 0% to 100%.
- Baseline, scenario value, days saved, and percent improvement are returned.
- Output states that the reduction is an assumption rather than a guaranteed intervention effect.

### FR-06 — Approval boundary

The system must not execute operational changes.

**Acceptance criteria**

- No tool writes to orders, invoices, customer terms, process controls, or other operational data.
- Requests to automatically change the process or customer terms are refused.
- Recommendations explicitly require human approval.

### FR-07 — Stateful follow-up

A user can continue an investigation in the same session.

**Acceptance criteria**

- A session stores the latest response lineage ID.
- A follow-up request references the previous response.
- In free mock mode, the causal follow-up reuses prior structured investigation evidence without redundant analytical calls.
- The user can reset the session.

### FR-08 — Bounded analyst preferences

A user can persist presentation preferences without creating unrestricted memory.

**Acceptance criteria**

Only the following keys are allowed:

- detail level;
- preferred breakdown;
- include risks;
- include scenario when relevant.

Unknown keys are rejected, and preferences cannot override evidence or approval rules.

### FR-09 — Traceability

The system exposes the analytical actions taken.

**Acceptance criteria**

- Tool name, arguments, result, turn, and latency are recorded.
- The UI can show a business-friendly tool path and raw trace.
- Deterministic trace evaluation can verify expected tool use.

### FR-10 — Prompt/tool transparency

A technical reviewer can inspect the actual running prompt and tool catalog.

**Acceptance criteria**

- `GET /demo/design` returns the complete system prompt.
- Parsed prompt rules and all approved tool descriptions are returned.
- Prompt and tool-catalog version hashes are returned.
- The UI exposes this information in a technical panel.

### FR-11 — Demo readiness

The system can confirm whether the portfolio demo is ready before presentation.

**Acceptance criteria**

- `GET /demo/status` reports database connectivity, order count, Scenario V1 status, backend, and benchmark summary.
- The UI displays readiness indicators.
- The one-command launcher fails clearly when Docker or setup is unavailable.

### FR-12 — Portable output

A completed investigation can be exported.

**Acceptance criteria**

- The browser can download a Markdown report.
- CI can produce a Markdown demo artifact from the same API response.
- The report includes KPI evidence, tool path, scenario output, governance note, and mock-vs-real disclosure.

## 5. Non-functional requirements

### NFR-01 — Reproducibility

A clean local setup must rebuild the same controlled Scenario V1 benchmark.

### NFR-02 — Auditability

Numerical conclusions must trace to SQL/Python tools rather than hidden model arithmetic.

### NFR-03 — Safety / governance

The application must remain read-only for operational systems.

### NFR-04 — Cost control

The default demo and integration evaluation must run without paid model API usage.

### NFR-05 — Replaceable model boundary

Switching from mock to OpenAI must not require rewriting the business tools or UI.

### NFR-06 — Deployment portability

The demo must run with Docker Compose on a standard developer workstation.

### NFR-07 — Honest reporting

Mock integration evidence must be labeled separately from real-model behavioral evidence.

## 6. Key acceptance benchmark

Controlled Scenario V1 should reproduce approximately:

| KPI | Q2 2024 | Q3 2024 | Expected interpretation |
|---|---:|---:|---|
| Total O2C cycle | 33.28 d | 33.71 d | overall deterioration |
| Order → Ship | 1.48 d | 2.09 d | largest stage deterioration |
| Ship → Invoice | 1.00 d | 1.00 d | stable |
| Invoice → Payment | 30.76 d | 30.49 d | longest stage but slightly improved |
| Marketplace Order → Ship | 1.45 d | 4.62 d | strongest channel concentration |

The benchmark is intentionally designed to catch the analytical shortcut of selecting the longest absolute stage instead of the stage that actually worsened.

## 7. Definition of done for portfolio MVP

The portfolio MVP is considered functionally complete when:

- the one-command local demo starts successfully;
- Scenario V1 readiness is confirmed;
- the main four-tool demo path completes;
- stateful causal follow-up works;
- the Markdown report can be generated;
- unit tests pass;
- Docker/API/UI smoke tests pass;
- all seven scripted integration evaluation cases pass deterministic trace checks;
- the documentation clearly distinguishes mock integration evidence from optional real-model evidence.
