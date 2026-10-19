# Agent Documentation Index

Start here if you are reviewing the AI Process Improvement & Scenario Planning Agent.

## Fastest paths

### I want to run the demo

1. `demo_quickstart.md`
2. `demo_script.md`
3. `sample_demo_output.md`

### I want to understand the business-analysis work

1. `business_requirements.md`
2. `process_improvement_case.md`
3. `requirements_traceability.md`
4. `business_scenario_v1.md`

### I want to understand the technical architecture

1. `architecture.md`
2. `prompt_design.md`
3. `memory_design.md`
4. `deployment.md`
5. `testing_modes.md`

### I want to inspect evaluation evidence

1. `scenario_v1_benchmark.md`
2. `mock_evaluation_report.md`
3. `live_eval_runbook.md`
4. `final_report_template.md`

### I want the portfolio summary

1. `portfolio_final_report.md`
2. `demo_one_pager.md`
3. `demo_interview_qa.md`

## Document map

| Document | Purpose |
|---|---|
| `architecture.md` | system boundaries, request flow, evaluation architecture |
| `business_requirements.md` | users, goals, functional/non-functional requirements, acceptance criteria |
| `business_scenario_v1.md` | controlled business scenario design |
| `data_readiness_review.md` | source-data suitability and gaps |
| `demo_interview_qa.md` | likely interview questions and concise answers |
| `demo_one_pager.md` | architecture + validated demo findings in one page |
| `demo_quickstart.md` | exact local setup and demo procedure |
| `demo_script.md` | five-minute narrated demo flow |
| `deployment.md` | Docker/FastAPI deployment guidance |
| `final_report_template.md` | result-gated template for optional real-model evidence |
| `live_eval_runbook.md` | optional real OpenAI evaluation procedure |
| `memory_design.md` | session state and bounded preferences design |
| `mock_evaluation_report.md` | current seven-case free integration evidence |
| `portfolio_final_report.md` | completed portfolio MVP report |
| `process_improvement_case.md` | AS-IS → hypothesis → TO-BE → pilot plan |
| `project_plan.md` | implementation phases and original roadmap |
| `prompt_design.md` | actual system prompt, tool semantics, prompt versioning |
| `requirements_traceability.md` | requirement → implementation → validation mapping |
| `sample_demo_output.md` | reference Scenario V1 result |
| `scenario_v1_benchmark.md` | measured benchmark and acceptance thresholds |
| `testing_modes.md` | mock vs OpenAI evidence boundaries |

## Reviewer recommendation

For a 10-minute portfolio review:

1. read `demo_one_pager.md`;
2. run the demo using `demo_quickstart.md`;
3. inspect `business_requirements.md`;
4. inspect `prompt_design.md`;
5. review `mock_evaluation_report.md`;
6. open `requirements_traceability.md` to see how requirements map to tests.

This sequence shows the business problem, implementation, governance, and evidence without requiring the reviewer to read every project file.
