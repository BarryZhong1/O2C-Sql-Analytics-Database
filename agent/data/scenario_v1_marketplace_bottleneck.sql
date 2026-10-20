-- Scenario V1: Marketplace fulfillment bottleneck
-- Apply AFTER the base O2C synthetic dataset and business views are loaded.
--
-- Primary injected mechanism:
--   Q3 Marketplace orders selected deterministically (~70%) receive +4 days
--   in order-to-ship time. All downstream timestamps move by the same amount
--   so the injected deterioration remains concentrated in order-to-ship.
--
-- Secondary confounder:
--   Q3 Enterprise paid invoices selected deterministically (~25%) receive
--   +2 days in payment time only.
--
-- This script stores original timestamps so the scenario can be reset.

USE o2c;

CREATE TABLE IF NOT EXISTS agent_scenario_registry (
    scenario_id VARCHAR(100) PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(500) NOT NULL,
    primary_order_count INT DEFAULT 0,
    secondary_invoice_count INT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS agent_scenario_v1_shipment_backup (
    shipment_id BIGINT UNSIGNED PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    ship_ts DATETIME NULL,
    promised_delivery_ts DATETIME NULL,
    actual_delivery_ts DATETIME NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS agent_scenario_v1_invoice_backup (
    invoice_id BIGINT UNSIGNED PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    invoice_ts DATETIME NULL,
    due_date DATE NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS agent_scenario_v1_payment_backup (
    payment_id BIGINT UNSIGNED PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    payment_ts DATETIME NULL,
    scenario_effect VARCHAR(40) NOT NULL
) ENGINE=InnoDB;

DROP TEMPORARY TABLE IF EXISTS scenario_v1_primary_orders;
CREATE TEMPORARY TABLE scenario_v1_primary_orders AS
SELECT o.order_id
FROM orders o
WHERE o.order_ts >= '2024-07-01'
  AND o.order_ts < '2024-10-01'
  AND o.channel = 'Marketplace'
  AND MOD(o.order_id, 10) < 7;

ALTER TABLE scenario_v1_primary_orders
    ADD PRIMARY KEY (order_id);

DROP TEMPORARY TABLE IF EXISTS scenario_v1_secondary_invoices;
CREATE TEMPORARY TABLE scenario_v1_secondary_invoices AS
SELECT DISTINCT inv.invoice_id
FROM invoices inv
JOIN orders o
  ON o.order_id = inv.order_id
JOIN customers c
  ON c.customer_id = o.customer_id
JOIN payments p
  ON p.invoice_id = inv.invoice_id
WHERE o.order_ts >= '2024-07-01'
  AND o.order_ts < '2024-10-01'
  AND c.segment = 'Enterprise'
  AND MOD(inv.invoice_id, 4) = 0;

ALTER TABLE scenario_v1_secondary_invoices
    ADD PRIMARY KEY (invoice_id);

START TRANSACTION;

-- A duplicate key here intentionally stops accidental re-application.
INSERT INTO agent_scenario_registry (
    scenario_id,
    description,
    primary_order_count,
    secondary_invoice_count
)
SELECT
    'scenario_v1_marketplace_bottleneck',
    'Q3 Marketplace order-to-ship bottleneck with smaller Enterprise payment-delay confounder',
    (SELECT COUNT(*) FROM scenario_v1_primary_orders),
    (SELECT COUNT(*) FROM scenario_v1_secondary_invoices);

-- Back up original timestamps before mutation.
INSERT INTO agent_scenario_v1_shipment_backup (
    shipment_id,
    order_id,
    ship_ts,
    promised_delivery_ts,
    actual_delivery_ts
)
SELECT
    s.shipment_id,
    s.order_id,
    s.ship_ts,
    s.promised_delivery_ts,
    s.actual_delivery_ts
FROM shipments s
JOIN scenario_v1_primary_orders x
  ON x.order_id = s.order_id;

INSERT INTO agent_scenario_v1_invoice_backup (
    invoice_id,
    order_id,
    invoice_ts,
    due_date
)
SELECT
    inv.invoice_id,
    inv.order_id,
    inv.invoice_ts,
    inv.due_date
FROM invoices inv
JOIN scenario_v1_primary_orders x
  ON x.order_id = inv.order_id;

INSERT INTO agent_scenario_v1_payment_backup (
    payment_id,
    invoice_id,
    payment_ts,
    scenario_effect
)
SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_ts,
    'primary_fulfillment_shift'
FROM payments p
JOIN invoices inv
  ON inv.invoice_id = p.invoice_id
JOIN scenario_v1_primary_orders x
  ON x.order_id = inv.order_id;

INSERT INTO agent_scenario_v1_payment_backup (
    payment_id,
    invoice_id,
    payment_ts,
    scenario_effect
)
SELECT
    p.payment_id,
    p.invoice_id,
    p.payment_ts,
    'secondary_collection_delay'
FROM payments p
JOIN scenario_v1_secondary_invoices x
  ON x.invoice_id = p.invoice_id
ON DUPLICATE KEY UPDATE
    scenario_effect = 'primary_and_secondary';

-- Primary injection: increase order-to-ship by four days while preserving
-- the downstream chronology and downstream stage durations.
UPDATE shipments s
JOIN scenario_v1_primary_orders x
  ON x.order_id = s.order_id
SET
    s.ship_ts = DATE_ADD(s.ship_ts, INTERVAL 4 DAY),
    s.promised_delivery_ts = DATE_ADD(s.promised_delivery_ts, INTERVAL 4 DAY),
    s.actual_delivery_ts = DATE_ADD(s.actual_delivery_ts, INTERVAL 4 DAY);

UPDATE invoices inv
JOIN scenario_v1_primary_orders x
  ON x.order_id = inv.order_id
SET
    inv.invoice_ts = DATE_ADD(inv.invoice_ts, INTERVAL 4 DAY),
    inv.due_date = DATE_ADD(inv.due_date, INTERVAL 4 DAY);

UPDATE payments p
JOIN invoices inv
  ON inv.invoice_id = p.invoice_id
JOIN scenario_v1_primary_orders x
  ON x.order_id = inv.order_id
SET
    p.payment_ts = DATE_ADD(p.payment_ts, INTERVAL 4 DAY);

-- Secondary confounder: smaller collections deterioration.
UPDATE payments p
JOIN scenario_v1_secondary_invoices x
  ON x.invoice_id = p.invoice_id
SET
    p.payment_ts = DATE_ADD(p.payment_ts, INTERVAL 2 DAY);

COMMIT;

SELECT
    scenario_id,
    applied_at,
    primary_order_count,
    secondary_invoice_count,
    description
FROM agent_scenario_registry
WHERE scenario_id = 'scenario_v1_marketplace_bottleneck';
