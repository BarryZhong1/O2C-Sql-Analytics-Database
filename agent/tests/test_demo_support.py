from app.agent import TOOLS
from app.main import demo_design
from scripts.build_demo_report import build_report


def test_demo_design_exposes_versioned_prompt_and_tools():
    payload = demo_design()

    assert payload["role"].startswith("AI business process improvement analyst")
    assert len(payload["instruction_rules"]) == 12
    assert len(payload["tools"]) == 5
    assert len(payload["system_prompt_version"]) == 12
    assert len(payload["tool_catalog_version"]) == 12
    assert "Never invent KPI values." in payload["instruction_rules"]
    assert any("human decision gate" in rule for rule in payload["instruction_rules"])
    assert any(tool["name"] == "simulate_stage_improvement" for tool in payload["tools"])
    assert "human approval" in payload["boundaries"]["execution"].lower()


def test_build_demo_report_includes_evidence_and_versions():
    payload = {
        "backend": "mock",
        "tool_call_count": 4,
        "answer": (
            "FINDING\nOrder-to-ship deteriorated.\n\n"
            "PROPOSED IMPLEMENTATION PLAN\n- Run a pilot."
        ),
        "tool_trace": [
            {
                "tool": "compare_stage_performance",
                "arguments": {},
                "result": {
                    "current_period": {"observed_total_o2c_cycle_days": 33.71},
                    "comparison_period": {"observed_total_o2c_cycle_days": 33.28},
                    "deterioration_rank": [
                        {
                            "stage": "order_to_ship_days",
                            "comparison_days": 1.48,
                            "current_days": 2.09,
                            "absolute_change_days": 0.61,
                        }
                    ],
                },
            },
            {
                "tool": "analyze_process",
                "arguments": {"group_by": "channel"},
                "result": {
                    "group_change_summary": {
                        "deterioration_rank": [
                            {
                                "dimension_value": "Marketplace",
                                "comparison_value": 1.45,
                                "current_value": 4.62,
                                "absolute_change": 3.17,
                            }
                        ]
                    }
                },
            },
            {
                "tool": "retrieve_policy",
                "arguments": {},
                "result": {
                    "matches": [
                        {
                            "source": "process_change_log.md",
                            "paragraph": "Manual Marketplace review began July 1.",
                        }
                    ]
                },
            },
            {
                "tool": "simulate_stage_improvement",
                "arguments": {},
                "result": {
                    "baseline": {"modeled_cash_cycle_days": 33.58},
                    "scenario": {
                        "modeled_cash_cycle_days": 33.06,
                        "days_saved": 0.52,
                        "percent_improvement": 1.56,
                    },
                },
            },
        ],
    }
    design = {
        "system_prompt_version": "prompt123456",
        "tool_catalog_version": "tools1234567",
    }

    report = build_report(payload, "Why did O2C worsen?", design)

    assert "Q2 total O2C cycle: **33.28 days**" in report
    assert "| Order → Ship | 1.48 | 2.09 | +0.61 |" in report
    assert "| Marketplace | 1.45 | 4.62 | +3.17 |" in report
    assert "Modeled days saved: **0.52 days**" in report
    assert "System prompt: **prompt123456**" in report
    assert "scripted mock mode" in report


def test_tool_surface_is_bounded_and_read_only():
    names = {tool["name"] for tool in TOOLS}
    assert names == {
        "analyze_process",
        "compare_stage_performance",
        "get_stage_baseline",
        "simulate_stage_improvement",
        "retrieve_policy",
    }

    forbidden_name_fragments = {
        "write",
        "update",
        "delete",
        "insert",
        "execute_sql",
        "send",
        "approve",
    }
    for name in names:
        lowered = name.lower()
        assert not any(fragment in lowered for fragment in forbidden_name_fragments)

    analyze = next(tool for tool in TOOLS if tool["name"] == "analyze_process")
    properties = analyze["parameters"]["properties"]
    assert "sql" not in properties
    assert "query" not in properties
    assert set(properties["group_by"]["enum"]) == {"segment", "channel", None}
    assert "order_to_ship_days" in properties["metric"]["enum"]
    assert analyze["parameters"]["additionalProperties"] is False
