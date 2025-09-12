-- =============================================
-- O2C SAMPLE ANALYTICAL QUERIES
-- Ready-to-use queries for business reporting
-- =============================================

USE `o2c`;

-- =============================================
-- EXECUTIVE DASHBOARD QUERIES
-- =============================================

-- Monthly Revenue Trend Analysis
SELECT 
    DATE_FORMAT(order_ts, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(oi.qty * oi.unit_price - oi.discount) AS gross_revenue,
    SUM(oi.qty * (oi.unit_price - p.unit_cost)) AS gross_profit,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / 
          SUM(oi.qty * oi.unit_price - oi.discount) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(order_ts, '%Y-%m')
ORDER BY month DESC;

-- Customer Segment Performance Summary
SELECT 
    c.segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty * oi.unit_price - oi.discount) AS segment_revenue,
    ROUND(AVG(oi.qty * oi.unit_price - oi.discount), 2) AS avg_order_value,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.segment
ORDER BY segment_revenue DESC;

-- Top 10 Products by Revenue (Last 90 Days)
SELECT 
    p.sku,
    p.category,
    SUM(oi.qty) AS total_qty_sold,
    SUM(oi.qty * oi.unit_price - oi.discount) AS total_revenue,
    SUM(oi.qty * (oi.unit_price - p.unit_cost)) AS total_profit,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / 
          SUM(oi.qty * oi.unit_price - oi.discount) * 100, 2) AS profit_margin_pct,
    COUNT(DISTINCT o.order_id) AS orders_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY p.product_id, p.sku, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- =============================================
-- OPERATIONAL PERFORMANCE QUERIES
-- =============================================

-- Order Fulfillment Performance by Channel
SELECT 
    o.channel,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN o.status = 'DELIVERED' THEN 1 END) AS delivered_orders,
    ROUND(COUNT(CASE WHEN o.status = 'DELIVERED' THEN 1 END) / COUNT(*) * 100, 2) AS delivery_rate_pct,
    ROUND(AVG(CASE WHEN s.actual_delivery_ts IS NOT NULL 
                   THEN DATEDIFF(s.actual_delivery_ts, o.order_ts) END), 1) AS avg_delivery_days,
    COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) AS on_time_deliveries,
    ROUND(COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) / 
          COUNT(CASE WHEN s.actual_delivery_ts IS NOT NULL THEN 1 END) * 100, 2) AS on_time_rate_pct
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY o.channel
ORDER BY total_orders DESC;

-- Inventory Status Report by Category
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    SUM(i.on_hand_qty) AS total_on_hand,
    SUM(i.reserved_qty) AS total_reserved,
    SUM(i.on_hand_qty - i.reserved_qty) AS total_available,
    SUM(p.safety_stock) AS total_safety_stock,
    COUNT(CASE WHEN (i.on_hand_qty - i.reserved_qty) < p.safety_stock THEN 1 END) AS below_safety_stock,
    ROUND(COUNT(CASE WHEN (i.on_hand_qty - i.reserved_qty) < p.safety_stock THEN 1 END) / 
          COUNT(DISTINCT p.product_id) * 100, 2) AS stockout_risk_pct
FROM products p
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.category
ORDER BY stockout_risk_pct DESC;

-- Carrier Performance Analysis
SELECT 
    s.carrier,
    COUNT(*) AS shipment_count,
    COUNT(CASE WHEN s.actual_delivery_ts IS NOT NULL THEN 1 END) AS delivered_count,
    ROUND(AVG(CASE WHEN s.actual_delivery_ts IS NOT NULL 
                   THEN DATEDIFF(s.actual_delivery_ts, s.ship_ts) END), 1) AS avg_transit_days,
    COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) AS on_time_count,
    ROUND(COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) / 
          COUNT(CASE WHEN s.actual_delivery_ts IS NOT NULL THEN 1 END) * 100, 2) AS on_time_rate_pct,
    COUNT(CASE WHEN s.actual_delivery_ts > s.promised_delivery_ts THEN 1 END) AS late_deliveries
FROM shipments s
WHERE s.ship_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY s.carrier
ORDER BY shipment_count DESC;

-- =============================================
-- FINANCIAL ANALYSIS QUERIES
-- =============================================

-- Accounts Receivable Aging Analysis
SELECT 
    CASE 
        WHEN DATEDIFF(CURDATE(), i.due_date) <= 0 THEN 'Current'
        WHEN DATEDIFF(CURDATE(), i.due_date) <= 30 THEN '1-30 Days'
        WHEN DATEDIFF(CURDATE(), i.due_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(CURDATE(), i.due_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket,
    COUNT(i.invoice_id) AS invoice_count,
    SUM(i.total) AS total_invoiced,
    SUM(COALESCE(p.amount, 0)) AS total_paid,
    SUM(i.total - COALESCE(p.amount, 0)) AS outstanding_balance,
    ROUND(SUM(i.total - COALESCE(p.amount, 0)) / SUM(i.total) * 100, 2) AS outstanding_pct
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.total > COALESCE(p.amount, 0) -- Only unpaid/partial invoices
GROUP BY aging_bucket
ORDER BY FIELD(aging_bucket, 'Current', '1-30 Days', '31-60 Days', '61-90 Days', '90+ Days');

-- Customer Payment Behavior Analysis
SELECT 
    c.customer_id,
    c.name,
    c.segment,
    c.payment_terms,
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    SUM(i.total) AS total_invoiced,
    SUM(COALESCE(pay.amount, 0)) AS total_paid,
    SUM(i.total - COALESCE(pay.amount, 0)) AS outstanding_balance,
    ROUND(AVG(CASE WHEN pay.payment_ts IS NOT NULL 
                   THEN DATEDIFF(pay.payment_ts, i.due_date) END), 1) AS avg_payment_delay_days,
    COUNT(CASE WHEN pay.payment_ts > i.due_date THEN 1 END) AS late_payments,
    ROUND(COUNT(CASE WHEN pay.payment_ts > i.due_date THEN 1 END) / 
          COUNT(CASE WHEN pay.payment_ts IS NOT NULL THEN 1 END) * 100, 2) AS late_payment_rate_pct
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN invoices i ON o.order_id = i.order_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount, MIN(payment_ts) as payment_ts 
    FROM payments 
    GROUP BY invoice_id
) pay ON i.invoice_id = pay.invoice_id
GROUP BY c.customer_id, c.name, c.segment, c.payment_terms
HAVING total_invoices >= 2 -- Only customers with multiple invoices
ORDER BY outstanding_balance DESC, avg_payment_delay_days DESC;

-- Cash Flow Projection (Next 90 Days)
SELECT 
    WEEK(i.due_date) AS week_number,
    DATE(DATE_ADD(i.due_date, INTERVAL(1-DAYOFWEEK(i.due_date)) DAY)) AS week_start,
    COUNT(i.invoice_id) AS invoices_due,
    SUM(i.total - COALESCE(p.amount, 0)) AS expected_collections,
    SUM(CASE WHEN c.payment_terms = 'Prepaid' THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) AS prepaid_expected,
    SUM(CASE WHEN c.payment_terms = 'Net15' THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) AS net15_expected,
    SUM(CASE WHEN c.payment_terms = 'Net30' THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) AS net30_expected,
    SUM(CASE WHEN c.payment_terms = 'Net45' THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) AS net45_expected
FROM invoices i
JOIN orders o ON i.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.due_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY)
  AND i.total > COALESCE(p.amount, 0)
GROUP BY WEEK(i.due_date), week_start
ORDER BY week_start;

-- =============================================
-- CUSTOMER ANALYSIS QUERIES
-- =============================================

-- Customer Lifetime Value Analysis (Top 20)
SELECT 
    c.customer_id,
    c.name,
    c.segment,
    c.region,
    DATEDIFF(CURDATE(), MIN(o.order_ts)) AS customer_age_days,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty * oi.unit_price - oi.discount) AS total_revenue,
    SUM(oi.qty * (oi.unit_price - p.unit_cost)) AS total_profit,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / 
          NULLIF(DATEDIFF(CURDATE(), MIN(o.order_ts)), 0) * 365, 2) AS annualized_revenue,
    MAX(o.order_ts) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_ts)) AS days_since_last_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.name, c.segment, c.region
ORDER BY total_revenue DESC
LIMIT 20;

-- New vs Returning Customer Analysis (Last 90 Days)
SELECT 
    'New Customers' AS customer_type,
    COUNT(DISTINCT first_orders.customer_id) AS customer_count,
    SUM(first_orders.order_value) AS total_revenue,
    ROUND(AVG(first_orders.order_value), 2) AS avg_order_value
FROM (
    SELECT 
        o.customer_id,
        SUM(oi.qty * oi.unit_price - oi.discount) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
      AND o.order_ts = (SELECT MIN(order_ts) FROM orders WHERE customer_id = o.customer_id)
    GROUP BY o.customer_id
) first_orders

UNION ALL

SELECT 
    'Returning Customers' AS customer_type,
    COUNT(DISTINCT return_orders.customer_id) AS customer_count,
    SUM(return_orders.order_value) AS total_revenue,
    ROUND(AVG(return_orders.order_value), 2) AS avg_order_value
FROM (
    SELECT 
        o.customer_id,
        SUM(oi.qty * oi.unit_price - oi.discount) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
      AND o.order_ts > (SELECT MIN(order_ts) FROM orders WHERE customer_id = o.customer_id)
    GROUP BY o.customer_id
) return_orders;

-- =============================================
-- PRODUCT ANALYSIS QUERIES
-- =============================================

-- Product Category Performance Comparison
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT oi.order_id) AS orders_with_category,
    SUM(oi.qty) AS total_units_sold,
    SUM(oi.qty * oi.unit_price - oi.discount) AS category_revenue,
    SUM(oi.qty * (oi.unit_price - p.unit_cost)) AS category_profit,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / 
          SUM(oi.qty * oi.unit_price - oi.discount) * 100, 2) AS profit_margin_pct,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / COUNT(DISTINCT p.product_id), 2) AS revenue_per_product,
    -- Return analysis
    COALESCE(SUM(r.qty), 0) AS total_returns,
    ROUND(COALESCE(SUM(r.qty), 0) / SUM(oi.qty) * 100, 2) AS return_rate_pct
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN returns r ON p.product_id = r.product_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 180 DAY) OR o.order_ts IS NULL
GROUP BY p.category
ORDER BY category_revenue DESC;

-- Slow-Moving Inventory Report
SELECT 
    p.sku,
    p.category,
    i.on_hand_qty,
    i.reserved_qty,
    (i.on_hand_qty - i.reserved_qty) AS available_qty,
    COALESCE(SUM(oi.qty), 0) AS qty_sold_90days,
    CASE 
        WHEN COALESCE(SUM(oi.qty), 0) = 0 THEN 999
        ELSE ROUND((i.on_hand_qty - i.reserved_qty) / (COALESCE(SUM(oi.qty), 0) / 90), 1)
    END AS days_of_supply,
    p.unit_cost * (i.on_hand_qty - i.reserved_qty) AS inventory_value,
    MAX(o.order_ts) AS last_sale_date,
    COALESCE(DATEDIFF(CURDATE(), MAX(o.order_ts)), 999) AS days_since_last_sale
FROM products p
JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id 
    AND o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
WHERE i.on_hand_qty > 0
GROUP BY p.product_id, p.sku, p.category, i.on_hand_qty, i.reserved_qty, p.unit_cost
HAVING days_of_supply > 60 OR days_since_last_sale > 60
ORDER BY inventory_value DESC, days_of_supply DESC;

-- =============================================
-- EXCEPTION REPORTS
-- =============================================

-- Orders at Risk (Delayed Shipments)
SELECT 
    o.order_id,
    c.name AS customer_name,
    c.segment,
    o.order_ts,
    o.requested_ship_date,
    o.status,
    DATEDIFF(CURDATE(), o.requested_ship_date) AS days_overdue,
    SUM(oi.qty * oi.unit_price - oi.discount) AS order_value,
    s.ship_ts,
    s.status AS shipment_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE o.requested_ship_date < CURDATE()
  AND o.status NOT IN ('DELIVERED', 'CANCELLED')
GROUP BY o.order_id, c.name, c.segment, o.order_ts, o.requested_ship_date, 
         o.status, s.ship_ts, s.status
ORDER BY days_overdue DESC, order_value DESC;

-- Credit Limit Utilization Alerts
SELECT 
    c.customer_id,
    c.name,
    c.segment,
    c.credit_limit,
    COALESCE(SUM(i.total - COALESCE(p.amount, 0)), 0) AS outstanding_balance,
    ROUND(COALESCE(SUM(i.total - COALESCE(p.amount, 0)), 0) / c.credit_limit * 100, 2) AS credit_utilization_pct,
    (c.credit_limit - COALESCE(SUM(i.total - COALESCE(p.amount, 0)), 0)) AS available_credit
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN invoices i ON o.order_id = i.order_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
GROUP BY c.customer_id, c.name, c.segment, c.credit_limit
HAVING credit_utilization_pct > 80 OR available_credit < 10000
ORDER BY credit_utilization_pct DESC;

-- =============================================
-- SUMMARY QUERY
-- =============================================

-- Overall Business Health Dashboard
SELECT 'BUSINESS METRICS SUMMARY' AS metric_category;

SELECT 
    'Total Active Customers' AS metric_name,
    COUNT(DISTINCT c.customer_id) AS metric_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)

UNION ALL

SELECT 
    'Orders This Month',
    COUNT(*)
FROM orders 
WHERE order_ts >= DATE_FORMAT(CURDATE(), '%Y-%m-01')

UNION ALL

SELECT 
    'Revenue This Month',
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_ts >= DATE_FORMAT(CURDATE(), '%Y-%m-01')

UNION ALL

SELECT 
    'Outstanding AR Balance',
    ROUND(SUM(i.total - COALESCE(p.amount, 0)), 0)
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.total > COALESCE(p.amount, 0)

UNION ALL

SELECT 
    'Average Order Value (90 days)',
    ROUND(AVG(order_value), 2)
FROM (
    SELECT SUM(oi.qty * oi.unit_price - oi.discount) as order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY o.order_id
) order_values;
