-- Reset Scenario V1 and restore original timestamps.

USE o2c;

START TRANSACTION;

UPDATE payments p
JOIN agent_scenario_v1_payment_backup b
  ON b.payment_id = p.payment_id
SET p.payment_ts = b.payment_ts;

UPDATE invoices inv
JOIN agent_scenario_v1_invoice_backup b
  ON b.invoice_id = inv.invoice_id
SET
    inv.invoice_ts = b.invoice_ts,
    inv.due_date = b.due_date;

UPDATE shipments s
JOIN agent_scenario_v1_shipment_backup b
  ON b.shipment_id = s.shipment_id
SET
    s.ship_ts = b.ship_ts,
    s.promised_delivery_ts = b.promised_delivery_ts,
    s.actual_delivery_ts = b.actual_delivery_ts;

DELETE FROM agent_scenario_registry
WHERE scenario_id = 'scenario_v1_marketplace_bottleneck';

DELETE FROM agent_scenario_v1_payment_backup;
DELETE FROM agent_scenario_v1_invoice_backup;
DELETE FROM agent_scenario_v1_shipment_backup;

COMMIT;

SELECT 'scenario_v1_marketplace_bottleneck reset complete' AS status;
