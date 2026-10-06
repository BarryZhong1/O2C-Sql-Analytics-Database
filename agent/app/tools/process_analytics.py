from __future__ import annotations

from typing import Any

from sqlalchemy import text

from app.db import engine


METRICS = {
    "total_o2c_cycle_days": "AVG(total_o2c_cycle_days)",
    "order_to_ship_days": "AVG(order_to_ship_days)",
    "ship_to_delivery_days": "AVG(ship_to_delivery_days)",
    "ship_to_invoice_days": "AVG(ship_to_invoice_days)",
    "invoice_to_payment_days": "AVG(invoice_to_payment_days)",
    "payment_delay_vs_due_days": (
        "AVG(CASE WHEN first_payment_ts IS NOT NULL "
        "THEN DATEDIFF(first_payment_ts, due_date) END)"
    ),
    "late_payment_rate": (
        "AVG(CASE "
        "WHEN first_payment_ts IS NULL THEN NULL "
        "WHEN DATE(first_payment_ts) > due_date THEN 1 ELSE 0 END) * 100"
    ),
    "on_time_delivery_rate": (
        "AVG(CASE WHEN delivery_performance = 'ON_TIME' THEN 1 ELSE 0 END) * 100"
    ),
    "on_time_ship_rate": (
        "AVG(CASE WHEN ship_performance = 'ON_TIME' THEN 1 ELSE 0 END) * 100"
    ),
}

DIMENSIONS = {
    "segment": "segment",
    "channel": "channel",
}

CASH_CYCLE_STAGES = (
    "order_to_ship_days",
    "ship_to_invoice_days",
    "invoice_to_payment_days",
)


def _validate(metric: str, group_by: str | None) -> None:
    if metric not in METRICS:
        raise ValueError(f"Unsupported metric: {metric}")
    if group_by is not None and group_by not in DIMENSIONS:
        raise ValueError(f"Unsupported group_by: {group_by}")


def _period_result(
    metric: str,
    start_date: str,
    end_date: str,
    group_by: str | None = None,
) -> dict[str, Any]:
    _validate(metric, group_by)
    metric_sql = METRICS[metric]

    if group_by:
        dim_sql = DIMENSIONS[group_by]
        sql = text(
            f"""
            SELECT
                {dim_sql} AS dimension_value,
                COUNT(*) AS record_count,
                ROUND({metric_sql}, 2) AS metric_value
            FROM vw_operational_performance
            WHERE order_ts >= :start_date
              AND order_ts < DATE_ADD(:end_date, INTERVAL 1 DAY)
            GROUP BY {dim_sql}
            ORDER BY metric_value DESC
            """
        )
    else:
        sql = text(
            f"""
            SELECT
                COUNT(*) AS record_count,
                ROUND({metric_sql}, 2) AS metric_value
            FROM vw_operational_performance
            WHERE order_ts >= :start_date
              AND order_ts < DATE_ADD(:end_date, INTERVAL 1 DAY)
            """
        )

    with engine.connect() as conn:
        rows = [
            dict(row._mapping)
            for row in conn.execute(
                sql, {"start_date": start_date, "end_date": end_date}
            )
        ]

    return {
        "metric": metric,
        "start_date": start_date,
        "end_date": end_date,
        "group_by": group_by,
        "rows": rows,
    }


def analyze_process(
    metric: str,
    start_date: str,
    end_date: str,
    group_by: str | None = None,
    compare_start_date: str | None = None,
    compare_end_date: str | None = None,
) -> dict[str, Any]:
    """
    Analyze one approved O2C process metric over a date range.

    If a comparison period is supplied, the tool also returns absolute and
    percentage change for the ungrouped metric.

    Use payment_delay_vs_due_days or late_payment_rate when evaluating collection
    performance across customers with different contractual payment terms.
    """
    current = _period_result(metric, start_date, end_date, group_by)

    result: dict[str, Any] = {"current": current}

    if compare_start_date and compare_end_date:
        comparison = _period_result(
            metric,
            compare_start_date,
            compare_end_date,
            group_by,
        )
        result["comparison"] = comparison

        if not group_by and current["rows"] and comparison["rows"]:
            cur = current["rows"][0]["metric_value"]
            prev = comparison["rows"][0]["metric_value"]
            if cur is not None and prev is not None:
                result["change"] = {
                    "absolute": round(float(cur) - float(prev), 2),
                    "percent": (
                        round((float(cur) - float(prev)) / float(prev) * 100, 2)
                        if float(prev) != 0
                        else None
                    ),
                }

    return result


def compare_stage_performance(
    start_date: str,
    end_date: str,
    compare_start_date: str,
    compare_end_date: str,
) -> dict[str, Any]:
    """
    Compare the three sequential cash-cycle stages across two periods and rank
    them by deterioration.

    This prevents the common analytical mistake of treating the longest stage as
    the stage that worsened the most.
    """
    current = get_stage_baseline(start_date, end_date)
    comparison = get_stage_baseline(compare_start_date, compare_end_date)

    stage_changes: list[dict[str, Any]] = []
    for stage in CASH_CYCLE_STAGES:
        cur = current.get(stage)
        prev = comparison.get(stage)
        if cur is None or prev is None:
            stage_changes.append(
                {
                    "stage": stage,
                    "current_days": cur,
                    "comparison_days": prev,
                    "absolute_change_days": None,
                    "percent_change": None,
                }
            )
            continue

        cur_float = float(cur)
        prev_float = float(prev)
        stage_changes.append(
            {
                "stage": stage,
                "current_days": round(cur_float, 2),
                "comparison_days": round(prev_float, 2),
                "absolute_change_days": round(cur_float - prev_float, 2),
                "percent_change": (
                    round((cur_float - prev_float) / prev_float * 100, 2)
                    if prev_float != 0
                    else None
                ),
            }
        )

    ranked = sorted(
        stage_changes,
        key=lambda item: (
            item["absolute_change_days"] is not None,
            (
                item["absolute_change_days"]
                if item["absolute_change_days"] is not None
                else float("-inf")
            ),
        ),
        reverse=True,
    )

    return {
        "current_period": {
            "start_date": start_date,
            "end_date": end_date,
            "record_count": current.get("record_count"),
            "observed_total_o2c_cycle_days": current.get(
                "observed_total_o2c_cycle_days"
            ),
        },
        "comparison_period": {
            "start_date": compare_start_date,
            "end_date": compare_end_date,
            "record_count": comparison.get("record_count"),
            "observed_total_o2c_cycle_days": comparison.get(
                "observed_total_o2c_cycle_days"
            ),
        },
        "stage_changes": stage_changes,
        "deterioration_rank": ranked,
        "interpretation_note": (
            "Stages are ranked by period-over-period change, not by absolute "
            "duration. Positive change means the stage became slower."
        ),
    }


def get_stage_baseline(start_date: str, end_date: str) -> dict[str, Any]:
    """
    Return average stage times used by the deterministic scenario simulator.

    The O2C cash-cycle path is modeled as:
    order -> shipment -> invoice -> first payment.

    Delivery time is reported separately because it can run in parallel with
    billing/collection and should not be blindly added to the cash-cycle path.
    """
    sql = text(
        """
        SELECT
            COUNT(*) AS record_count,
            ROUND(AVG(order_to_ship_days), 2) AS order_to_ship_days,
            ROUND(AVG(ship_to_invoice_days), 2) AS ship_to_invoice_days,
            ROUND(AVG(invoice_to_payment_days), 2) AS invoice_to_payment_days,
            ROUND(AVG(ship_to_delivery_days), 2) AS ship_to_delivery_days,
            ROUND(
                AVG(
                    CASE
                        WHEN first_payment_ts IS NOT NULL
                        THEN DATEDIFF(first_payment_ts, due_date)
                    END
                ),
                2
            ) AS payment_delay_vs_due_days,
            ROUND(AVG(total_o2c_cycle_days), 2) AS observed_total_o2c_cycle_days
        FROM vw_operational_performance
        WHERE order_ts >= :start_date
          AND order_ts < DATE_ADD(:end_date, INTERVAL 1 DAY)
        """
    )

    with engine.connect() as conn:
        row = conn.execute(
            sql, {"start_date": start_date, "end_date": end_date}
        ).mappings().one()

    return {
        "start_date": start_date,
        "end_date": end_date,
        **dict(row),
    }
