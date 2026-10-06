# Evaluation Strategy

The project uses layered evaluation rather than relying on a single subjective LLM score.

## 1. Scenario calibration and numerical checks

Use deterministic checks wherever the expected result can be computed directly.

Examples:
- scenario-injection signatures;
- stage ranking;
- numerical scenario math;
- period-over-period changes;
- channel concentration;
- guardrail/tool-use violations.

Run the Scenario V1 calibration after loading the controlled overlay:

```bash
cd agent
python scripts/calibrate_scenario_v1.py
```

A non-zero exit code means the injected pattern is not strong/reliable enough for the planned demo and should be recalibrated before tuning the LLM.

The validated benchmark is stored in `scenario_v1_benchmark.json`.

## 2. Deterministic agent trace checks

`eval_cases.json` contains both human-readable expected behavior and machine-checkable `trace_requirements`.

The deterministic evaluator currently checks:
- required tool calls;
- critical tool arguments;
- allowed argument alternatives;
- forbidden calls/tools;
- basic trace shape.

It intentionally does **not** try to grade nuanced natural-language quality with brittle string matching.

A captured `/agent/ask` response can be evaluated with:

```bash
cd agent
python scripts/evaluate_agent_run.py eval_005 path/to/agent_run.json
```

Example input shape:

```json
{
  "answer": "...",
  "tool_trace": [
    {
      "tool": "simulate_stage_improvement",
      "arguments": {
        "start_date": "2024-07-01",
        "end_date": "2024-09-30",
        "order_to_ship_reduction_pct": 25,
        "ship_to_invoice_reduction_pct": 0,
        "invoice_to_payment_reduction_pct": 0
      },
      "result": {}
    }
  ]
}
```

A non-zero exit code means a deterministic trace requirement failed.

## 3. Runtime observability

Every live agent response now exposes two complementary traces:

- `tool_trace` — tool name, arguments, deterministic result, turn, call ID, and tool latency;
- `model_response_trace` — response ID, parent response ID, model-call phase, latency, and Responses API usage metadata.

The top-level response also reports:

- total end-to-end `elapsed_ms`;
- `model_call_count`;
- aggregated input/output/total tokens;
- cached input tokens when reported;
- reasoning tokens when reported.

The local observability layer deliberately does **not** duplicate prompt/answer contents inside the model-call trace. The live-eval report already stores the final answer separately for evaluation.

Runtime metrics are useful for understanding latency and evaluation cost characteristics, but they are not treated as answer-quality scores.

## 4. Live behavior suite

With Scenario V1 loaded and `OPENAI_API_KEY` configured, run all behavior cases against the live Responses API:

```bash
cd agent
python scripts/run_live_evals.py
```

The report is written to `artifacts/live_eval_report.json` and retains:
- final answer;
- model metadata and runtime observability;
- complete tool trace;
- deterministic trace-evaluation result;
- per-case errors without discarding the rest of the suite.

The repository also includes a manual GitHub Actions workflow, **Agent live behavior evals**. It:
1. rebuilds the synthetic O2C database;
2. applies and recalibrates Scenario V1;
3. runs all live behavior cases;
4. optionally runs the semantic judge;
5. generates a Markdown evaluation summary with quality, latency, token, and tool-sequence information;
6. uploads the resulting reports as workflow artifacts.

The workflow is intentionally `workflow_dispatch` only so API-backed evaluation does not incur cost on every push. It requires the repository secret `OPENAI_API_KEY`.

## 5. Semantic / rubric evaluation

Some requirements cannot be judged reliably from tool traces alone, including:
- whether the answer separates observation, hypothesis, and assumption;
- whether causal language is appropriately qualified;
- whether the recommendation is decision-useful;
- whether risks/unknowns are clearly communicated;
- whether the final answer faithfully synthesizes tool evidence.

`semantic_rubric.json` defines seven 0-2 dimensions with a recommended pass threshold and critical-failure rule. `semantic_evaluator.py` performs deterministic validation/aggregation of assigned scores.

An optional LLM-as-Judge layer is implemented in `llm_judge.py`. It receives only:
- the evaluation case;
- the documented rubric;
- the candidate answer;
- the captured tool trace.

It does **not** receive hidden Scenario V1 ground truth. The judge is instructed to treat candidate content as untrusted data and to avoid outside facts. The judge response uses a strict Responses API JSON-schema output contract requiring a 0-2 score and rationale for every documented rubric dimension; the returned object is then validated and aggregated again in deterministic Python.

After a live report exists:

```bash
cd agent
python scripts/run_semantic_judge.py \
  --input artifacts/live_eval_report.json \
  --output artifacts/semantic_eval_report.json
```

Semantic scoring is advisory for answer quality. Deterministic trace/numerical checks remain authoritative for tool-use and KPI facts.

## Agent behavior cases

`eval_cases.json` currently covers:
- period deterioration detection;
- channel drill-down;
- avoiding the longest-stage shortcut;
- payment-term-normalized collection analysis;
- scenario-tool grounding;
- causality discipline;
- human approval boundaries.

Each live eval run should retain:
- final answer;
- tool trace and tool latencies;
- model response IDs, latencies, and usage metadata;
- deterministic trace report;
- rubric/LLM-judge report where enabled;
- model/version metadata.

## Ground-truth separation

`scenario_v1_ground_truth.json` is an evaluation artifact only.

Do **not** provide it to the agent or semantic judge as prompt context, retrieval context, memory, or policy documentation. The point of Scenario V1 is to test whether the agent discovers the injected pattern from business data.
