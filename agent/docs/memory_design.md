# Context and Memory Design

## Why memory exists in this project

The agent needs two different kinds of continuity:

1. **Investigation continuity** — a user should be able to ask a follow-up such as "now drill into channel" without repeating the entire previous question.
2. **Stable reporting preferences** — an analyst may consistently prefer executive-level answers or channel-first drill-downs across separate sessions.

These needs should not be implemented by dumping all prior conversations or customer-level business data into a vector database.

## Memory layers

### Layer 1 — short-term session state

Implemented with:
- Responses API `previous_response_id`;
- a local SQLite mapping from `session_id` to the latest response ID;
- explicit session inspect/reset endpoints.

Stored locally:
- session ID;
- latest response ID;
- created/updated timestamps.

Not duplicated locally:
- raw O2C transactional rows;
- full chat transcripts;
- hidden Scenario V1 ground truth.

This keeps the MVP small while supporting multi-turn investigations.

### Layer 2 — bounded long-term analyst preferences

Implemented as an explicit, whitelisted preference store in the same local SQLite database.

Allowed keys:
- `detail_level`: `executive | balanced | detailed`
- `preferred_breakdown`: `segment | channel | none`
- `include_risks`: boolean
- `include_scenario_if_relevant`: boolean

Unknown keys are rejected. This prevents the memory store from silently turning into an unrestricted profile database.

Preferences affect presentation and optional investigation defaults only. They cannot:
- override measured evidence;
- change KPI definitions;
- authorize write actions;
- suppress safety/approval boundaries;
- force a scenario when it is not relevant to the user's current request.

## API examples

Set an analyst profile:

```bash
curl -X PUT http://localhost:8000/agent/profile/ops-manager/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "detail_level": "executive",
    "preferred_breakdown": "channel",
    "include_risks": true,
    "include_scenario_if_relevant": true
  }'
```

Inspect it:

```bash
curl http://localhost:8000/agent/profile/ops-manager/preferences
```

Use it in a stateless request:

```bash
curl -X POST http://localhost:8000/agent/ask \
  -H "Content-Type: application/json" \
  -d '{
    "profile_id": "ops-manager",
    "question": "Compare Q3 O2C performance with Q2 and identify the strongest operational deterioration."
  }'
```

Or combine the profile with a multi-turn session:

```bash
curl -X POST http://localhost:8000/agent/session/q3-review/ask \
  -H "Content-Type: application/json" \
  -d '{
    "profile_id": "ops-manager",
    "question": "Continue the investigation and evaluate an improvement scenario."
  }'
```

Reset preferences:

```bash
curl -X DELETE http://localhost:8000/agent/profile/ops-manager/preferences
```

## Why not vector memory yet

A vector store is useful when there is a real retrieval problem over many durable memories or documents. For the current MVP:
- conversation continuity is already handled by response state;
- business rules/process context are handled by the local document retriever;
- durable user memory consists of four small structured preferences.

Adding embeddings here would increase complexity without improving the core business decision task.

A later version could add vector memory for compact summaries of prior investigations if there is a demonstrated need to retrieve similar historical cases across many sessions.

## Governance principles

- memory writes are explicit API actions, not invisible model decisions;
- stored keys are whitelisted;
- users can inspect and delete stored preferences;
- sensitive customer-level details are out of scope for long-term memory;
- operational permissions are not represented as preferences;
- hidden evaluation ground truth is never memory/context.
