# Deployment Guide — GitHub Codespaces, GitHub Pages, and Local Docker

This project now supports three practical deployment/presentation modes.

## Option A — GitHub Codespaces: full application in the browser

This is the easiest way to run the **real FastAPI + MySQL + tool-trace application** without installing the repository locally.

### What runs

GitHub Codespaces starts a cloud development environment that contains:

- Docker;
- Docker Compose;
- Python 3.12;
- the repository;
- MySQL;
- the FastAPI agent service;
- the full analyst UI.

The default backend remains `MODEL_BACKEND=mock`, so no OpenAI API key is required.

### Launch

Open:

```text
https://codespaces.new/BarryZhong1/O2C-Sql-Analytics-Database?ref=feature/process-improvement-agent
```

Then choose **Create codespace**.

The `.devcontainer/devcontainer.json` configuration automatically:

1. provisions Docker-in-Docker;
2. forwards port 8000;
3. runs `.devcontainer/bootstrap.sh`;
4. rebuilds the controlled Scenario V1 dataset on first creation;
5. starts the FastAPI + MySQL stack;
6. opens the forwarded analyst UI when port 8000 becomes available.

If the browser does not open automatically, use the **Ports** tab and open the forwarded port labeled:

> O2C Process Improvement Agent

### Restart behavior

On normal Codespaces restarts, the bootstrap script tries to reuse the existing Docker volumes. If the stored demo data is invalid or missing, it automatically rebuilds the controlled dataset.

### Important limitation

Codespaces is a cloud development environment, not permanent production hosting.

The application is available while the codespace is running. A sleeping or stopped codespace does not serve the UI.

Use GitHub Pages when you need a permanently accessible static portfolio link.

---

## Option B — GitHub Pages: public static portfolio demo

The repository includes:

```text
site/index.html
```

This is a standalone static interface showing the validated Scenario V1 benchmark.

It includes:

- KPI cards;
- stage and channel evidence tables;
- O2C process visualization;
- interactive custom Order → Ship scenario percentage;
- modeled cash-cycle result;
- sample investigation path;
- sample recommendation;
- report download.

The page is explicitly labeled as a **static portfolio preview**. It does not pretend to query MySQL or run a real model.

### Deployment workflow

The workflow:

```text
.github/workflows/pages.yml
```

validates the static UI in pull requests and deploys `site/` after the workflow exists on `main`.

### One-time GitHub setting

After this feature branch is merged to `main`:

1. open the GitHub repository;
2. go to **Settings**;
3. open **Pages**;
4. under **Build and deployment**, choose **GitHub Actions** as the source.

The next eligible workflow run deploys the site.

Expected URL:

```text
https://barryzhong1.github.io/O2C-Sql-Analytics-Database/
```

If GitHub shows a different Pages URL in the deployment environment, use the URL reported by the Pages workflow.

### What Pages does not run

GitHub Pages cannot host:

- FastAPI;
- MySQL;
- Docker;
- the agent tool loop;
- server-side session state.

Use Codespaces or local Docker for the full application.

---

## Option C — Local Docker: full application on your machine

From the repository root:

```bash
make demo-open
```

Equivalent:

```bash
bash agent/scripts/start_demo.sh --open
```

Open:

```text
http://localhost:8000/
```

---

# Recommended portfolio setup

Use both GitHub deployment modes:

## Public resume / LinkedIn link

Use the GitHub Pages static preview.

This gives reviewers a URL that opens immediately with no setup.

## Interview / technical walkthrough

Use the GitHub Codespaces full application.

This lets you demonstrate:

- FastAPI;
- MySQL;
- Workflow v1 vs Agent v1;
- prompt/tool inspection;
- stateful follow-up;
- raw tool traces;
- custom scenarios;
- Markdown/JSON export.

---

# Codespaces architecture

```text
Browser
  |
  | GitHub forwarded port 8000
  v
Codespace VM
  |
  +-- FastAPI agent container
  |
  +-- MySQL container
  |
  +-- persistent Docker volumes
```

The browser connects to GitHub's forwarded port; the FastAPI app continues to use the Docker-in-Docker Compose stack inside the codespace.

---

# GitHub Pages architecture

```text
Browser
  |
  v
GitHub Pages
  |
  v
Static HTML + JavaScript
  |
  +-- embedded Scenario V1 benchmark
  +-- browser-side scenario calculation
```

No server or database is involved.

---

# Optional OpenAI mode in Codespaces

If you later want the full Codespaces application to use the real OpenAI backend:

1. add the API key to your Codespaces secrets;
2. set `MODEL_BACKEND=openai`;
3. restart the app.

Do not commit an API key to the repository.

The free default remains `mock`.

---

# Troubleshooting Codespaces

## The UI does not open

Open the **Ports** panel and look for port 8000.

## Port 8000 is not listed

In the Codespaces terminal:

```bash
make demo-open
```

or:

```bash
bash agent/scripts/start_demo.sh
```

## Demo readiness is incomplete

Run:

```bash
make demo-reset
make demo
```

## Need the forwarded URL

The launcher prints it automatically when the Codespaces environment variables are present.

## Need logs

```bash
docker compose logs db agent
```

---

# Troubleshooting GitHub Pages

## Workflow validates but does not deploy

Make sure:

**Settings → Pages → Build and deployment → Source → GitHub Actions**

is enabled.

## Pages link is 404

Wait for the **Deploy static portfolio demo to GitHub Pages** workflow to complete and use the URL from the deployment result.

## Interactive scenario works but no database/tool trace is available

That is expected. Pages is intentionally the static presentation version. Use Codespaces for the full system.
