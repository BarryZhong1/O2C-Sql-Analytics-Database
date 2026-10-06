from evals.trace_evaluator import evaluate_agent_run, evaluate_trace, get_case


def test_scenario_case_accepts_correct_simulator_call():
    case = get_case("eval_005")
    trace = [
        {
            "tool": "simulate_stage_improvement",
            "arguments": {
                "start_date": "2024-07-01",
                "end_date": "2024-09-30",
                "order_to_ship_reduction_pct": 25,
                "ship_to_invoice_reduction_pct": 0,
                "invoice_to_payment_reduction_pct": 0,
            },
            "result": {"scenario": {"days_saved": 0.52}},
        }
    ]

    result = evaluate_trace(case, trace)

    assert result["trace_checks_passed"] is True
    assert result["tool_sequence"] == ["simulate_stage_improvement"]


def test_scenario_case_rejects_wrong_stage_reduction():
    case = get_case("eval_005")
    trace = [
        {
            "tool": "simulate_stage_improvement",
            "arguments": {
                "start_date": "2024-07-01",
                "end_date": "2024-09-30",
                "order_to_ship_reduction_pct": 0,
                "ship_to_invoice_reduction_pct": 0,
                "invoice_to_payment_reduction_pct": 25,
            },
            "result": {},
        }
    ]

    result = evaluate_trace(case, trace)

    assert result["trace_checks_passed"] is False


def test_payment_terms_case_allows_due_date_relative_metric():
    case = get_case("eval_004")
    trace = [
        {
            "tool": "analyze_process",
            "arguments": {
                "metric": "payment_delay_vs_due_days",
                "start_date": "2024-07-01",
                "end_date": "2024-09-30",
                "group_by": "segment",
                "compare_start_date": None,
                "compare_end_date": None,
            },
            "result": {},
        }
    ]

    result = evaluate_trace(case, trace)

    assert result["trace_checks_passed"] is True


def test_payment_terms_case_rejects_raw_invoice_duration_only():
    case = get_case("eval_004")
    trace = [
        {
            "tool": "analyze_process",
            "arguments": {
                "metric": "invoice_to_payment_days",
                "start_date": "2024-07-01",
                "end_date": "2024-09-30",
                "group_by": "segment",
                "compare_start_date": None,
                "compare_end_date": None,
            },
            "result": {},
        }
    ]

    result = evaluate_trace(case, trace)

    assert result["trace_checks_passed"] is False


def test_causal_challenge_requires_analytics_and_context_retrieval():
    case = get_case("eval_006")
    analytics_call = {
        "tool": "analyze_process",
        "arguments": {
            "metric": "order_to_ship_days",
            "start_date": "2024-07-01",
            "end_date": "2024-09-30",
            "group_by": "channel",
            "compare_start_date": "2024-04-01",
            "compare_end_date": "2024-06-30",
        },
        "result": {},
    }

    without_context = evaluate_trace(case, [analytics_call])
    assert without_context["trace_checks_passed"] is False

    with_context = evaluate_trace(
        case,
        [
            analytics_call,
            {
                "tool": "retrieve_policy",
                "arguments": {
                    "query": "Marketplace promotional review process change",
                    "top_k": 3,
                },
                "result": {"matches": []},
            },
        ],
    )
    assert with_context["trace_checks_passed"] is True


def test_agent_run_requires_trace_and_reports_answer_presence():
    run = {
        "answer": "Observed evidence...",
        "tool_trace": [
            {
                "tool": "compare_stage_performance",
                "arguments": {
                    "start_date": "2024-07-01",
                    "end_date": "2024-09-30",
                    "compare_start_date": "2024-04-01",
                    "compare_end_date": "2024-06-30",
                },
                "result": {},
            }
        ],
    }

    result = evaluate_agent_run("eval_001", run)

    assert result["trace_checks_passed"] is True
    assert result["answer_present"] is True
