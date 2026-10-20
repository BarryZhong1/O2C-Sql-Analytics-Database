# Portfolio MVP Release Checklist

Target: **Agent API/UI v0.5.0 — portfolio demo release candidate**

## Business scope

- [x] O2C process-improvement problem is clearly defined.
- [x] Controlled Scenario V1 produces a reproducible deterioration.
- [x] Main demo distinguishes largest deterioration from longest absolute stage.
- [x] Marketplace drill-down is measurable and reproducible.
- [x] Process-change context is treated as hypothesis support, not causal proof.
- [x] Scenario planning produces deterministic modeled impact.
- [x] Recommended action includes pilot scope, success metrics, dependencies, and decision gate.

## Agent/system design

- [x] Natural-language business question endpoint.
- [x] Five bounded analytical tools.
- [x] No free-form model-generated SQL.
- [x] No operational write tools.
- [x] Human approval boundary.
- [x] Bounded analyst preferences.
- [x] Stateful follow-up path.
- [x] Mock/OpenAI backend abstraction.
- [x] Prompt and tool catalog versioning.

## Demo UX

- [x] One-command launcher.
- [x] Browser auto-open option.
- [x] Readiness indicators.
- [x] Presentation mode.
- [x] Architecture flow.
- [x] Prompt/tool inspection.
- [x] Business-question presets.
- [x] Custom scenario assumption.
- [x] Process-flow visualization.
- [x] KPI cards.
- [x] Evidence tables.
- [x] Evidence-status guardrail.
- [x] Tool-path visualization.
- [x] Raw trace/metadata inspection.
- [x] Markdown report download.
- [x] Raw JSON download.
- [x] Terminal fallback.

## Evaluation and CI

- [x] Unit tests.
- [x] Docker/Compose smoke test.
- [x] Scenario V1 calibration.
- [x] Seven scripted behavior cases.
- [x] Deterministic trace evaluator.
- [x] Semantic rubric.
- [x] Optional LLM-as-Judge path.
- [x] Portfolio demo smoke test.
- [x] Browser JavaScript syntax validation.
- [x] Custom scenario smoke test.
- [x] Stateful follow-up smoke test.
- [x] CI-generated Markdown demo artifact.

## Documentation

- [x] Documentation index.
- [x] Architecture.
- [x] Business requirements and acceptance criteria.
- [x] AS-IS / TO-BE process case.
- [x] Requirements traceability matrix.
- [x] Prompt/tool design.
- [x] Memory design.
- [x] Testing modes.
- [x] Mock evaluation report.
- [x] Demo quick start.
- [x] Five-minute demo script.
- [x] Interview Q&A.
- [x] Demo one-pager.
- [x] Portfolio MVP report.

## Evidence boundary

- [x] Mock results are explicitly labeled as scripted integration evidence.
- [x] No claim of real-model semantic accuracy is made.
- [x] OpenAI backend remains available for optional future validation.
- [x] Real-model results section remains unset until actually measured.

## Optional future enhancements

- [ ] Run seven-case evaluation with a real OpenAI model.
- [ ] Tune prompt/tools only from measured real-model failures.
- [ ] Add richer intervention-specific simulation inputs (capacity, rework, cost).
- [ ] Add hosted deployment if a public URL is needed.
- [ ] Add recorded video/GIF after local visual QA.

## Release decision

The project is ready to be treated as a **portfolio MVP release candidate** when the four primary CI gates are green on the final branch commit:

1. Agent unit tests;
2. Agent Docker smoke test;
3. Agent mocked behavior evals;
4. Portfolio demo smoke test.

Real-model evaluation is an optional evidence upgrade, not a blocker for the zero-cost portfolio MVP.
