#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

KEEP_DATA=0
OPEN_BROWSER=0

for arg in "$@"; do
  case "$arg" in
    --keep-data)
      KEEP_DATA=1
      ;;
    --open)
      OPEN_BROWSER=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash agent/scripts/start_demo.sh [--keep-data] [--open]

Options:
  --keep-data  Reuse the existing MySQL/agentstate volumes instead of rebuilding
               the controlled Scenario V1 dataset.
  --open       Open http://localhost:8000/ in the default browser when ready.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run with --help for supported options."
      exit 2
      ;;
  esac
done

for command in docker curl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command '$command' was not found."
    if [[ "$command" == "docker" ]]; then
      echo "Install/start Docker Desktop or Docker Engine with Compose v2."
    fi
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but the Docker daemon is not available."
  echo "Start Docker Desktop/Engine and run this command again."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required (the 'docker compose' command)."
  exit 1
fi

export MODEL_BACKEND="${MODEL_BACKEND:-mock}"

if [[ "$MODEL_BACKEND" != "mock" && "$MODEL_BACKEND" != "openai" ]]; then
  echo "MODEL_BACKEND must be either 'mock' or 'openai'."
  exit 1
fi

if [[ "$MODEL_BACKEND" == "openai" && -z "${OPENAI_API_KEY:-}" ]]; then
  echo "MODEL_BACKEND=openai requires OPENAI_API_KEY."
  echo "For the free demo, run with MODEL_BACKEND=mock (the default)."
  exit 1
fi

if [[ "$KEEP_DATA" -eq 0 ]]; then
  echo "Resetting local demo containers/volumes for a reproducible dataset..."
  docker compose down -v --remove-orphans >/dev/null 2>&1 || true
fi

echo "Starting MySQL and agent in MODEL_BACKEND=$MODEL_BACKEND mode..."
docker compose up -d --build db agent

echo "Waiting for MySQL..."
for attempt in {1..60}; do
  if docker compose exec -T db sh -c     'mysql -h127.0.0.1 -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"'     >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 60 ]]; then
    echo "MySQL did not become ready in time."
    docker compose logs db
    exit 1
  fi
  sleep 2
done

if [[ "$KEEP_DATA" -eq 0 ]]; then
  echo "Loading base O2C dataset..."
  docker compose exec -T db sh -c     'mysql -h127.0.0.1 -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD"'     < sql/complete_setup.sql

  echo "Applying controlled Scenario V1..."
  docker compose exec -T db sh -c     'mysql -h127.0.0.1 -P3306 -uroot -p"$MYSQL_ROOT_PASSWORD"'     < agent/data/scenario_v1_marketplace_bottleneck.sql
else
  echo "--keep-data selected: existing database contents were retained."
fi

echo "Waiting for the agent API..."
for attempt in {1..60}; do
  if curl --fail --silent http://localhost:8000/health >/tmp/o2c-agent-health.json 2>/dev/null; then
    break
  fi
  if [[ "$attempt" -eq 60 ]]; then
    echo "Agent API did not become ready in time."
    docker compose logs agent
    exit 1
  fi
  sleep 2
done

echo "Checking demo readiness..."
if ! curl --fail --silent http://localhost:8000/demo/status >/tmp/o2c-demo-status.json; then
  echo "The API is running, but the demo readiness endpoint failed."
  docker compose logs agent
  exit 1
fi

python_cmd=""
if command -v python3 >/dev/null 2>&1; then
  python_cmd="python3"
elif command -v python >/dev/null 2>&1; then
  python_cmd="python"
fi

if [[ -n "$python_cmd" ]]; then
  "$python_cmd" - <<'PY'
import json
payload = json.load(open("/tmp/o2c-demo-status.json"))
if not payload.get("ready"):
    raise SystemExit("Demo setup is incomplete: " + json.dumps(payload, default=str))
print(
    "Ready: "
    f"{payload['database']['order_count']} orders, "
    f"Scenario V1={'applied' if payload['scenario']['applied'] else 'missing'}, "
    f"backend={payload['model_backend']}"
)
PY
else
  echo "Demo API is healthy. (Python not found locally, so readiness JSON was not pretty-printed.)"
  cat /tmp/o2c-demo-status.json
  echo
fi

echo
echo "Demo is ready."
echo "Local URL: http://localhost:8000/"
if [[ -n "${CODESPACE_NAME:-}" && -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
  echo "Codespaces URL: https://${CODESPACE_NAME}-8000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/"
fi
echo
echo "Recommended first action:"
echo "Click 'Full diagnosis' and then 'Run investigation'."
echo
echo "Active backend:"
cat /tmp/o2c-agent-health.json
echo
echo
echo "Stop the demo with: docker compose down"
echo "Delete demo data/state with: docker compose down -v"

if [[ "$OPEN_BROWSER" -eq 1 ]]; then
  if command -v open >/dev/null 2>&1; then
    open "http://localhost:8000/"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:8000/" >/dev/null 2>&1 || true
  else
    echo "Could not find a supported browser-open command; open the URL manually."
  fi
fi
