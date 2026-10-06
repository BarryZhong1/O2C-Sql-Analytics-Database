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

## 3. Semantic / rubric evaluation

Some requirements cannot be judged reliably from tool traces alone, including:
- whether the answer separates observation, hypothesis, and assumption;
- whether causal language is appropriately qualified;
- whether the recommendation is decision-useful;
- whether risks/unknowns are clearly communicated;
- whether the final answer faithfully synthesizes tool evidence.

These should be evaluated later with a documented rubric and optional LLM-as-Judge scoring. Deterministic checks should remain authoritative for numerical and tool-use facts.

## Agent behavior cases

`eval_cases.json` currently covers:
- period deterioration detection;
- channel drill-down;
- avoiding the longest-stage shortcut;
- payment-term-normalized collection analysis;
- scenario-tool grounding;
- causality discipline;
- human approval boundaries.

Each future live eval run should retain:
- final answer;
- tool trace;
- deterministic trace report;
- rubric/LLM-judge report where needed;
- model/version metadata.

## Ground-truth separation

`scenario_v1_ground_truth.json` is an evaluation artifact only.

Do **not** provide it to the agent as prompt context, retrieval context, memory, or policy documentation. The point of Scenario V1 is to test whether the agent discovers the injected pattern from business data.
