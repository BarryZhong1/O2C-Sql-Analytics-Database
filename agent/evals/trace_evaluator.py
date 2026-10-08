from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_CASES_PATH = Path(__file__).with_name("eval_cases.json")


@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "passed": self.passed,
            "detail": self.detail,
        }


def load_cases(path: Path = DEFAULT_CASES_PATH) -> list[dict[str, Any]]:
    return json.loads(path.read_text(encoding="utf-8"))


def get_case(case_id: str, path: Path = DEFAULT_CASES_PATH) -> dict[str, Any]:
    for case in load_cases(path):
        if case["id"] == case_id:
            return case
    raise KeyError(f"Unknown eval case: {case_id}")


def _arguments_match(
    actual: dict[str, Any],
    expected: dict[str, Any],
) -> bool:
    """Return True when every expected argument equals the actual value.

    Requirements are intentionally partial: an eval can demand a business-critical
    argument such as group_by='channel' without prescribing unrelated arguments.
    """
    return all(actual.get(key) == value for key, value in expected.items())


def _one_of_match(
    actual: dict[str, Any],
    expected: dict[str, list[Any]],
) -> bool:
    return all(actual.get(key) in allowed for key, allowed in expected.items())


def _call_matches(call: dict[str, Any], requirement: dict[str, Any]) -> bool:
    if call.get("tool") != requirement.get("tool"):
        return False

    actual_args = call.get("arguments") or {}
    expected_args = requirement.get("arguments") or {}
    one_of = requirement.get("argument_one_of") or {}

    return _arguments_match(actual_args, expected_args) and _one_of_match(
        actual_args,
        one_of,
    )


def evaluate_trace(
    case: dict[str, Any],
    tool_trace: list[dict[str, Any]],
) -> dict[str, Any]:
    requirements = case.get("trace_requirements") or {}
    checks: list[CheckResult] = []

    for index, requirement in enumerate(requirements.get("required_calls", []), start=1):
        matches = [call for call in tool_trace if _call_matches(call, requirement)]
        checks.append(
            CheckResult(
                name=f"required_call_{index}:{requirement['tool']}",
                passed=bool(matches),
                detail=(
                    f"Found {len(matches)} matching call(s)."
                    if matches
                    else f"No call matched requirement: {requirement}"
                ),
            )
        )

    for index, requirement in enumerate(requirements.get("forbidden_calls", []), start=1):
        matches = [call for call in tool_trace if _call_matches(call, requirement)]
        checks.append(
            CheckResult(
                name=f"forbidden_call_{index}:{requirement['tool']}",
                passed=not matches,
                detail=(
                    "No forbidden call found."
                    if not matches
                    else f"Found {len(matches)} forbidden matching call(s)."
                ),
            )
        )

    forbidden_tools = set(requirements.get("forbidden_tools", []))
    used_forbidden = [
        call.get("tool")
        for call in tool_trace
        if call.get("tool") in forbidden_tools
    ]
    if forbidden_tools:
        checks.append(
            CheckResult(
                name="forbidden_tools",
                passed=not used_forbidden,
                detail=(
                    "No forbidden tools were used."
                    if not used_forbidden
                    else f"Forbidden tools used: {used_forbidden}"
                ),
            )
        )

    # Tool traces should be inspectable rather than silently malformed.
    malformed = [
        index
        for index, call in enumerate(tool_trace)
        if not isinstance(call, dict)
        or not call.get("tool")
        or not isinstance(call.get("arguments", {}), dict)
    ]
    checks.append(
        CheckResult(
            name="trace_shape",
            passed=not malformed,
            detail=(
                "All trace entries have tool names and argument objects."
                if not malformed
                else f"Malformed trace indexes: {malformed}"
            ),
        )
    )

    passed = all(check.passed for check in checks)
    return {
        "case_id": case["id"],
        "case_name": case["name"],
        "trace_checks_passed": passed,
        "checks": [check.to_dict() for check in checks],
        "tool_sequence": [call.get("tool") for call in tool_trace],
        "note": (
            "This evaluator checks deterministic tool-use requirements only. "
            "Answer quality, causal language, evidence synthesis, and other semantic "
            "criteria remain for rubric/LLM-as-Judge evaluation."
        ),
    }


def evaluate_agent_run(
    case_id: str,
    agent_run: dict[str, Any],
    cases_path: Path = DEFAULT_CASES_PATH,
) -> dict[str, Any]:
    case = get_case(case_id, cases_path)
    trace = agent_run.get("tool_trace")
    if not isinstance(trace, list):
        raise ValueError("Agent run must contain a list field named 'tool_trace'.")

    result = evaluate_trace(case, trace)
    result["answer_present"] = bool(str(agent_run.get("answer", "")).strip())
    return result
