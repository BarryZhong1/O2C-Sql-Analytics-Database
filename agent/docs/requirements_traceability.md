# Requirements Traceability Matrix

This matrix connects business/functional requirements to implementation evidence and automated validation.

| Requirement | Implementation evidence | Validation evidence |
|---|---|---|
| FR-01 Natural-language investigation | `app/main.py` → `POST /agent/ask`; `app/agent.py` | Portfolio demo smoke test main investigation |
| FR-02 Process-stage comparison | `tools/process_analytics.py::compare_stage_performance` | `tests/test_process_analytics.py`; eval_001/eval_003 |
| FR-03 Business-driver drill-down | `tools/process_analytics.py::analyze_process` | `tests/test_process_analytics.py`; eval_002 |
| FR-04 Business-context retrieval | `tools/policy_retriever.py` | `tests/test_policy_retriever.py`; eval_006 |
| FR-05 Scenario planning | `tools/scenario_simulator.py` | `tests/test_scenario_simulator.py`; eval_005 |
| FR-06 Approval boundary | no operational write tools; system rule 10 | eval_007; mock guardrail preset |
| FR-07 Stateful follow-up | `app/state.py`; session endpoints; mock prior-result reuse | `tests/test_state.py`; `tests/test_model_backends.py`; demo smoke stateful follow-up |
| FR-08 Bounded analyst preferences | `app/state.py`; profile preference endpoints | `tests/test_state.py` |
| FR-09 Traceability | `app/agent.py` tool trace; `app/observability.py` | `tests/test_observability.py`; `tests/test_trace_evaluator.py` |
| FR-10 Prompt/tool transparency | `GET /demo/design`; version hashes; UI design panel | `tests/test_demo_support.py`; demo smoke design validation |
| FR-11 Demo readiness | `GET /demo/status`; readiness UI; `start_demo.sh` | Portfolio demo smoke test |
| FR-12 Portable output | browser Markdown export; `scripts/build_demo_report.py` | `tests/test_demo_support.py`; demo smoke report build |
| NFR-01 Reproducibility | `data/scenario_v1_marketplace_bottleneck.sql`; calibration script | mocked eval workflow scenario calibration |
| NFR-02 Auditability | parameterized tools + raw tool trace | deterministic trace evaluator |
| NFR-03 Safety/governance | read-only tool surface + approval rule | eval_007 |
| NFR-04 Cost control | `MODEL_BACKEND=mock` default | mock workflow runs without API secret |
| NFR-05 Replaceable model boundary | `app/model_backends.py` | `tests/test_model_backends.py` |
| NFR-06 Deployment portability | Dockerfile + Compose + launcher | Agent Docker smoke test + Portfolio demo smoke test |
| NFR-07 Honest reporting | mock labels, testing modes docs, report disclosure | report builder + UI backend banner |

## CI evidence

The branch maintains four primary automated quality gates:

1. **Agent unit tests** — Python compile + unit suite.
2. **Agent Docker smoke test** — image build, Compose startup, health/UI/session endpoints.
3. **Agent mocked behavior evals** — Scenario V1 calibration + seven deterministic behavior cases.
4. **Portfolio demo smoke test** — exact local launcher, readiness/design endpoints, browser UI/JavaScript, four-tool investigation, Markdown artifact, terminal fallback, and stateful follow-up.

## Change-management use

When a requirement changes:

1. update `business_requirements.md`;
2. update the corresponding implementation;
3. update or add the mapped test/evaluation case;
4. update this matrix;
5. require the relevant CI gate to pass before treating the change as complete.

This keeps the portfolio project from becoming a collection of disconnected features and makes the relationship between business requirements, technical implementation, and verification explicit.
