import pytest

from evals.llm_judge import _judge_text_format, _validate_judge_output
from evals.semantic_evaluator import load_rubric


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


def test_judge_text_format_requires_every_rubric_dimension():
    text_config = _judge_text_format(load_rubric())
    schema = text_config["format"]["schema"]

    assert text_config["format"]["type"] == "json_schema"
    assert text_config["format"]["strict"] is True
    assert set(schema["required"]) == {"scores", "rationales"}
    assert set(schema["properties"]["scores"]["required"]) == set(FULL_SCORES)
    assert set(schema["properties"]["rationales"]["required"]) == set(FULL_SCORES)
    assert schema["properties"]["scores"]["additionalProperties"] is False
    assert schema["properties"]["rationales"]["additionalProperties"] is False


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
