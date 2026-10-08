# Testing Modes

The project supports two model backends so most development and integration testing can remain free while preserving a real OpenAI Responses API path for later validation.

## 1. Mock backend — default and free

Set:

```bash
MODEL_BACKEND=mock
```

No `OPENAI_API_KEY` is required.

The scripted mock backend deliberately implements a narrow set of tool-selection plans for the documented O2C evaluation cases. It still runs the real project code around the model boundary:

- FastAPI request handling;
- agent tool loop;
- SQLAlchemy/MySQL analytics;
- policy/context retrieval;
- deterministic Python scenario simulation;
- session/response lineage plumbing;
- tool traces and timing;
- deterministic trace evaluation;
- Scenario V1 calibration;
- Docker/Compose integration.

Mock outputs are visibly labeled `[MOCK BACKEND]`.

### What mock results prove

A passing mock suite demonstrates that the system wiring, tool schemas, deterministic calculations, database integration, guardrails exposed by the tool surface, and evaluation harness work together.

### What mock results do not prove

Mock results are **not** evidence that a real LLM can:

- infer the right investigation path from unseen wording;
- reason well under ambiguity;
- synthesize a strong business recommendation;
- maintain causal discipline without scripted routing;
- achieve the semantic rubric threshold.

Do not report mock trace pass rates as real-model performance.

## 2. OpenAI backend — optional real-model validation

Set:

```bash
MODEL_BACKEND=openai
OPENAI_API_KEY=<secret>
OPENAI_MODEL=<supported model>
```

The agent then uses the real OpenAI Responses API through the same tool loop and returns `backend: openai` in its run metadata.

The paid/live GitHub Actions workflow also passes `--backend openai` explicitly, so the existence of a mock default cannot accidentally turn a claimed live run into a scripted run.

## Local mocked evaluation

After loading the O2C database and Scenario V1:

```bash
cd agent
MODEL_BACKEND=mock \
DATABASE_URL=mysql+pymysql://app:app_pw@localhost:3306/o2c \
python scripts/run_live_evals.py \
  --backend mock \
  --output artifacts/mock_eval_report.json

python scripts/build_eval_summary.py \
  --live artifacts/mock_eval_report.json \
  --semantic artifacts/no_semantic_report.json \
  --output artifacts/mock_evaluation_summary.md
```

## GitHub Actions

### Free automatic workflow

`Agent mocked behavior evals` runs without an API key. It rebuilds the database, applies Scenario V1, recalibrates the benchmark, executes all seven scripted mock cases through the real tool loop, creates a Markdown summary, and uploads artifacts.

### Optional paid/live workflow

`Agent live behavior evals` remains available for later real-model validation. It requires the repository secret `OPENAI_API_KEY`.

## Semantic evaluation

The LLM-as-Judge semantic layer is intentionally reserved for real API runs. The mock suite focuses on deterministic trace/tool behavior because scoring a scripted mock answer with another scripted fake judge would create misleading evidence.

The documented semantic rubric remains in the repository so the same seven cases can be evaluated later with a real model.

## Portfolio reporting rule

Keep these result classes separate:

```text
Mocked integration evidence
    = system wiring + tools + deterministic evaluation

Real-model evidence
    = model tool selection + synthesis + semantic evaluation
```

A final report may include the mock suite as engineering validation even if no paid API run has been performed, but it must explicitly say that real-model behavioral evaluation remains pending.
