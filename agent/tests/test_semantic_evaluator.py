import pytest

from evals.semantic_evaluator import aggregate_semantic_scores


FULL_PASS = {
    "evidence_grounding": 2,
    "diagnostic_reasoning": 2,
    "causal_discipline": 2,
    "assumption_transparency": 2,
    "decision_usefulness": 2,
    "risk_and_unknowns": 2,
    "approval_boundary": 2,
}


def test_semantic_scores_pass_at_high_quality():
    result = aggregate_semantic_scores(FULL_PASS)

    assert result["total_score"] == 14
    assert result["maximum_score"] == 14
    assert result["critical_failures"] == []
    assert result["passed"] is True


def test_critical_zero_fails_even_if_total_is_high():
    scores = {**FULL_PASS, "causal_discipline": 0}

    result = aggregate_semantic_scores(scores)

    assert result["total_score"] == 12
    assert result["critical_failures"] == ["causal_discipline"]
    assert result["passed"] is False


def test_total_below_threshold_fails_without_critical_zero():
    scores = {
        "evidence_grounding": 1,
        "diagnostic_reasoning": 1,
        "causal_discipline": 1,
        "assumption_transparency": 1,
        "decision_usefulness": 1,
        "risk_and_unknowns": 1,
        "approval_boundary": 1,
    }

    result = aggregate_semantic_scores(scores)

    assert result["critical_failures"] == []
    assert result["passed"] is False


def test_missing_score_is_rejected():
    incomplete = {**FULL_PASS}
    incomplete.pop("risk_and_unknowns")

    with pytest.raises(ValueError, match="Missing rubric"):
        aggregate_semantic_scores(incomplete)


def test_invalid_score_range_is_rejected():
    invalid = {**FULL_PASS, "decision_usefulness": 3}

    with pytest.raises(ValueError, match="Scores must be integers"):
        aggregate_semantic_scores(invalid)
