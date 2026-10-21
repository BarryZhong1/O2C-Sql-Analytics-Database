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
https://codespaces.new/BarryZhong1/O2C-Sql-Analytics-Database/tree/main
```

Then choose **Create codespace**.

The `.devcontainer/devcontainer.json` configuration automatically:

1. provisions Docker CLI access to the Codespaces host daemon;
2. forwards port 8000;
3. opens the repository workspace **without blocking on the database setup**;
4. starts `.devcontainer/bootstrap.sh` in the background, initializing Scenario V1 on the first creation;
5. starts the FastAPI + MySQL stack, keeping Docker volumes on subsequent starts;
6. opens the forwarded analyst UI when port 8000 becomes available.

**Why async startup?** The first MySQL seed and container image build can take several
minutes. A blocking `postCreateCommand` previously kept the editor showing
"Building codespace" until this finished. The new `postStartCommand` launches
the same demo in the background so you can use the editor while it initializes.

If the browser does not open automatically, use the **Ports** tab and open the forwarded port labeled:

> O2C Process Improvement Agent

### Temporarily share the full Codespaces UI

If you want another person to open the running full demo while your codespace is active:

1. open the **Ports** tab in Codespaces;
2. find port **8000**;
3. change **Port Visibility** to **Public** if your GitHub/account policy allows it;
4. copy the forwarded URL.

Treat this as temporary demonstration hosting. The URL works only while the codespace/forwarded port remains available.

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

Now that the feature has been merged to `main`:

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

The browser connects to GitHub's forwarded port; the FastAPI app runs through Docker Compose using the Codespaces host Docker daemon from inside the devcontainer.

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

## Editor says `Opening Remote` or shows `${localWorkspaceFolder}`

That text may appear in VS Code while a remote workspace is still connecting; it
is **not a path used by the repository**. The devcontainer deliberately uses
GitHub Codespaces' native workspace mount and does not set `workspaceMount`
or `workspaceFolder` to a potentially invalid local substitution.

Open the Codespace **in your browser** from GitHub's Codespaces page if the
desktop VS Code connection stalls. The repository itself should open before
the MySQL database finishes loading.

After the terminal becomes available:

```bash
# Watch automatic startup progress
tail -f "$HOME/.local/state/o2c-demo/bootstrap.log"

# Wait until real MySQL-backed Scenario V1 endpoints are ready
bash .devcontainer/wait-for-demo.sh 600
```

If startup fails or never begins, retry manually:

```bash
bash .devcontainer/start-background.sh
```

## Browser returns HTTP 502 at the forwarded port

The Docker Compose API runs in a sibling container through Docker-outside-of-Docker.
A healthy `agent` container does not necessarily imply port 8000 is reachable
from the Codespaces workspace. The devcontainer therefore starts a small
standard-library HTTP bridge at port 8000 **inside the workspace** before
building MySQL and the API. It shows a temporary startup page while the backend
initializes and forwards requests to FastAPI as soon as it responds.

In an **existing** Codespace, apply the latest code then restart the launcher:

```bash
git pull --ff-only origin main
bash .devcontainer/start-background.sh
bash .devcontainer/wait-for-demo.sh 600
```

Then open port 8000 from the Ports tab. No new Codespace is normally needed.

For diagnostics:

```bash
curl -i http://127.0.0.1:8000/_codespace_bridge_probe
curl -i http://127.0.0.1:8000/health
docker compose ps
tail -n 80 "$HOME/.local/state/o2c-demo/bootstrap.log"
tail -n 40 "$HOME/.local/state/o2c-demo/port-bridge.log"
```

A response of `{"bridge":"ok"}` confirms the workspace listener is running;
`/health` returning `{"status":"ok"...}` confirms that requests are reaching
the real agent backend. If both local checks succeed but the forwarded
`*.app.github.dev` URL still returns 502, remove and add port 8000 in the
Ports tab to refresh a potentially stale forwarding entry.

## The UI does not open

Open the **Ports** panel and look for port 8000. It may take several minutes
for the port to appear on the first build.

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
