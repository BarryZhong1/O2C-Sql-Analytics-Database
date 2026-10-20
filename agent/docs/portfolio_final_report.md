# AI Process Improvement & Scenario Planning Agent
## Portfolio MVP Report

## 1. Executive summary

This project extends an existing Order-to-Cash (O2C) analytics database into a bounded AI-assisted process-improvement system.

The application is designed to answer business questions such as:

> Why did O2C cycle time worsen in Q3 2024 versus Q2 2024, where is the deterioration concentrated, and what improvement scenario should we test?

The system combines:

- MySQL process analytics;
- a model/orchestration boundary;
- business-context retrieval;
- deterministic Python scenario simulation;
- bounded session state and analyst preferences;
- tool-level traces and evaluation;
- FastAPI + Docker deployment.

The free default demo uses a scripted mock backend at the model boundary. This allows end-to-end engineering validation without paid API usage while preserving an optional OpenAI Responses API path for later real-model testing.

## 2. Business problem

A traditional dashboard can surface a KPI change, but a human analyst still has to decide:

1. which process stage changed;
2. where the change is concentrated;
3. which business rules or process changes are relevant;
4. whether the evidence supports a causal claim;
5. which improvement scenario is worth evaluating;
6. what implementation/pilot plan should be recommended.

The project converts that manual investigation into a bounded, auditable workflow.

## 3. Solution architecture

```text
Business user
    ↓
FastAPI analyst UI
    ↓
Model / orchestration boundary
(mock by default; OpenAI optional)
    ↓
Approved tools
    ├── stage comparison / MySQL
    ├── KPI drill-down / MySQL
    ├── baseline lookup / MySQL
    ├── business-context retrieval / local Markdown
    └── scenario simulation / Python
    ↓
Evidence-backed recommendation
    ↓
Human approval
```

The LLM/model boundary does not receive unrestricted write access or free-form SQL execution.

## 4. Prompt and tool design

The system prompt defines the role as an O2C process-improvement analyst and enforces:

- evidence vs hypothesis vs assumption separation;
- no invented KPI values;
- no causal claims from descriptive patterns alone;
- deterioration vs absolute-duration distinction;
- due-date-normalized collections analysis;
- deterministic scenario math;
- human approval for operational changes.

The prompt intentionally does not hard-code a full reasoning sequence.

Instead, the analytical affordances are exposed through five strict tools:

1. `compare_stage_performance`
2. `analyze_process`
3. `get_stage_baseline`
4. `retrieve_policy`
5. `simulate_stage_improvement`

The running application exposes the actual prompt and tool catalog through `GET /demo/design`, including version hashes.

## 5. Controlled business benchmark

Scenario V1 creates a reproducible Q3 2024 Marketplace fulfillment deterioration.

| KPI | Q2 2024 | Q3 2024 | Change |
|---|---:|---:|---:|
| Total O2C cycle | 33.28 d | 33.71 d | +0.43 d |
| Order → Ship | 1.48 d | 2.09 d | **+0.61 d** |
| Ship → Invoice | 1.00 d | 1.00 d | 0.00 d |
| Invoice → Payment | 30.76 d | 30.49 d | -0.27 d |
| Marketplace Order → Ship | 1.45 d | 4.62 d | **+3.17 d** |

The benchmark deliberately makes Invoice → Payment the longest absolute stage while Order → Ship is the stage that deteriorates most.

This tests whether the system diagnoses change rather than taking a naïve "largest number = problem" shortcut.

## 6. Main demo investigation

The primary demo question is:

> Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario.

The scripted mock demo executes:

```text
compare_stage_performance
        ↓
analyze_process by channel
        ↓
retrieve_policy
        ↓
simulate_stage_improvement
        ↓
recommendation + implementation plan
```

### Findings

- overall O2C worsens from 33.28 to 33.71 days;
- Order → Ship is the stage with the largest deterioration;
- Marketplace is the strongest channel-level concentration;
- a July 1 Marketplace promotional-review process change is retrieved as relevant context;
- the change is treated as hypothesis-supporting context, not causal proof.

## 7. Scenario planning

Assumption:

> Reduce Q3 Order → Ship duration by 25%.

Deterministic Python result:

- modeled cash cycle: 33.58 → 33.06 days;
- modeled days saved: 0.52 days;
- modeled improvement: 1.56%.

The percentage reduction is explicitly labeled as a planning assumption.

## 8. Proposed implementation plan

### Scope

Marketplace order-release / promotional-review workflow.

### Pilot concept

Use pre-validation or rules-based routing for standard cases while reserving manual review for exceptions/higher-risk cases.

### Success metrics

- Order → Ship duration;
- on-time ship rate;
- exception/rework rate;
- Marketplace SLA attainment;
- total O2C cycle time.

### Dependencies

- review-queue timestamps;
- exception reason coding;
- affected/control cohort definition;
- process-owner agreement;
- implementation support.

### Decision gate

Broad rollout requires human review of pilot evidence.

## 9. Memory and state

### Short-term state

The application stores the latest response lineage ID per session.

In real OpenAI mode, this supports Responses API continuation.

In free mock mode, the scripted causal follow-up can reuse prior structured investigation results without rerunning redundant analytical tools.

### Bounded long-term preferences

Only explicit presentation preferences are persisted:

- detail level;
- preferred breakdown;
- include risks;
- include scenario if relevant.

These preferences cannot override data, tool outputs, current user instructions, or approval boundaries.

## 10. Evaluation strategy

The project uses multiple validation layers.

### Deterministic data calibration

Scenario V1 is rebuilt and measured before behavioral evaluation.

### Seven scripted integration cases

The cases test:

- period deterioration;
- channel concentration;
- longest-stage shortcut resistance;
- payment-term normalization;
- deterministic scenario math;
- causal discipline;
- approval boundaries.

Latest mock result:

- cases completed: **7/7**
- deterministic trace checks passed: **7/7**
- deterministic pass rate: **100%**
- semantic real-model score: **not claimed**

### Additional CI

- unit tests;
- Docker/Compose smoke test;
- portfolio demo smoke test;
- UI JavaScript syntax check;
- stateful follow-up validation;
- Markdown report generation;
- prompt/tool design metadata validation.

## 11. What the mock evidence proves

The current free evidence supports that:

- the database setup is reproducible;
- analytics tools return the intended metrics;
- scenario calculations are deterministic;
- policy retrieval is integrated;
- the agent tool loop is wired correctly;
- session/state plumbing works;
- tool traces are inspectable/evaluable;
- the browser demo and CLI fallback work;
- the system can generate portable Markdown evidence.

## 12. What the mock evidence does not prove

The current free evidence does not prove that a real LLM can independently:

- select the best tools for arbitrary unseen questions;
- reason correctly under novel ambiguity;
- synthesize consistently strong recommendations;
- pass the semantic rubric at a measured rate.

Those claims require a real OpenAI backend evaluation.

## 13. Demo/deployment

Zero-cost local demo:

```bash
git checkout feature/process-improvement-agent
bash agent/scripts/start_demo.sh --open
```

The launcher:

- checks Docker/Compose;
- resets/rebuilds the controlled dataset;
- starts MySQL + FastAPI;
- applies Scenario V1;
- validates readiness;
- opens the browser.

The UI supports:

- readiness indicators;
- presentation mode;
- prompt/tool inspection;
- FastAPI docs link;
- business question presets;
- process-flow visualization;
- evidence tables;
- KPI cards;
- tool-path visualization;
- raw trace;
- stateful causal follow-up;
- session reset;
- Markdown report export.

## 14. Business-analysis artifacts

The repository includes:

- business requirements + acceptance criteria;
- AS-IS / TO-BE process-improvement case;
- requirements traceability matrix;
- controlled benchmark definition;
- prompt/tool design documentation;
- architecture documentation;
- evaluation reports;
- demo script and interview Q&A.

## 15. Portfolio positioning

This project is intended to demonstrate the ability to translate an ambiguous business problem into:

- measurable requirements;
- business-process diagnostics;
- controlled analytical tools;
- system architecture;
- AI orchestration boundaries;
- evaluation criteria;
- guardrails;
- scenario planning;
- implementation/pilot recommendations;
- deployable software.

## 16. Resume-ready project description

> Built a deployable O2C process-improvement agent with FastAPI, MySQL, bounded AI tool orchestration, local business-context retrieval, deterministic Python scenario modeling, session state, and layered evaluation; created a controlled benchmark and validated seven scripted integration cases across KPI diagnosis, causal guardrails, scenario planning, and human-approval boundaries.

If a real OpenAI behavioral evaluation is completed later, update the description to distinguish measured real-model performance from mock integration evidence.

## 17. Current status

Portfolio MVP:

- functional demo: complete;
- reproducible controlled benchmark: complete;
- free mock integration evidence: complete;
- BA requirements/process artifacts: complete;
- Docker deployment: complete;
- optional real-model evaluation: not yet run.
