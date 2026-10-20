from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


DEFAULT_QUESTION = (
    "Investigate why O2C cycle time worsened in Q3 2024 versus Q2 2024. "
    "Identify the stage that deteriorated most, drill into the strongest driver, "
    "and test a realistic improvement scenario."
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the portfolio demo through the local FastAPI service."
    )
    parser.add_argument(
        "--url",
        default="http://localhost:8000",
        help="Base URL for the running demo API.",
    )
    parser.add_argument(
        "--question",
        default=DEFAULT_QUESTION,
        help="Business question to send to the agent.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional path for the raw JSON response.",
    )
    return parser.parse_args()


def post_json(url: str, payload: dict) -> dict:
    body = json.dumps(payload).encode("utf-8")
    request = Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"API returned HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(
            "Could not reach the demo API. Run agent/scripts/start_demo.sh first."
        ) from exc


def main() -> int:
    args = parse_args()
    endpoint = args.url.rstrip("/") + "/agent/ask"

    payload = post_json(
        endpoint,
        {"question": args.question, "profile_id": None},
    )

    print("=" * 72)
    print("O2C PROCESS IMPROVEMENT AGENT — PORTFOLIO DEMO")
    print("=" * 72)
    print(f"Backend: {payload.get('backend', 'unknown')}")
    print(f"Tool calls: {payload.get('tool_call_count', 0)}")
    print()

    trace = payload.get("tool_trace") or []
    if trace:
        print("Investigation path:")
        for index, item in enumerate(trace, start=1):
            print(f"  {index}. {item.get('tool')}")
        print()

    print(payload.get("answer") or "No answer returned.")

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(payload, indent=2, default=str),
            encoding="utf-8",
        )
        print()
        print(f"Raw response saved to: {args.output}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"Demo failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
