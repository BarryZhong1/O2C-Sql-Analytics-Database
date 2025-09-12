-- =============================================
-- O2C DATA VALIDATION AND QUALITY CHECKS
-- Comprehensive tests for data integrity
-- =============================================

USE `o2c`;

-- =============================================
-- 1. RECORD COUNT VALIDATION
-- =============================================
SELECT '========================================' AS separator;
SELECT 'RECORD COUNT VALIDATION' AS test_category;
SELECT '========================================' AS separator;

SELECT 
    'customers' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM customers
UNION ALL
SELECT 
    'products', 
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM products
UNION ALL  
SELECT 
    'orders', 
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM orders
UNION ALL
SELECT 
    'order_items', 
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM order_items
UNION ALL
SELECT 
    'inventory', 
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM inventory
UNION ALL
SELECT 
    'shipments', 
    COUNT(*),
    CASE WHEN COUNT(*) >= 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM shipments
UNION ALL
SELECT 
    'invoices', 
    COUNT(*),
    CASE WHEN COUNT(*) >= 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM invoices
UNION ALL
SELECT 
    'payments', 
    COUNT(*),
    CASE WHEN COUNT(*) >= 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM payments
UNION ALL
SELECT 
    'returns', 
    COUNT(*),
    CASE WHEN COUNT(*) >= 0 THEN '✓ PASS' ELSE '✗ FAIL' END
FROM returns;

-- =============================================
-- 2. REFERENTIAL INTEGRITY CHECKS
-- =============================================
SELECT '' AS separator;
SELECT 'REFERENTIAL INTEGRITY CHECKS' AS test_category;
SELECT '========================================' AS separator;

-- Orders without customers (should be 0)
SELECT 
    'Orders with invalid customer_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM orders o 
LEFT JOIN customers c ON o.customer_id = c.customer_id 
WHERE c.customer_id IS NULL;

-- Order items without orders (should be 0)
SELECT 
    'Order items with invalid order_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM order_items oi 
LEFT JOIN orders o ON oi.order_id = o.order_id 
WHERE o.order_id IS NULL;

-- Order items without products (should be 0)
SELECT 
    'Order items with invalid product_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM order_items oi 
LEFT JOIN products p ON oi.product_id = p.product_id 
WHERE p.product_id IS NULL;

-- Inventory without products (should be 0)
SELECT 
    'Inventory with invalid product_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM inventory i 
LEFT JOIN products p ON i.product_id = p.product_id 
WHERE p.product_id IS NULL;

-- Shipments without orders (should be 0)
SELECT 
    'Shipments with invalid order_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM shipments s 
LEFT JOIN orders o ON s.order_id = o.order_id 
WHERE o.order_id IS NULL;

-- Invoices without orders (should be 0)
SELECT 
    'Invoices with invalid order_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM invoices i 
LEFT JOIN orders o ON i.order_id = o.order_id 
WHERE o.order_id IS NULL;

-- Payments without invoices (should be 0)
SELECT 
    'Payments with invalid invoice_id' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM payments p 
LEFT JOIN invoices i ON p.invoice_id = i.invoice_id 
WHERE i.invoice_id IS NULL;

-- =============================================
-- 3. DATA QUALITY CHECKS
-- =============================================
SELECT '' AS separator;
SELECT 'DATA QUALITY CHECKS' AS test_category;
SELECT '========================================' AS separator;

-- Customers with missing required fields
SELECT 
    'Customers with missing name' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM customers 
WHERE name IS NULL OR name = '';

-- Products with negative costs or prices
SELECT 
    'Products with negative unit_cost' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM products 
WHERE unit_cost < 0;

SELECT 
    'Products with negative list_price' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM products 
WHERE list_price < 0;

-- Products with cost higher than list price (potential margin issues)
SELECT 
    'Products with cost > list_price' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM products 
WHERE unit_cost > list_price;

-- Order items with negative quantities or prices
SELECT 
    'Order items with negative qty' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM order_items 
WHERE qty <= 0;

SELECT 
    'Order items with negative unit_price' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM order_items 
WHERE unit_price < 0;

-- Inventory with negative quantities
SELECT 
    'Inventory with negative on_hand_qty' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM inventory 
WHERE on_hand_qty < 0;

SELECT 
    'Inventory with negative reserved_qty' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM inventory 
WHERE reserved_qty < 0;

-- Reserved quantity exceeding on-hand quantity
SELECT 
    'Inventory with reserved > on_hand' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM inventory 
WHERE reserved_qty > on_hand_qty;

-- =============================================
-- 4. BUSINESS LOGIC VALIDATION
-- =============================================
SELECT '' AS separator;
SELECT 'BUSINESS LOGIC VALIDATION' AS test_category;
SELECT '========================================' AS separator;

-- Orders without any order items
SELECT 
    'Orders with no line items' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM orders o 
LEFT JOIN order_items oi ON o.order_id = oi.order_id 
WHERE oi.order_id IS NULL;

-- Shipped orders without shipments
SELECT 
    'Shipped orders without shipment records' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM orders o 
LEFT JOIN shipments s ON o.order_id = s.order_id 
WHERE o.status IN ('SHIPPED', 'DELIVERED') 
  AND s.order_id IS NULL;

-- Delivered orders without delivery confirmation
SELECT 
    'Delivered orders without delivery timestamp' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM orders o 
JOIN shipments s ON o.order_id = s.order_id 
WHERE o.status = 'DELIVERED' 
  AND s.actual_delivery_ts IS NULL;

-- Shipments with delivery before ship date
SELECT 
    'Shipments with delivery before ship date' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM shipments 
WHERE actual_delivery_ts < ship_ts;

-- Invoices with total not matching components
SELECT 
    'Invoices with incorrect total calculation' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM invoices 
WHERE ABS(total - (subtotal + tax + freight)) > 0.01;

-- Payments exceeding invoice totals (by invoice)
SELECT 
    'Invoices with payments > invoice total' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM (
    SELECT 
        i.invoice_id,
        i.total as invoice_total,
        SUM(p.amount) as total_payments
    FROM invoices i
    LEFT JOIN payments p ON i.invoice_id = p.invoice_id
    GROUP BY i.invoice_id, i.total
    HAVING SUM(p.amount) > i.total
) overpaid;

-- Returns exceeding original order quantities
SELECT 
    'Returns exceeding original order qty' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM (
    SELECT 
        r.order_id,
        r.product_id,
        r.qty as return_qty,
        oi.qty as original_qty
    FROM returns r
    JOIN order_items oi ON r.order_id = oi.order_id AND r.product_id = oi.product_id
    WHERE r.qty > oi.qty
) excessive_returns;

-- =============================================
-- 5. FINANCIAL INTEGRITY CHECKS
-- =============================================
SELECT '' AS separator;
SELECT 'FINANCIAL INTEGRITY CHECKS' AS test_category;
SELECT '========================================' AS separator;

-- Invoice amounts with unreasonable values
SELECT 
    'Invoices with zero or negative totals' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM invoices 
WHERE total <= 0;

-- Payments with zero or negative amounts
SELECT 
    'Payments with zero or negative amounts' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM payments 
WHERE amount <= 0;

-- Customer credit limit utilization over 100%
SELECT 
    'Customers over credit limit' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM (
    SELECT 
        c.customer_id,
        c.credit_limit,
        SUM(i.total - COALESCE(p.amount, 0)) as outstanding_balance
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN invoices i ON o.order_id = i.order_id
    LEFT JOIN (
        SELECT invoice_id, SUM(amount) as amount 
        FROM payments 
        GROUP BY invoice_id
    ) p ON i.invoice_id = p.invoice_id
    GROUP BY c.customer_id, c.credit_limit
    HAVING outstanding_balance > c.credit_limit
) over_limit;

-- =============================================
-- 6. DATE CONSISTENCY CHECKS
-- =============================================
SELECT '' AS separator;
SELECT 'DATE CONSISTENCY CHECKS' AS test_category;
SELECT '========================================' AS separator;

-- Future order dates
SELECT 
    'Orders with future dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM orders 
WHERE order_ts > NOW();

-- Invoice dates before order dates
SELECT 
    'Invoices before order dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM invoices i
JOIN orders o ON i.order_id = o.order_id
WHERE i.invoice_ts < o.order_ts;

-- Payment dates before invoice dates
SELECT 
    'Payments before invoice dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM payments p
JOIN invoices i ON p.invoice_id = i.invoice_id
WHERE p.payment_ts < i.invoice_ts;

-- Ship dates before order dates
SELECT 
    'Ship dates before order dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM shipments s
JOIN orders o ON s.order_id = o.order_id
WHERE s.ship_ts < o.order_ts;

-- =============================================
-- 7. SUMMARY VALIDATION REPORT
-- =============================================
SELECT '' AS separator;
SELECT 'VALIDATION SUMMARY' AS test_category;
SELECT '========================================' AS separator;

-- Count of all validation issues
SELECT 
    'Total Critical Issues (FAIL)' as summary_item,
    (
        SELECT COUNT(*) FROM (
            SELECT COUNT(*) as issues FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL
            UNION ALL SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL
            UNION ALL SELECT COUNT(*) FROM order_items oi LEFT JOIN products p ON oi.product_id = p.product_id WHERE p.product_id IS NULL
            UNION ALL SELECT COUNT(*) FROM inventory i LEFT JOIN products p ON i.product_id = p.product_id WHERE p.product_id IS NULL
            UNION ALL SELECT COUNT(*) FROM customers WHERE name IS NULL OR name = ''
            UNION ALL SELECT COUNT(*) FROM products WHERE unit_cost < 0
            UNION ALL SELECT COUNT(*) FROM products WHERE list_price < 0
            UNION ALL SELECT COUNT(*) FROM order_items WHERE qty <= 0
            UNION ALL SELECT COUNT(*) FROM order_items WHERE unit_price < 0
            UNION ALL SELECT COUNT(*) FROM inventory WHERE on_hand_qty < 0
            UNION ALL SELECT COUNT(*) FROM inventory WHERE reserved_qty < 0
            UNION ALL SELECT COUNT(*) FROM orders o LEFT JOIN order_items oi ON o.order_id = oi.order_id WHERE oi.order_id IS NULL
            UNION ALL SELECT COUNT(*) FROM shipments WHERE actual_delivery_ts < ship_ts
            UNION ALL SELECT COUNT(*) FROM invoices WHERE ABS(total - (subtotal + tax + freight)) > 0.01
            UNION ALL SELECT COUNT(*) FROM invoices WHERE total <= 0
            UNION ALL SELECT COUNT(*) FROM payments WHERE amount <= 0
        ) all_issues WHERE issues > 0
    ) as count,
    CASE WHEN (
        SELECT COUNT(*) FROM (
            SELECT COUNT(*) as issues FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL
            UNION ALL SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL
            UNION ALL SELECT COUNT(*) FROM order_items oi LEFT JOIN products p ON oi.product_id = p.product_id WHERE p.product_id IS NULL
            -- Add other critical checks here
        ) critical_issues WHERE issues > 0
    ) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END as status;

-- Database health score
SELECT 
    'Overall Database Health Score' as summary_item,
    CONCAT(
        ROUND(
            (1 - (
                SELECT COUNT(*) FROM (
                    SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as has_issues FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM customers WHERE name IS NULL OR name = ''
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM products WHERE unit_cost < 0 OR list_price < 0
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM order_items WHERE qty <= 0 OR unit_price < 0
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM inventory WHERE on_hand_qty < 0 OR reserved_qty < 0
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM invoices WHERE total <= 0
                    UNION ALL SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM payments WHERE amount <= 0
                ) issues WHERE has_issues = 1
            ) / 8) * 100, 1
        ), '%'
    ) as health_score,
    '📊 INFO' as status;

SELECT '========================================' AS separator;
SELECT 'VALIDATION COMPLETE' AS final_status;
SELECT '========================================' AS separator;
