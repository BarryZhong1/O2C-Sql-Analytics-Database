#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
LOG_DIR="$HOME/.local/state/o2c-demo"
mkdir -p "$LOG_DIR"

if curl --silent --fail --max-time 2 http://127.0.0.1:8000/_codespace_bridge_probe >/dev/null; then
  echo "[codespace] Port bridge already listening."
  exit 0
fi
if curl --silent --fail --max-time 2 http://127.0.0.1:8000/health >/dev/null; then
  echo "[codespace] Agent directly reachable from workspace; bridge not needed."
  exit 0
fi

nohup python3 "$ROOT_DIR/.devcontainer/port-bridge.py" \
  >>"$LOG_DIR/port-bridge.log" 2>&1 </dev/null &
sleep 1
if curl --silent --fail --max-time 2 http://127.0.0.1:8000/_codespace_bridge_probe >/dev/null; then
  echo "[codespace] Forwarded port 8000 now has a workspace listener."
else
  echo "[codespace] Port bridge failed; inspect $LOG_DIR/port-bridge.log" >&2
  exit 1
fi
