#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-}"

echo "[codespace] Preparing O2C portfolio demo..."

if curl --fail --silent http://localhost:8000/demo/status >/tmp/o2c-codespace-status.json 2>/dev/null; then
  if python3 - <<'PY'
import json
p = json.load(open("/tmp/o2c-codespace-status.json"))
raise SystemExit(0 if p.get("ready") else 1)
PY
  then
    echo "[codespace] Demo is already ready."
    exit 0
  fi
fi

if [[ "$MODE" == "--clean" ]]; then
  bash agent/scripts/start_demo.sh
  exit 0
fi

# On a normal Codespaces restart, prefer reusing the persisted Docker volume.
if bash agent/scripts/start_demo.sh --keep-data; then
  exit 0
fi

echo "[codespace] Existing data was not usable; rebuilding the controlled demo dataset."
bash agent/scripts/start_demo.sh
