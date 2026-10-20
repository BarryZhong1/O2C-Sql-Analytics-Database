#!/usr/bin/env bash
# Keep Codespaces/VS Code workspace activation independent of the slow Docker
# image build and Scenario V1 database generation.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${HOME:-/tmp}/.local/state/o2c-demo"
LOG_FILE="$LOG_DIR/bootstrap.log"
LOCK_FILE="$LOG_DIR/bootstrap.lock"
mkdir -p "$LOG_DIR"

if [[ ! -f "$ROOT_DIR/docker-compose.yml" || ! -f "$ROOT_DIR/agent/scripts/start_demo.sh" ]]; then
  echo "[codespace] Repository root was not found: $ROOT_DIR" >&2
  exit 1
fi

# A Codespace can trigger lifecycle hooks multiple times; flock prevents
# overlapping runs that might reset each other's database volumes.
nohup bash -c '
  set -euo pipefail
  root="$1"
  lock="$2"
  exec 9>"$lock"
  if ! flock -n 9; then
    echo "[codespace] Another bootstrap is in progress; reusing it."
    exit 0
  fi
  cd "$root"
  echo "[codespace] Bootstrap started: $(date -u +%FT%TZ)"
  if bash .devcontainer/bootstrap.sh; then
    echo "[codespace] Bootstrap complete: $(date -u +%FT%TZ)"
  else
    code=$?
    echo "[codespace] Bootstrap failed (exit $code). See log above."
    exit "$code"
  fi
' _ "$ROOT_DIR" "$LOCK_FILE" >>"$LOG_FILE" 2>&1 </dev/null &

echo "[codespace] Workspace is available; launching the demo in the background."
echo "[codespace] Follow setup: tail -f $LOG_FILE"
echo "[codespace] Check readiness: bash .devcontainer/wait-for-demo.sh"
