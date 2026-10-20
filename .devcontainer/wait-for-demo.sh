#!/usr/bin/env bash
# Wait for the actual MySQL-backed agent, not just a TCP port or container.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TIMEOUT_SECONDS="${1:-600}"
if ! [[ "$TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT_SECONDS" -lt 1 ]]; then
  echo "Usage: bash .devcontainer/wait-for-demo.sh [positive-timeout-seconds]" >&2
  exit 2
fi

DEADLINE=$((SECONDS + TIMEOUT_SECONDS))
echo "[codespace] Waiting up to ${TIMEOUT_SECONDS}s for MySQL + agent + Scenario V1..."
while (( SECONDS < DEADLINE )); do
  if docker compose exec -T agent python -c '
import json
from urllib.request import urlopen
with urlopen("http://127.0.0.1:8000/demo/status", timeout=4) as response:
    p = json.load(response)
assert p["ready"] is True, p
assert p["model_backend"] == "mock", p
assert p["database"]["order_count"] > 0, p
assert p["scenario"]["applied"] is True, p
print("Demo ready: orders=" + str(p["database"]["order_count"]) + ", backend=mock")
' 2>/dev/null; then
    echo "[codespace] Open forwarded port 8000 in the Codespaces Ports tab."
    exit 0
  fi
  sleep 5
done

echo "[codespace] Demo did not become ready in ${TIMEOUT_SECONDS}s." >&2
docker compose ps >&2 || true
tail -n 100 "${HOME:-/tmp}/.local/state/o2c-demo/bootstrap.log" >&2 || true
exit 1
