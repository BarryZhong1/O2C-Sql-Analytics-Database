from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

from sqlalchemy import create_engine, text


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+pymysql://app:app_pw@127.0.0.1:3306/o2c",
)
OUTPUT_PATH = Path(
    os.getenv("BENCHMARK_OUTPUT", "agent/benchmark_results.json")
)

engine = create_engine(DATABASE_URL, pool_pre_ping=True, future=True)


def fetch_one(sql: str) -> dict[str, Any]:
    with engine.connect() as conn:
        row = conn.execute(text(sql)).mappings().one()
    return dict(row)


def fetch_all(sql: str) -> list[dict[str, Any]]:
    with engine.connect() as conn:
        rows = conn.execute(text(sql)).mappings().all()
    return [dict(row) for row in rows]


def as_float(value: Any) -> float | None:
    if value is None:
        return None
    return float(value)


def stage_metrics() -> dict[str, dict[str, float | int | None]]:
    rows = fetch_all(
        """
        SELECT
            CASE
                WHEN order_ts >= '2024-04-01' AND order_ts < '2024-07-01' THEN 'Q2'
                WHEN order_ts >= '2024-07-01' AND order_ts < '2024-10-01' THEN 'Q3'
            END AS period,
            COUNT(*) AS orders,
            AVG(total_o2c_cycle_days) AS total_o2c_cycle_days,
            AVG(order_to_ship_days) AS order_to_ship_days,
            AVG(ship_to_invoice_days) AS ship_to_invoice_days,
            AVG(invoice_to_payment_days) AS invoice_to_payment_days
        FROM vw_operational_performance
        WHERE order_ts >= '2024-04-01'
          AND order_ts < '2024-10-01'
        GROUP BY period
        ORDER BY period
        """
    )
    result: dict[str, dict[str, float | int | None]] = {}
    for row in rows:
        result[str(row["period"])] = {
            "orders": int(row["orders"]),
            "total_o2c_cycle_days": as_float(row["total_o2c_cycle_days"]),
            "order_to_ship_days": as_float(row["order_to_ship_days"]),
            "ship_to_invoice_days": as_float(row["ship_to_invoice_days"]),
            "invoice_to_payment_days": as_float(row["invoice_to_payment_days"]),
        }
    return result


def channel_metrics() -> dict[str, dict[str, dict[str, float | int | None]]]:
    rows = fetch_all(
        """
        SELECT
            CASE
                WHEN order_ts >= '2024-04-01' AND order_ts < '2024-07-01' THEN 'Q2'
                WHEN order_ts >= '2024-07-01' AND order_ts < '2024-10-01' THEN 'Q3'
            END AS period,
            channel,
            COUNT(*) AS orders,
            AVG(order_to_ship_days) AS order_to_ship_days,
            AVG(total_o2c_cycle_days) AS total_o2c_cycle_days
        FROM vw_operational_performance
        WHERE order_ts >= '2024-04-01'
          AND order_ts < '2024-10-01'
        GROUP BY period, channel
        ORDER BY period, channel
        """
    )
    result: dict[str, dict[str, dict[str, float | int | None]]] = {}
    for row in rows:
        period = str(row["period"])
        channel = str(row["channel"])
        result.setdefault(period, {})[channel] = {
            "orders": int(row["orders"]),
            "order_to_ship_days": as_float(row["order_to_ship_days"]),
            "total_o2c_cycle_days": as_float(row["total_o2c_cycle_days"]),
        }
    return result


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    registry = fetch_one(
        """
        SELECT
            scenario_id,
            primary_order_count,
            secondary_invoice_count
        FROM agent_scenario_registry
        WHERE scenario_id = 'scenario_v1_marketplace_bottleneck'
        """
    )

    stages = stage_metrics()
    channels = channel_metrics()

    failures: list[str] = []

    require("Q2" in stages and "Q3" in stages, "Q2/Q3 stage metrics are missing", failures)
    require(
        int(registry["primary_order_count"]) > 0,
        "Primary Marketplace cohort is empty",
        failures,
    )
    require(
        int(registry["secondary_invoice_count"]) > 0,
        "Secondary Enterprise invoice cohort is empty",
        failures,
    )

    if "Q2" in stages and "Q3" in stages:
        q2 = stages["Q2"]
        q3 = stages["Q3"]

        total_delta = float(q3["total_o2c_cycle_days"]) - float(q2["total_o2c_cycle_days"])
        ship_delta = float(q3["order_to_ship_days"]) - float(q2["order_to_ship_days"])
        invoice_delta = float(q3["ship_to_invoice_days"]) - float(q2["ship_to_invoice_days"])
        payment_delta = float(q3["invoice_to_payment_days"]) - float(q2["invoice_to_payment_days"])

        require(total_delta > 0.25, f"Total O2C did not deteriorate enough: {total_delta:.3f}", failures)
        require(ship_delta > 0.25, f"Order-to-ship did not deteriorate enough: {ship_delta:.3f}", failures)
        require(
            ship_delta > invoice_delta and ship_delta > payment_delta,
            (
                "Order-to-ship is not the largest stage deterioration: "
                f"ship={ship_delta:.3f}, ship_to_invoice={invoice_delta:.3f}, "
                f"invoice_to_payment={payment_delta:.3f}"
            ),
            failures,
        )
    else:
        total_delta = ship_delta = invoice_delta = payment_delta = None

    q2_market = channels.get("Q2", {}).get("Marketplace")
    q3_market = channels.get("Q3", {}).get("Marketplace")
    q3_web = channels.get("Q3", {}).get("Web")

    require(q2_market is not None, "Q2 Marketplace channel is missing", failures)
    require(q3_market is not None, "Q3 Marketplace channel is missing", failures)
    require(q3_web is not None, "Q3 Web channel is missing", failures)

    market_delta = None
    q3_market_vs_web = None
    if q2_market and q3_market:
        market_delta = float(q3_market["order_to_ship_days"]) - float(q2_market["order_to_ship_days"])
        require(
            market_delta > 2.0,
            f"Marketplace deterioration is too weak: {market_delta:.3f} days",
            failures,
        )

    if q3_market and q3_web:
        q3_market_vs_web = float(q3_market["order_to_ship_days"]) - float(q3_web["order_to_ship_days"])
        require(
            q3_market_vs_web > 1.5,
            f"Q3 Marketplace signal is not clearly above Web: {q3_market_vs_web:.3f} days",
            failures,
        )

    result = {
        "scenario_id": registry["scenario_id"],
        "cohorts": {
            "primary_order_count": int(registry["primary_order_count"]),
            "secondary_invoice_count": int(registry["secondary_invoice_count"]),
        },
        "stage_metrics": stages,
        "channel_metrics": channels,
        "derived": {
            "q3_minus_q2_total_o2c_days": total_delta,
            "q3_minus_q2_order_to_ship_days": ship_delta,
            "q3_minus_q2_ship_to_invoice_days": invoice_delta,
            "q3_minus_q2_invoice_to_payment_days": payment_delta,
            "q3_minus_q2_marketplace_order_to_ship_days": market_delta,
            "q3_marketplace_minus_web_order_to_ship_days": q3_market_vs_web,
        },
        "status": "PASS" if not failures else "FAIL",
        "failures": failures,
    }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(result, indent=2, default=str), encoding="utf-8")
    print(json.dumps(result, indent=2, default=str))

    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
