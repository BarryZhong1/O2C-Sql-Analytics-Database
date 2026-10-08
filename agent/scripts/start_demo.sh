#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

KEEP_DATA=0
if [[ "${1:-}" == "--keep-data" ]]; then
  KEEP_DATA=1
fi

export MODEL_BACKEND="${MODEL_BACKEND:-mock}"

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

echo
echo "Demo is ready."
echo "Open: http://localhost:8000/"
echo
echo "Recommended first prompt:"
echo "Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. Identify the stage that deteriorated most, drill into the strongest driver, and test a realistic improvement scenario."
echo
echo "Active backend:"
cat /tmp/o2c-agent-health.json
echo
echo
echo "Stop the demo with: docker compose down"
echo "Delete demo data/state with: docker compose down -v"
