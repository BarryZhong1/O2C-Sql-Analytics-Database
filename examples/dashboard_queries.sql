-- =============================================
-- O2C DASHBOARD QUERIES
-- Ready-to-use queries for business dashboards
-- =============================================

USE `o2c`;

-- =============================================
-- EXECUTIVE DASHBOARD
-- =============================================

-- KPI Summary Cards
SELECT 'EXECUTIVE KPI SUMMARY' AS dashboard_section;

-- Revenue This Month vs Last Month
SELECT 
    'Monthly Revenue Comparison' as metric_name,
    ROUND(SUM(CASE WHEN MONTH(o.order_ts) = MONTH(CURDATE()) AND YEAR(o.order_ts) = YEAR(CURDATE()) 
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END), 0) as current_month,
    ROUND(SUM(CASE WHEN MONTH(o.order_ts) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) 
                        AND YEAR(o.order_ts) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END), 0) as last_month,
    ROUND((SUM(CASE WHEN MONTH(o.order_ts) = MONTH(CURDATE()) AND YEAR(o.order_ts) = YEAR(CURDATE()) 
                        THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END) - 
           SUM(CASE WHEN MONTH(o.order_ts) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) 
                         AND YEAR(o.order_ts) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
                    THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END)) / 
          NULLIF(SUM(CASE WHEN MONTH(o.order_ts) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) 
                               AND YEAR(o.order_ts) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
                          THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END), 0) * 100, 1) as growth_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH);

-- Key Metrics Summary
SELECT 
    COUNT(DISTINCT CASE WHEN o.order_ts >= DATE_FORMAT(CURDATE(), '%Y-%m-01') THEN o.customer_id END) as active_customers_mtd,
    COUNT(CASE WHEN o.order_ts >= DATE_FORMAT(CURDATE(), '%Y-%m-01') THEN 1 END) as orders_mtd,
    ROUND(SUM(CASE WHEN o.order_ts >= DATE_FORMAT(CURDATE(), '%Y-%m-01') 
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END), 0) as revenue_mtd,
    ROUND(AVG(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) 
                   THEN oi.qty * oi.unit_price - oi.discount END), 0) as avg_order_value_30d,
    ROUND(SUM(i.total - COALESCE(p.amount, 0)), 0) as outstanding_ar
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN invoices i ON o.order_id = i.order_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id;

-- =============================================
-- SALES PERFORMANCE DASHBOARD
-- =============================================

-- Sales Trend - Last 12 Months
SELECT 'SALES PERFORMANCE TRENDS' AS dashboard_section;

SELECT 
    DATE_FORMAT(o.order_ts, '%Y-%m') as month,
    COUNT(DISTINCT o.order_id) as order_count,
    COUNT(DISTINCT o.customer_id) as customer_count,
    SUM(oi.qty) as units_sold,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as revenue,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)), 0) as gross_profit,
    ROUND(AVG(oi.qty * oi.unit_price - oi.discount), 0) as avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(o.order_ts, '%Y-%m')
ORDER BY month DESC
LIMIT 12;

-- Channel Performance
SELECT 
    o.channel,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as total_revenue,
    ROUND(AVG(oi.qty * oi.unit_price - oi.discount), 0) as avg_order_value,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / 
          (SELECT SUM(oi2.qty * oi2.unit_price - oi2.discount) 
           FROM orders o2 
           JOIN order_items oi2 ON o2.order_id = oi2.order_id 
           WHERE o2.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)) * 100, 1) as revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY o.channel
ORDER BY total_revenue DESC;

-- Top 10 Customers by Revenue (YTD)
SELECT 
    c.customer_id,
    c.name,
    c.segment,
    c.region,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as ytd_revenue,
    ROUND(AVG(oi.qty * oi.unit_price - oi.discount), 0) as avg_order_value,
    MAX(o.order_ts) as last_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE YEAR(o.order_ts) = YEAR(CURDATE())
GROUP BY c.customer_id, c.name, c.segment, c.region
ORDER BY ytd_revenue DESC
LIMIT 10;

-- =============================================
-- OPERATIONAL DASHBOARD
-- =============================================

-- Order Status Pipeline
SELECT 'OPERATIONAL PERFORMANCE' AS dashboard_section;

SELECT 
    o.status,
    COUNT(*) as order_count,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as total_value,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM orders WHERE order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) * 100, 1) as percentage
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY o.status
ORDER BY FIELD(o.status, 'NEW', 'ALLOCATED', 'SHIPPED', 'DELIVERED', 'CANCELLED');

-- Fulfillment Performance Metrics
SELECT 
    COUNT(DISTINCT o.order_id) as total_orders_30d,
    COUNT(DISTINCT CASE WHEN s.ship_ts IS NOT NULL THEN o.order_id END) as shipped_orders,
    COUNT(DISTINCT CASE WHEN s.actual_delivery_ts IS NOT NULL THEN o.order_id END) as delivered_orders,
    ROUND(AVG(CASE WHEN s.ship_ts IS NOT NULL 
                   THEN DATEDIFF(s.ship_ts, o.order_ts) END), 1) as avg_days_to_ship,
    ROUND(AVG(CASE WHEN s.actual_delivery_ts IS NOT NULL 
                   THEN DATEDIFF(s.actual_delivery_ts, o.order_ts) END), 1) as avg_days_to_deliver,
    COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) as on_time_deliveries,
    ROUND(COUNT(CASE WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 1 END) / 
          COUNT(CASE WHEN s.actual_delivery_ts IS NOT NULL THEN 1 END) * 100, 1) as on_time_delivery_pct
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY); -- Last 30 days for current operational performance

-- Inventory Alerts (Products Below Safety Stock)
-- Purpose: Identify products that need immediate attention for restocking
-- Safety stock threshold is defined per product to prevent stockouts
SELECT 
    p.sku,
    p.category,
    i.loc_code as warehouse_location,
    i.on_hand_qty as current_stock,
    i.reserved_qty as reserved_for_orders,
    (i.on_hand_qty - i.reserved_qty) as available_stock,
    p.safety_stock as minimum_required,
    (p.safety_stock - (i.on_hand_qty - i.reserved_qty)) as reorder_qty_needed,
    -- Calculate days of supply based on recent sales velocity
    CASE 
        WHEN COALESCE(recent_sales.avg_daily_sales, 0) = 0 THEN 999 -- No recent sales = infinite supply
        ELSE ROUND((i.on_hand_qty - i.reserved_qty) / recent_sales.avg_daily_sales, 1) 
    END as days_of_supply_remaining
FROM products p
JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN (
    -- Subquery to calculate average daily sales over last 30 days
    -- Using 30 days to get recent demand patterns while smoothing daily fluctuations
    SELECT 
        oi.product_id,
        SUM(oi.qty) / 30 as avg_daily_sales -- Divide by 30 to get daily average
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY oi.product_id
) recent_sales ON p.product_id = recent_sales.product_id
WHERE (i.on_hand_qty - i.reserved_qty) < p.safety_stock -- Below safety stock threshold
ORDER BY (p.safety_stock - (i.on_hand_qty - i.reserved_qty)) DESC -- Most critical first
LIMIT 20; -- Top 20 most critical items for management focus

-- =============================================
-- FINANCIAL DASHBOARD
-- =============================================

-- Cash Flow Summary
SELECT 'FINANCIAL PERFORMANCE' AS dashboard_section;

-- Current Accounts Receivable Status
-- Purpose: Monitor outstanding invoices and collection performance
-- Critical for cash flow management and credit risk assessment
SELECT 
    -- Current period (0-30 days) - Normal collection window
    SUM(CASE WHEN DATEDIFF(CURDATE(), i.due_date) BETWEEN -30 AND 0 THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) as current_0_30_days,
    
    -- Early bucket (31-60 days) - Starting to be concerning
    SUM(CASE WHEN DATEDIFF(CURDATE(), i.due_date) BETWEEN 1 AND 30 THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) as past_due_1_30_days,
    
    -- Moderate risk (31-60 days) - Requires attention
    SUM(CASE WHEN DATEDIFF(CURDATE(), i.due_date) BETWEEN 31 AND 60 THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) as past_due_31_60_days,
    
    -- High risk (61-90 days) - Immediate action needed
    SUM(CASE WHEN DATEDIFF(CURDATE(), i.due_date) BETWEEN 61 AND 90 THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) as past_due_61_90_days,
    
    -- Critical risk (90+ days) - Potential bad debt
    SUM(CASE WHEN DATEDIFF(CURDATE(), i.due_date) > 90 THEN i.total - COALESCE(p.amount, 0) ELSE 0 END) as past_due_90_plus_days,
    
    -- Total outstanding balance across all aging buckets
    SUM(i.total - COALESCE(p.amount, 0)) as total_outstanding
FROM invoices i
LEFT JOIN (
    -- Aggregate payments by invoice to get total paid per invoice
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.total > COALESCE(p.amount, 0); -- Only include invoices with outstanding balance

-- Days Sales Outstanding (DSO) Calculation
-- Purpose: Measure average collection period - key financial KPI
-- Industry benchmark: 30-45 days is typically good, >60 days needs attention
SELECT 
    'Days Sales Outstanding (DSO)' as metric_name,
    ROUND(
        (SELECT SUM(i.total - COALESCE(p.amount, 0)) 
         FROM invoices i
         LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p 
         ON i.invoice_id = p.invoice_id
         WHERE i.total > COALESCE(p.amount, 0)) / -- Total outstanding AR
        (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 -- Average daily sales over last 30 days
         FROM orders o
         JOIN order_items oi ON o.order_id = oi.order_id
         WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY))
    , 1) as dso_days,
    CASE 
        WHEN ROUND((SELECT SUM(i.total - COALESCE(p.amount, 0)) FROM invoices i LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p ON i.invoice_id = p.invoice_id WHERE i.total > COALESCE(p.amount, 0)) / (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 FROM orders o JOIN order_items oi ON o.order_id = oi.order_id WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 1) <= 30 THEN 'Excellent'
        WHEN ROUND((SELECT SUM(i.total - COALESCE(p.amount, 0)) FROM invoices i LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p ON i.invoice_id = p.invoice_id WHERE i.total > COALESCE(p.amount, 0)) / (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 FROM orders o JOIN order_items oi ON o.order_id = oi.order_id WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 1) <= 45 THEN 'Good'
        WHEN ROUND((SELECT SUM(i.total - COALESCE(p.amount, 0)) FROM invoices i LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p ON i.invoice_id = p.invoice_id WHERE i.total > COALESCE(p.amount, 0)) / (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 FROM orders o JOIN order_items oi ON o.order_id = oi.order_id WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)), 1) <= 60 THEN 'Needs Attention'
        ELSE 'Critical'
    END as performance_rating;

-- Payment Method Performance Analysis
-- Purpose: Analyze payment preferences and processing times by method
-- Helps optimize payment processing and reduce collection costs
SELECT 
    p.method as payment_method,
    COUNT(*) as transaction_count,
    ROUND(SUM(p.amount), 0) as total_amount,
    ROUND(AVG(p.amount), 0) as avg_transaction_size,
    
    -- Calculate average payment processing time (invoice date to payment date)
    -- Shorter times indicate more efficient payment methods
    ROUND(AVG(DATEDIFF(p.payment_ts, i.invoice_ts)), 1) as avg_days_to_pay,
    
    -- Percentage of total payment volume by method
    ROUND(SUM(p.amount) / (SELECT SUM(amount) FROM payments) * 100, 1) as volume_percentage,
    
    -- Cost efficiency rating based on processing time
    CASE 
        WHEN AVG(DATEDIFF(p.payment_ts, i.invoice_ts)) <= 5 THEN 'Very Fast'
        WHEN AVG(DATEDIFF(p.payment_ts, i.invoice_ts)) <= 15 THEN 'Fast' 
        WHEN AVG(DATEDIFF(p.payment_ts, i.invoice_ts)) <= 30 THEN 'Standard'
        ELSE 'Slow'
    END as processing_speed
FROM payments p
JOIN invoices i ON p.invoice_id = i.invoice_id
WHERE p.payment_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) -- Last 90 days for recent trends
GROUP BY p.method
ORDER BY total_amount DESC; -- Order by volume to see most used methods first

-- =============================================
-- CUSTOMER ANALYTICS DASHBOARD  
-- =============================================

-- Customer Segmentation Performance
-- Purpose: Compare performance across customer segments (SMB/Mid/Enterprise)
-- Helps focus sales and marketing efforts on most profitable segments
SELECT 'CUSTOMER ANALYTICS' AS dashboard_section;

SELECT 
    c.segment as customer_segment,
    COUNT(DISTINCT c.customer_id) as total_customers,
    
    -- Revenue metrics for last 90 days (quarterly performance)
    ROUND(SUM(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END), 0) as revenue_90d,
    
    -- Average revenue per customer in segment
    ROUND(SUM(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END) / 
          COUNT(DISTINCT c.customer_id), 0) as revenue_per_customer,
    
    -- Order frequency and size analysis
    ROUND(AVG(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
                   THEN oi.qty * oi.unit_price - oi.discount END), 0) as avg_order_value,
    
    -- Customer activity level (orders per customer)
    ROUND(COUNT(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) THEN o.order_id END) / 
          COUNT(DISTINCT c.customer_id), 1) as avg_orders_per_customer,
    
    -- Gross margin by segment
    ROUND(SUM(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
                   THEN oi.qty * (oi.unit_price - p.unit_cost) ELSE 0 END) /
          SUM(CASE WHEN o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
                   THEN oi.qty * oi.unit_price - oi.discount ELSE 0 END) * 100, 1) as gross_margin_pct
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id  
LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY c.segment
ORDER BY revenue_90d DESC; -- Order by revenue to see most valuable segments first

-- Customer Churn Risk Analysis
-- Purpose: Identify customers who haven't ordered recently and may be at risk
-- 60+ days without order is concerning, 90+ days is high churn risk
SELECT 
    c.customer_id,
    c.name as customer_name,
    c.segment,
    
    -- Calculate recency metrics
    MAX(o.order_ts) as last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_ts)) as days_since_last_order,
    
    -- Historical value to assess importance of retention
    COUNT(DISTINCT o.order_id) as total_lifetime_orders,
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as lifetime_revenue,
    ROUND(AVG(oi.qty * oi.unit_price - oi.discount), 0) as avg_historical_order_value,
    
    -- Risk categorization based on days since last order
    CASE 
        WHEN DATEDIFF(CURDATE(), MAX(o.order_ts)) <= 30 THEN 'Active' -- Recent customer
        WHEN DATEDIFF(CURDATE(), MAX(o.order_ts)) <= 60 THEN 'At Risk' -- Needs attention
        WHEN DATEDIFF(CURDATE(), MAX(o.order_ts)) <= 90 THEN 'High Risk' -- Urgent outreach needed
        ELSE 'Critical Risk' -- Likely churned
    END as churn_risk_category
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_id IS NOT NULL -- Only customers who have placed orders
GROUP BY c.customer_id, c.name, c.segment
HAVING days_since_last_order >= 30 -- Focus on customers with concerning inactivity
ORDER BY 
    CASE churn_risk_category 
        WHEN 'Critical Risk' THEN 1 
        WHEN 'High Risk' THEN 2 
        WHEN 'At Risk' THEN 3 
        ELSE 4 
    END,
    lifetime_revenue DESC -- Within each risk category, prioritize by value
LIMIT 25; -- Top 25 at-risk customers for focused retention efforts

-- =============================================
-- PRODUCT PERFORMANCE DASHBOARD
-- =============================================

-- Top Performing Products (Last 90 Days)  
-- Purpose: Identify best-selling products for inventory planning and promotion
-- 90-day window provides recent trends while smoothing short-term fluctuations
SELECT 'PRODUCT ANALYTICS' AS dashboard_section;

SELECT 
    p.product_id,
    p.sku as product_sku,
    p.category,
    
    -- Sales volume metrics
    SUM(oi.qty) as units_sold_90d,
    COUNT(DISTINCT oi.order_id) as orders_containing_product,
    
    -- Revenue and profitability
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount), 0) as revenue_90d,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)), 0) as gross_profit_90d,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / 
          SUM(oi.qty * oi.unit_price - oi.discount) * 100, 1) as profit_margin_pct,
    
    -- Performance ranking within category
    ROUND(SUM(oi.qty * oi.unit_price - oi.discount) / 
          (SELECT SUM(oi2.qty * oi2.unit_price - oi2.discount) 
           FROM order_items oi2 
           JOIN orders o2 ON oi2.order_id = o2.order_id
           JOIN products p2 ON oi2.product_id = p2.product_id
           WHERE o2.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) 
           AND p2.category = p.category) * 100, 1) as category_revenue_share_pct,
    
    -- Inventory turn rate (how fast product moves)
    ROUND(SUM(oi.qty) / NULLIF(AVG(i.on_hand_qty), 0) * 4, 1) as annualized_inventory_turns -- Multiply by 4 to annualize 90-day data
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN inventory i ON p.product_id = i.product_id
WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) -- Last 90 days for recent performance
GROUP BY p.product_id, p.sku, p.category
ORDER BY revenue_90d DESC -- Order by revenue to see top performers
LIMIT 15; -- Top 15 products for management focus

-- =============================================
-- ALERTS AND EXCEPTIONS DASHBOARD
-- =============================================

-- Critical Business Alerts
-- Purpose: Highlight issues requiring immediate management attention
-- Thresholds set based on typical business requirements
SELECT 'CRITICAL ALERTS' AS dashboard_section;

-- Orders stuck in processing (shipped late)
SELECT 
    'LATE_SHIPMENTS' as alert_type,
    COUNT(*) as alert_count,
    CONCAT('Orders past requested ship date: ', GROUP_CONCAT(o.order_id ORDER BY o.requested_ship_date SEPARATOR ', ')) as alert_details
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE o.requested_ship_date < CURDATE() -- Past requested ship date
  AND o.status NOT IN ('DELIVERED', 'CANCELLED') -- Still active orders
  AND (s.ship_ts IS NULL OR s.ship_ts > o.requested_ship_date) -- Not shipped or shipped late
HAVING COUNT(*) > 0 -- Only show if there are alerts

UNION ALL

-- High-value customers with overdue payments
-- $10,000 threshold indicates significant financial impact
SELECT 
    'HIGH_VALUE_OVERDUE' as alert_type,
    COUNT(*) as alert_count,
    CONCAT('High-value customers (>$10K) with overdue payments: ', 
           GROUP_CONCAT(DISTINCT c.name ORDER BY outstanding SEPARATOR ', ')) as alert_details
FROM (
    SELECT 
        c.customer_id,
        c.name,
        SUM(i.total - COALESCE(p.amount, 0)) as outstanding
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN invoices i ON o.order_id = i.order_id
    LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p 
        ON i.invoice_id = p.invoice_id
    WHERE i.due_date < CURDATE() -- Past due date
      AND i.total > COALESCE(p.amount, 0) -- Has outstanding balance
    GROUP BY c.customer_id, c.name
    HAVING outstanding >= 10000 -- $10K+ threshold for high-value alerts
) overdue_customers
JOIN customers c ON overdue_customers.customer_id = c.customer_id
HAVING COUNT(*) > 0

UNION ALL

-- Low inventory alerts for fast-moving products
-- 7-day supply threshold ensures adequate safety buffer
SELECT 
    'LOW_INVENTORY' as alert_type,
    COUNT(*) as alert_count,
    CONCAT('Products with <7 days inventory remaining: ', 
           GROUP_CONCAT(p.sku ORDER BY days_supply SEPARATOR ', ')) as alert_details
FROM (
    SELECT 
        p.product_id,
        p.sku,
        (i.on_hand_qty - i.reserved_qty) as available_qty,
        COALESCE(recent_sales.daily_avg, 0) as daily_sales,
        CASE 
            WHEN COALESCE(recent_sales.daily_avg, 0) = 0 THEN 999
            ELSE (i.on_hand_qty - i.reserved_qty) / recent_sales.daily_avg
        END as days_supply
    FROM products p
    JOIN inventory i ON p.product_id = i.product_id
    LEFT JOIN (
        -- Calculate daily sales average over last 30 days
        SELECT 
            oi.product_id,
            SUM(oi.qty) / 30 as daily_avg -- 30-day average for stability
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY oi.product_id
    ) recent_sales ON p.product_id = recent_sales.product_id
    WHERE (i.on_hand_qty - i.reserved_qty) > 0 -- Has inventory
) inventory_analysis
JOIN products p ON inventory_analysis.product_id = p.product_id
WHERE inventory_analysis.days_supply < 7 -- Less than 7 days supply
HAVING COUNT(*) > 0;
