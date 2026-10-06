# Evaluation Strategy

The project uses two layers of evaluation.

## 1. Deterministic checks

Use deterministic checks wherever the expected result can be computed directly.

Examples:
- scenario-injection signatures;
- stage ranking;
- numerical scenario math;
- tool arguments;
- guardrail violations.

Run the Scenario V1 calibration after loading the controlled overlay:

```bash
cd agent
python scripts/calibrate_scenario_v1.py
```

A non-zero exit code means the injected pattern is not strong/reliable enough for the planned demo and should be recalibrated before tuning the LLM.

## 2. Agent behavior cases

`eval_cases.json` defines behavior-level cases for:
- tool selection;
- correct drill-down;
- payment-term normalization;
- scenario grounding;
- causality discipline;
- human approval boundaries.

These cases should eventually be run through an automated harness that records:
- final answer;
- tool trace;
- deterministic assertions;
- rubric/LLM-judge score where deterministic grading is insufficient.

## Ground-truth separation

`scenario_v1_ground_truth.json` is an evaluation artifact only.

Do **not** provide it to the agent as prompt context, retrieval context, memory, or policy documentation. The point of Scenario V1 is to test whether the agent discovers the injected pattern from business data.
