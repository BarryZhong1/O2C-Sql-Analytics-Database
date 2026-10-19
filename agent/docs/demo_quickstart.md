# Portfolio Demo Quick Start

This is the recommended **zero-API-cost** demo path.

The demo uses the scripted mock backend to choose a known investigation path, but the SQL analytics, policy retrieval, scenario calculations, API, database, tool trace, and UI are the real project components.

## 1. Prerequisites

Install:

- Git
- Docker Desktop (or Docker Engine + Compose v2)

No OpenAI API key is required for the default demo.

## 2. Get the feature branch

If you do not already have the repository locally:

```bash
git clone https://github.com/BarryZhong1/O2C-Sql-Analytics-Database.git
cd O2C-Sql-Analytics-Database
git checkout feature/process-improvement-agent
```

If you already cloned it:

```bash
git fetch
git checkout feature/process-improvement-agent
git pull
```

## 3. Start a clean demo

From the repository root, the shortest command is:

```bash
make demo-open
```

Equivalent direct command:

```bash
bash agent/scripts/start_demo.sh --open
```

The `--open` flag opens the analyst UI automatically when the stack is ready. Omit it if you prefer to open the browser manually.

The launcher:

1. checks Docker/Compose prerequisites and Docker daemon availability;
2. resets the local demo containers/volumes for reproducibility;
3. starts MySQL and the FastAPI agent;
4. loads the base O2C dataset;
5. applies controlled Scenario V1;
6. validates `/demo/status` readiness;
7. prints the demo URL and active backend.

Open:

```text
http://localhost:8000/
```

The page should display:

> **Free demo mode:** scripted investigation path with real MySQL/tool results.

It should also show four green readiness indicators:

- **Database** — orders loaded;
- **Scenario V1** — applied;
- **Backend** — mock;
- **Demo status** — Ready to present.

## 4. Optional: show the actual prompt/tool design

Before running the analysis, expand **Inspect agent instructions & tool catalog** if the reviewer asks how the agent is prompted.

That panel is loaded from the running application rather than a manually copied slide. It shows:

- the parsed system-prompt rules;
- all five approved tools and their descriptions;
- a prompt version hash;
- a tool-catalog version hash;
- the full current system prompt.

The **API docs** shortcut opens FastAPI's generated OpenAPI documentation in a separate tab.

## 5. Run the main portfolio demo

Click **Full diagnosis** and then **Run investigation**.

The expected tool path is:

```text
compare_stage_performance
        ↓
analyze_process (order-to-ship by channel)
        ↓
retrieve_policy
        ↓
simulate_stage_improvement
        ↓
structured business recommendation
```

The answer should identify:

- Q3 O2C deterioration versus Q2;
- order-to-ship as the stage that deteriorated most;
- Marketplace as the strongest channel-level driver;
- the July 1 Marketplace promotional-review change as relevant context, not causal proof;
- the modeled impact of a 25% order-to-ship improvement;
- risks/unknowns and a human-approved next action.

The UI now also renders the investigation as a four-step visual path so a reviewer can understand the orchestration without reading raw JSON.

Expand **Inspect tool trace** to show the underlying SQL/tool results used by the demo.

After the run, click **Download Markdown report** to export the business question, KPI/stage/channel evidence tables, scenario results, answer, tool path, evidence-mode disclosure, and governance note as a portable demo artifact.

## 6. Use the other demo presets

### Channel drill-down

Shows that the system can compare Q3 and Q2 by sales channel and rank the deterioration deterministically.

### 25% what-if

Runs the deterministic Python scenario simulator and shows modeled days saved.

You can also change **Custom Order → Ship improvement assumption (%)** and click **Set custom what-if**. This prepares a scenario prompt with any value from 0–100%; for example, a 10% assumption should save about 0.21 modeled days in Scenario V1.

### Approval guardrail

Asks the system to automatically change the business process and customer terms. The system refuses execution and requires human approval.

### Causality follow-up

Use the same stateful session after **Full diagnosis** and click **Causality follow-up**. The mock path explains what additional evidence would be needed before claiming that the Marketplace process change caused the slowdown. In mock mode, the follow-up reuses the prior structured investigation evidence and makes no redundant analytical tool call. This is useful for demonstrating response lineage, bounded state reuse, and causal-discipline design.

The **Reset session** button clears the current demo session so you can repeat the presentation from a clean state.

## 7. What to say during the demo

A concise explanation:

> I started with a fixed O2C analytics database, then added an agent layer that can choose from bounded analytical tools. For the free portfolio demo I use a scripted mock at the model boundary, so there is no API cost. The database queries, process metrics, policy retrieval, scenario calculations, traces, state, and evaluation system are all real. The same application can switch to the OpenAI Responses API later without changing the business tools.

When showing the result:

> The benchmark is deliberately designed so invoice-to-payment is still the longest absolute stage, but order-to-ship is the stage that actually deteriorated. That tests whether the investigation focuses on change rather than simply picking the largest number.

When showing the process-change log:

> The July 1 change is contextual evidence. The system does not treat timing as causal proof.

When showing the scenario:

> The 25% improvement is a transparent what-if assumption calculated in Python. It is not presented as a guaranteed operational effect.

## 8. Important honesty boundary

The mock demo **does demonstrate**:

- deployable UI/API;
- end-to-end database integration;
- bounded tool orchestration;
- deterministic KPI calculations;
- multi-step investigation flow;
- retrieval;
- scenario planning;
- traceability;
- approval guardrails;
- evaluation infrastructure.

It **does not demonstrate** that a real LLM independently discovered the tool path.

If asked, say exactly that. The project preserves an optional `MODEL_BACKEND=openai` mode for later real-model validation.

## 9. Optional OpenAI mode later

After configuring an API key:

```bash
export MODEL_BACKEND=openai
export OPENAI_API_KEY="..."
export OPENAI_MODEL="gpt-5"
bash agent/scripts/start_demo.sh
```

The UI and business tools remain the same; only the model/orchestration backend changes.

## 10. Stop/reset

Stop containers but keep volumes:

```bash
docker compose down
```

Delete all local demo database/state volumes:

```bash
docker compose down -v
```

The next normal `start_demo.sh` run resets volumes anyway unless you explicitly use:

```bash
bash agent/scripts/start_demo.sh --keep-data
```


## Presenter preparation

See `demo_interview_qa.md` for concise answers about the system prompt, tool descriptions, mock-vs-real boundaries, causality, SQL guardrails, evaluation, and likely interview follow-ups.


## Terminal fallback

If you prefer to demonstrate the project without a browser, keep the Docker demo running and execute:

```bash
python3 agent/scripts/run_demo_cli.py
```

The CLI submits the same main business question through the FastAPI endpoint, prints the tool path and recommendation, and can save the raw response:

```bash
python3 agent/scripts/run_demo_cli.py \
  --output agent/artifacts/local_demo_response.json
```

## Reference output

See `sample_demo_output.md` for a validated reference snapshot of the expected Scenario V1 findings and numbers.


## Convenience commands

From the repository root:

```bash
make help
```

Useful shortcuts include `make demo`, `make demo-open`, `make demo-cli`, `make demo-stop`, `make demo-reset`, `make agent-test`, and `make compose-check`.
