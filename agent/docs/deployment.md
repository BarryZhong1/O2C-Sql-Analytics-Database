# Deployment Guide

## Goal

Package the portfolio project as a small deployable business system rather than a notebook-only demo.

The local deployment contains three services:

```text
Browser / API client
        |
        v
Agent API + analyst UI :8000
        |
        +----> MySQL O2C database :3306
        |
        +----> OpenAI Responses API
        |
        +----> local business-context documents
        |
        +----> persistent SQLite session/preference volume

Adminer :8080 ----> MySQL
```

## Prerequisites

- Docker with Compose v2
- an OpenAI API key for `/agent/*` model calls

The analyst UI, `/health`, fixed workflow, database, and container smoke-test paths can load without the model API key. Running an agent investigation requires it.

## Start the stack

From the repository root:

```bash
export OPENAI_API_KEY="..."
docker compose up -d --build db agent adminer
```

Check service state:

```bash
docker compose ps
```

Analyst UI:

```text
http://localhost:8000/
```

Agent health:

```bash
curl http://localhost:8000/health
```

Interactive API documentation:

```text
http://localhost:8000/docs
```

Adminer:

```text
http://localhost:8080
```

## Load the deterministic portfolio dataset

The MySQL service must be healthy before loading the SQL project.

```bash
docker compose exec -T db sh -c \
  'mysql -h127.0.0.1 -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  < sql/complete_setup.sql
```

Apply the controlled Scenario V1 overlay:

```bash
docker compose exec -T db sh -c \
  'mysql -h127.0.0.1 -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  < agent/data/scenario_v1_marketplace_bottleneck.sql
```

## Use the analyst UI

The root page is intentionally lightweight and has no separate frontend build system. It supports:

- natural-language business questions;
- stateless or stateful investigation sessions;
- optional analyst profile preferences;
- final answer display;
- expandable tool trace and response metadata;
- explicit preference controls for detail level, preferred drill-down, risks, and scenario inclusion.

The browser calls the same FastAPI endpoints documented below, so the UI is a thin client rather than a second business-logic layer.

## Run an investigation through the API

Fixed workflow baseline:

```bash
curl -X POST http://localhost:8000/workflow/investigate \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2024-07-01",
    "end_date": "2024-09-30",
    "compare_start_date": "2024-04-01",
    "compare_end_date": "2024-06-30"
  }'
```

Stateful agent session:

```bash
curl -X POST http://localhost:8000/agent/session/demo/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Compare Q3 O2C performance with Q2 and identify the stage that deteriorated most."
  }'
```

Then continue the same investigation:

```bash
curl -X POST http://localhost:8000/agent/session/demo/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Drill into the sales channel driving that deterioration and check relevant process changes."
  }'
```

## Persistence

Docker volumes:

- `dbdata` persists the MySQL database.
- `agentstate` persists the local SQLite session-response mapping and bounded analyst preferences.

The local state store contains response IDs, timestamps, and whitelisted profile preferences; it is not a second copy of raw O2C transactional data.

Remove containers but retain data:

```bash
docker compose down
```

Remove local containers **and** persisted demo data/state:

```bash
docker compose down -v
```

## Configuration

The agent container receives:

- `OPENAI_API_KEY`
- `OPENAI_MODEL` (default `gpt-5` in the current project config)
- `DATABASE_URL=mysql+pymysql://app:app_pw@db:3306/o2c`
- `POLICY_PATH=policies`
- `STATE_DB_PATH=/state/agent_state.db`

Do not commit API keys or production credentials.

## Container security choices in the MVP

- the agent image runs as a non-root user;
- the API accesses MySQL through the application account rather than the root account;
- analytical tools expose whitelisted metrics/dimensions rather than arbitrary SQL;
- the agent has no business-operation write tools;
- local session/preferences state is isolated in a dedicated volume;
- scenario and policy files are baked into the image for reproducible demos.

This is a portfolio/demo deployment, not a production security certification. Production hardening would additionally require secret management, authentication/authorization, TLS, network policies, centralized audit logging, database least-privilege review, retention controls, and environment-specific configuration.

## CI smoke test

`.github/workflows/agent-docker-smoke.yml` validates that:

1. Docker Compose configuration parses;
2. the agent image builds;
3. MySQL becomes healthy;
4. the agent starts;
5. `/health` returns `status=ok`;
6. the analyst UI is served at `/`;
7. a session-status request reaches the FastAPI service;
8. the stack is torn down after the test.

The smoke test deliberately does not call the external model API, so it does not require an API secret in CI.
