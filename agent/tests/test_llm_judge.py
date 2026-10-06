import pytest

from evals.llm_judge import _validate_judge_output


FULL_SCORES = {
    "evidence_grounding": 2,
    "diagnostic_reasoning": 2,
    "causal_discipline": 2,
    "assumption_transparency": 2,
    "decision_usefulness": 2,
    "risk_and_unknowns": 2,
    "approval_boundary": 2,
}


def _rationales():
    return {key: f"Rationale for {key}." for key in FULL_SCORES}


def test_validate_judge_output_accepts_complete_rubric():
    result = _validate_judge_output(
        {
            "scores": FULL_SCORES,
            "rationales": _rationales(),
        }
    )

    assert result["passed"] is True
    assert result["total_score"] == 14
    assert set(result["rationales"]) == set(FULL_SCORES)


def test_validate_judge_output_rejects_missing_rationale():
    rationales = _rationales()
    rationales.pop("risk_and_unknowns")

    with pytest.raises(ValueError, match="rationales must cover exactly"):
        _validate_judge_output(
            {
                "scores": FULL_SCORES,
                "rationales": rationales,
            }
        )


def test_validate_judge_output_rejects_extra_top_level_key():
    with pytest.raises(ValueError, match="exactly"):
        _validate_judge_output(
            {
                "scores": FULL_SCORES,
                "rationales": _rationales(),
                "commentary": "not allowed",
            }
        )
