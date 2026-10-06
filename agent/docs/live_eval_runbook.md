# Live Evaluation Runbook

## Purpose

Use this runbook to produce the first complete API-backed evaluation artifact for the seven-case O2C benchmark.

The workflow intentionally does **not** run on ordinary pushes because it calls the external model API and therefore has variable cost. Automatic CI continues to cover unit tests, deterministic Scenario V1 calibration, and Docker/API/UI smoke checks without model calls.

## One-time repository setup

Add a repository Actions secret named:

```text
OPENAI_API_KEY
```

GitHub UI path:

```text
Repository → Settings → Secrets and variables → Actions → New repository secret
```

Do not store the key in `.env`, workflow YAML, committed JSON, issue comments, or PR comments.

## Why there are two trigger paths

GitHub only exposes `workflow_dispatch` for workflows that exist on the repository's default branch. While this project is still isolated in the draft feature branch, the workflow therefore also supports a deliberately narrow feature-branch push trigger.

### Before this PR is merged

After `OPENAI_API_KEY` is configured, create or update exactly this file on the feature branch:

```text
agent/evals/.run-live-evals
```

Any content is acceptable; a timestamp or short note is enough. The live workflow watches only that path for push-triggered runs, so normal development pushes do not spend API budget.

Example content:

```text
2026-10-06 first full live evaluation
```

For the feature-branch trigger:

- model defaults to `gpt-5`;
- semantic judging is enabled;
- Scenario V1 is rebuilt and recalibrated before model evaluation.

### After the workflow exists on the default branch

Use:

```text
Repository → Actions → Agent live behavior evals → Run workflow
```

Then select the desired branch, model, and whether to run semantic judging.

## What the workflow does

1. Installs the agent dependencies.
2. Verifies `OPENAI_API_KEY` is available.
3. Starts MySQL.
4. Loads the clean synthetic O2C dataset.
5. Applies Scenario V1.
6. Re-runs deterministic Scenario V1 calibration.
7. Executes all seven live agent behavior cases.
8. Runs the semantic rubric judge when enabled.
9. Builds a Markdown evaluation summary.
10. Uploads all reports as a GitHub Actions artifact.
11. Fails the workflow if deterministic live checks fail, semantic checks fail when enabled, or the summary cannot be generated.

## Expected artifact bundle

The workflow uploads an artifact named similar to:

```text
agent-live-eval-<run_number>
```

Expected files:

```text
live_eval_report.json
semantic_eval_report.json
evaluation_summary.md
scenario-v1-live-calibration.json
```

The live report includes the final answer, tool trace, model response lineage, latency, and token-usage metadata for each completed case.

## Reading the result

Start with `evaluation_summary.md`.

Check in this order:

1. Did Scenario V1 calibration still pass?
2. Did all seven cases complete?
3. Which deterministic trace requirements failed?
4. Which semantic rubric dimensions failed?
5. Were any failures critical (`evidence_grounding`, `causal_discipline`, or `approval_boundary`)?
6. Are failures isolated or repeated across cases?
7. What are the observed latency/model-call/token characteristics?

Do not tune the prompt merely to reproduce hidden ground-truth wording. Fix the smallest generalizable failure in tool descriptions, prompt rules, schemas, or deterministic calculations, then rerun the whole suite to check for regressions.

## Recommended failure triage

| Failure type | First place to inspect |
|---|---|
| Wrong tool selected | tool descriptions + system prompt |
| Right tool, wrong dates/dimension | tool schema + eval prompt clarity |
| KPI/math mismatch | deterministic SQL/Python tool, not the LLM prompt |
| Longest-stage shortcut | stage-comparison prompt/tool description |
| Raw payment duration used across different terms | collection metric guidance |
| Unsupported causal claim | causal-discipline rule + retrieved context wording |
| Scenario presented as guaranteed | scenario tool description + assumption rule |
| Attempts operational execution | tool surface + human-approval rule |
| Good trace but weak recommendation | semantic synthesis/presentation guidance |

## Completion criterion for the draft PR

Before treating the portfolio MVP as evidence-complete, retain at least one full seven-case live run and use its actual results to fill `docs/final_report_template.md`.

The PR should remain draft while live behavior has not yet been measured. A green unit/Docker/calibration CI suite proves the deterministic infrastructure works; it does not substitute for testing the model's actual tool-selection and synthesis behavior.
