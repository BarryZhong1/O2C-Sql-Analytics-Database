-- Validation queries for Scenario V1.
-- Goal: verify that the injected Q3 Marketplace fulfillment deterioration is
-- measurable and larger than the secondary payment-delay confounder.

USE o2c;

-- 1. Registry / cohort counts
SELECT *
FROM agent_scenario_registry
WHERE scenario_id = 'scenario_v1_marketplace_bottleneck';

-- 2. Q2 vs Q3 overall stage performance
WITH period_metrics AS (
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
)
SELECT
    period,
    orders,
    ROUND(total_o2c_cycle_days, 2) AS total_o2c_cycle_days,
    ROUND(order_to_ship_days, 2) AS order_to_ship_days,
    ROUND(ship_to_invoice_days, 2) AS ship_to_invoice_days,
    ROUND(invoice_to_payment_days, 2) AS invoice_to_payment_days
FROM period_metrics
ORDER BY period;

-- 3. Stage deterioration: Q3 minus Q2
WITH period_metrics AS (
    SELECT
        CASE
            WHEN order_ts >= '2024-04-01' AND order_ts < '2024-07-01' THEN 'Q2'
            WHEN order_ts >= '2024-07-01' AND order_ts < '2024-10-01' THEN 'Q3'
        END AS period,
        AVG(total_o2c_cycle_days) AS total_o2c_cycle_days,
        AVG(order_to_ship_days) AS order_to_ship_days,
        AVG(ship_to_invoice_days) AS ship_to_invoice_days,
        AVG(invoice_to_payment_days) AS invoice_to_payment_days
    FROM vw_operational_performance
    WHERE order_ts >= '2024-04-01'
      AND order_ts < '2024-10-01'
    GROUP BY period
),
pivoted AS (
    SELECT
        MAX(CASE WHEN period = 'Q2' THEN total_o2c_cycle_days END) AS q2_total,
        MAX(CASE WHEN period = 'Q3' THEN total_o2c_cycle_days END) AS q3_total,
        MAX(CASE WHEN period = 'Q2' THEN order_to_ship_days END) AS q2_order_ship,
        MAX(CASE WHEN period = 'Q3' THEN order_to_ship_days END) AS q3_order_ship,
        MAX(CASE WHEN period = 'Q2' THEN ship_to_invoice_days END) AS q2_ship_invoice,
        MAX(CASE WHEN period = 'Q3' THEN ship_to_invoice_days END) AS q3_ship_invoice,
        MAX(CASE WHEN period = 'Q2' THEN invoice_to_payment_days END) AS q2_invoice_payment,
        MAX(CASE WHEN period = 'Q3' THEN invoice_to_payment_days END) AS q3_invoice_payment
    FROM period_metrics
)
SELECT 'total_o2c_cycle_days' AS metric, ROUND(q3_total - q2_total, 2) AS q3_minus_q2
FROM pivoted
UNION ALL
SELECT 'order_to_ship_days', ROUND(q3_order_ship - q2_order_ship, 2)
FROM pivoted
UNION ALL
SELECT 'ship_to_invoice_days', ROUND(q3_ship_invoice - q2_ship_invoice, 2)
FROM pivoted
UNION ALL
SELECT 'invoice_to_payment_days', ROUND(q3_invoice_payment - q2_invoice_payment, 2)
FROM pivoted;

-- 4. Channel drill-down: expected primary signal is Q3 Marketplace.
SELECT
    CASE
        WHEN order_ts >= '2024-04-01' AND order_ts < '2024-07-01' THEN 'Q2'
        WHEN order_ts >= '2024-07-01' AND order_ts < '2024-10-01' THEN 'Q3'
    END AS period,
    channel,
    COUNT(*) AS orders,
    ROUND(AVG(order_to_ship_days), 2) AS avg_order_to_ship_days,
    ROUND(AVG(total_o2c_cycle_days), 2) AS avg_total_o2c_cycle_days
FROM vw_operational_performance
WHERE order_ts >= '2024-04-01'
  AND order_ts < '2024-10-01'
GROUP BY period, channel
ORDER BY period, avg_order_to_ship_days DESC;

-- 5. Segment check: useful to ensure customer segment alone does not explain
-- the primary Marketplace effect.
SELECT
    CASE
        WHEN order_ts >= '2024-04-01' AND order_ts < '2024-07-01' THEN 'Q2'
        WHEN order_ts >= '2024-07-01' AND order_ts < '2024-10-01' THEN 'Q3'
    END AS period,
    segment,
    COUNT(*) AS orders,
    ROUND(AVG(order_to_ship_days), 2) AS avg_order_to_ship_days,
    ROUND(AVG(invoice_to_payment_days), 2) AS avg_invoice_to_payment_days
FROM vw_operational_performance
WHERE order_ts >= '2024-04-01'
  AND order_ts < '2024-10-01'
GROUP BY period, segment
ORDER BY period, segment;

-- 6. Direct sanity check of the primary cohort.
SELECT
    COUNT(*) AS affected_marketplace_orders,
    ROUND(AVG(v.order_to_ship_days), 2) AS avg_order_to_ship_days,
    ROUND(AVG(v.total_o2c_cycle_days), 2) AS avg_total_o2c_cycle_days
FROM vw_operational_performance v
JOIN agent_scenario_v1_shipment_backup b
  ON b.order_id = v.order_id;
