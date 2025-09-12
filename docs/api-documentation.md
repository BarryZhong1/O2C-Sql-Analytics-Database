# O2C Database API Documentation

## Overview

This document provides comprehensive API documentation for accessing and manipulating the Order-to-Cash (O2C) Analytics Database. While this is primarily a database project, this documentation covers SQL interfaces, stored procedures, views, and common query patterns that serve as the "API" for business applications.

## Table of Contents

1. [Connection Information](#connection-information)
2. [Database Views API](#database-views-api)
3. [Common Query Patterns](#common-query-patterns)
4. [Stored Procedures](#stored-procedures)
5. [Data Manipulation Guidelines](#data-manipulation-guidelines)
6. [Performance Considerations](#performance-considerations)
7. [Error Handling](#error-handling)

## Connection Information

### MySQL Connection Parameters

```sql
-- Standard connection
Host: localhost (or your server IP)
Port: 3306
Database: o2c
Character Set: utf8mb4
Collation: utf8mb4_0900_ai_ci

-- Docker connection
Host: localhost
Port: 3306
Username: app
Password: app_pw
Database: o2c
```

### Connection String Examples

**JDBC (Java)**
```
jdbc:mysql://localhost:3306/o2c?useUnicode=true&characterEncoding=UTF-8
```

**Python (pymysql)**
```python
import pymysql
connection = pymysql.connect(
    host='localhost',
    user='app',
    password='app_pw',
    database='o2c',
    charset='utf8mb4'
)
```

**Node.js (mysql2)**
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'app',
    password: 'app_pw',
    database: 'o2c'
});
```

**PHP (PDO)**
```php
$dsn = 'mysql:host=localhost;dbname=o2c;charset=utf8mb4';
$pdo = new PDO($dsn, 'app', 'app_pw');
```

## Database Views API

The O2C database provides five primary views that serve as the main API for business intelligence queries:

### 1. vw_order_summary

**Purpose**: Complete order information with customer and financial details

**Columns**:
- `order_id` (BIGINT): Unique order identifier
- `order_ts` (DATETIME): Order timestamp
- `customer_name` (VARCHAR): Customer name
- `customer_segment` (ENUM): SMB/Mid/Enterprise
- `region` (VARCHAR): Geographic region
- `payment_terms` (ENUM): Payment terms
- `order_status` (ENUM): Order status
- `channel` (ENUM): Sales channel
- `requested_ship_date` (DATE): Requested ship date
- `line_items` (INT): Number of line items
- `total_qty` (INT): Total quantity ordered
- `gross_amount` (DECIMAL): Gross order amount
- `total_discount` (DECIMAL): Total discounts
- `total_tax` (DECIMAL): Total tax
- `net_amount` (DECIMAL): Net order amount
- `gross_profit` (DECIMAL): Gross profit
- `gross_margin_pct` (DECIMAL): Gross margin percentage

**Sample Query**:
```sql
-- Get orders for a specific customer segment
SELECT * FROM vw_order_summary 
WHERE customer_segment = 'Enterprise' 
  AND order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY net_amount DESC;
```

### 2. vw_customer_analytics

**Purpose**: Customer performance metrics and lifecycle analysis

**Columns**:
- `customer_id` (BIGINT): Unique customer identifier
- `customer_name` (VARCHAR): Customer name
- `segment` (ENUM): Customer segment
- `region` (VARCHAR): Geographic region
- `payment_terms` (ENUM): Payment terms
- `credit_limit` (DECIMAL): Credit limit
- `total_orders` (INT): Total order count
- `total_revenue` (DECIMAL): Total revenue
- `avg_order_value` (DECIMAL): Average order value
- `total_gross_profit` (DECIMAL): Total gross profit
- `first_order_date` (DATETIME): First order date
- `last_order_date` (DATETIME): Last order date
- `customer_lifetime_days` (INT): Customer lifetime in days
- `avg_payment_delay_days` (DECIMAL): Average payment delay
- `total_returns` (INT): Total returns
- `total_refunds` (DECIMAL): Total refund amount

**Sample Query**:
```sql
-- Get top 10 customers by lifetime value
SELECT * FROM vw_customer_analytics 
ORDER BY total_revenue DESC 
LIMIT 10;
```

### 3. vw_product_performance

**Purpose**: Product sales performance and inventory analysis

**Columns**:
- `product_id` (BIGINT): Unique product identifier
- `sku` (VARCHAR): Stock keeping unit
- `category` (VARCHAR): Product category
- `unit_cost` (DECIMAL): Unit cost
- `list_price` (DECIMAL): List price
- `safety_stock` (INT): Safety stock level
- `on_hand_qty` (INT): On-hand quantity
- `reserved_qty` (INT): Reserved quantity
- `available_qty` (INT): Available quantity
- `orders_count` (INT): Number of orders
- `total_qty_sold` (INT): Total quantity sold
- `gross_revenue` (DECIMAL): Gross revenue
- `total_discounts` (DECIMAL): Total discounts
- `net_revenue` (DECIMAL): Net revenue
- `gross_profit` (DECIMAL): Gross profit
- `gross_margin_pct` (DECIMAL): Gross margin percentage
- `turnover_ratio` (DECIMAL): Inventory turnover ratio
- `total_returns` (INT): Total returns
- `return_rate_pct` (DECIMAL): Return rate percentage

**Sample Query**:
```sql
-- Get products below safety stock
SELECT * FROM vw_product_performance 
WHERE available_qty < safety_stock
ORDER BY (safety_stock - available_qty) DESC;
```

### 4. vw_cash_flow_analysis

**Purpose**: Invoice and payment tracking for cash flow management

**Columns**:
- `invoice_id` (BIGINT): Unique invoice identifier
- `order_id` (BIGINT): Related order ID
- `customer_id` (BIGINT): Customer ID
- `customer_name` (VARCHAR): Customer name
- `customer_segment` (ENUM): Customer segment
- `payment_terms` (ENUM): Payment terms
- `invoice_ts` (DATETIME): Invoice timestamp
- `due_date` (DATE): Payment due date
- `invoice_amount` (DECIMAL): Invoice amount
- `paid_amount` (DECIMAL): Amount paid
- `outstanding_amount` (DECIMAL): Outstanding balance
- `payment_status` (VARCHAR): PAID/PARTIAL/UNPAID
- `days_past_due` (INT): Days past due
- `payment_delay_days` (INT): Payment delay in days
- `aging_bucket` (VARCHAR): Aging category

**Sample Query**:
```sql
-- Get overdue invoices
SELECT * FROM vw_cash_flow_analysis 
WHERE payment_status != 'PAID' 
  AND days_past_due > 0
ORDER BY days_past_due DESC;
```

### 5. vw_operational_performance

**Purpose**: End-to-end process performance metrics

**Columns**:
- `order_id` (BIGINT): Unique order identifier
- `customer_name` (VARCHAR): Customer name
- `segment` (ENUM): Customer segment
- `channel` (ENUM): Sales channel
- `order_ts` (DATETIME): Order timestamp
- `requested_ship_date` (DATE): Requested ship date
- `ship_ts` (DATETIME): Actual ship timestamp
- `promised_delivery_ts` (DATETIME): Promised delivery
- `actual_delivery_ts` (DATETIME): Actual delivery
- `invoice_ts` (DATETIME): Invoice timestamp
- `due_date` (DATE): Payment due date
- `first_payment_ts` (DATETIME): First payment timestamp
- `order_to_ship_days` (INT): Order to ship time
- `ship_to_delivery_days` (INT): Shipping time
- `order_to_delivery_days` (INT): Total delivery time
- `ship_to_invoice_days` (INT): Ship to invoice time
- `invoice_to_payment_days` (INT): Payment collection time
- `total_o2c_cycle_days` (INT): Total O2C cycle time
- `delivery_performance` (VARCHAR): ON_TIME/LATE/PENDING
- `ship_performance` (VARCHAR): ON_TIME/LATE/PENDING
- `invoice_amount` (DECIMAL): Invoice amount
- `total_paid` (DECIMAL): Total amount paid

**Sample Query**:
```sql
-- Get orders with long O2C cycles
SELECT * FROM vw_operational_performance 
WHERE total_o2c_cycle_days > 45
ORDER BY total_o2c_cycle_days DESC;
```

## Common Query Patterns

### Customer Queries

```sql
-- Get customer credit utilization
SELECT 
    c.customer_id,
    c.name,
    c.credit_limit,
    COALESCE(SUM(i.total - COALESCE(p.amount, 0)), 0) AS outstanding,
    ROUND(COALESCE(SUM(i.total - COALESCE(p.amount, 0)), 0) / c.credit_limit * 100, 2) AS utilization_pct
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN invoices i ON o.order_id = i.order_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as amount 
    FROM payments 
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
GROUP BY c.customer_id, c.name, c.credit_limit
HAVING utilization_pct > 80;

-- Get customer order history
SELECT 
    o.order_id,
    o.order_ts,
    o.status,
    SUM(oi.qty * oi.unit_price - oi.discount) AS order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = ? -- parameter
GROUP BY o.order_id, o.order_ts, o.status
ORDER BY o.order_ts DESC;
```

### Product Queries

```sql
-- Get product availability by location
SELECT 
    p.sku,
    i.loc_code,
    i.on_hand_qty,
    i.reserved_qty,
    (i.on_hand_qty - i.reserved_qty) AS available
FROM products p
JOIN inventory i ON p.product_id = i.product_id
WHERE p.product_id = ? -- parameter
ORDER BY i.loc_code;

-- Get product sales history
SELECT 
    DATE_FORMAT(o.order_ts, '%Y-%m') AS month,
    SUM(oi.qty) AS qty_sold,
    SUM(oi.qty * oi.unit_price - oi.discount) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE oi.product_id = ? -- parameter
  AND o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(o.order_ts, '%Y-%m')
ORDER BY month;
```

### Order Queries

```sql
-- Get order details with items
SELECT 
    o.order_id,
    o.order_ts,
    o.status,
    p.sku,
    oi.qty,
    oi.unit_price,
    oi.discount,
    (oi.qty * oi.unit_price - oi.discount) AS line_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id = ?; -- parameter

-- Get order fulfillment status
SELECT 
    o.order_id,
    o.status AS order_status,
    s.ship_ts,
    s.carrier,
    s.tracking_number,
    s.actual_delivery_ts
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id
WHERE o.order_id = ?; -- parameter
```

### Financial Queries

```sql
-- Get invoice details with payments
SELECT 
    i.invoice_id,
    i.invoice_ts,
    i.due_date,
    i.total AS invoice_amount,
    p.payment_ts,
    p.method,
    p.amount AS payment_amount,
    (i.total - COALESCE(SUM(p.amount) OVER (PARTITION BY i.invoice_id), 0)) AS balance
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
WHERE i.invoice_id = ?; -- parameter

-- Get AR aging summary
SELECT 
    CASE 
        WHEN DATEDIFF(CURDATE(), due_date) <= 0 THEN 'Current'
        WHEN DATEDIFF(CURDATE(), due_date) <= 30 THEN '1-30 Days'
        WHEN DATEDIFF(CURDATE(), due_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(CURDATE(), due_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket,
    COUNT(*) AS invoice_count,
    SUM(total - COALESCE(paid, 0)) AS outstanding
FROM (
    SELECT 
        i.invoice_id,
        i.due_date,
        i.total,
        SUM(p.amount) AS paid
    FROM invoices i
    LEFT JOIN payments p ON i.invoice_id = p.invoice_id
    GROUP BY i.invoice_id, i.due_date, i.total
) inv
WHERE total > COALESCE(paid, 0)
GROUP BY aging_bucket;
```

## Stored Procedures

### GenerateRealisticTransactions (if retained)

**Purpose**: Generate sample transactional data for testing

**Parameters**: None

**Usage**:
```sql
CALL GenerateRealisticTransactions();
```

**Note**: This procedure is typically dropped after initial data generation.

## Data Manipulation Guidelines

### INSERT Operations

**Creating a New Order**:
```sql
-- Start transaction
START TRANSACTION;

-- Insert order header
INSERT INTO orders (customer_id, order_ts, status, channel, requested_ship_date)
VALUES (?, NOW(), 'NEW', 'Web', DATE_ADD(CURDATE(), INTERVAL 2 DAY));

SET @order_id = LAST_INSERT_ID();

-- Insert order items
INSERT INTO order_items (order_id, product_id, qty, unit_price, discount, tax)
SELECT 
    @order_id,
    ?,  -- product_id
    ?,  -- quantity
    list_price,
    0,  -- discount
    list_price * ? * 0.085  -- tax calculation
FROM products 
WHERE product_id = ?;

-- Update inventory reservation
UPDATE inventory 
SET reserved_qty = reserved_qty + ?
WHERE product_id = ? AND loc_code = 'PHX-01';

COMMIT;
```

### UPDATE Operations

**Update Order Status**:
```sql
UPDATE orders 
SET status = 'SHIPPED',
    updated_at = NOW()
WHERE order_id = ?;
```

**Process Payment**:
```sql
INSERT INTO payments (invoice_id, payment_ts, method, amount, reference_number)
VALUES (?, NOW(), 'ACH', ?, ?);
```

### DELETE Operations

**Cancel Order** (soft delete recommended):
```sql
UPDATE orders 
SET status = 'CANCELLED',
    updated_at = NOW()
WHERE order_id = ?;

-- Release inventory reservation
UPDATE inventory i
JOIN order_items oi ON i.product_id = oi.product_id
SET i.reserved_qty = i.reserved_qty - oi.qty
WHERE oi.order_id = ? AND i.loc_code = 'PHX-01';
```

## Performance Considerations

### Index Usage

The database includes optimized indexes for common query patterns:

```sql
-- Check index usage
EXPLAIN SELECT * FROM vw_order_summary 
WHERE customer_segment = 'Enterprise' 
  AND order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);
```

### Query Optimization Tips

1. **Use Date Ranges Efficiently**:
```sql
-- Good: Uses index
WHERE order_ts >= '2024-01-01' AND order_ts < '2024-02-01'

-- Bad: Function on column prevents index use
WHERE YEAR(order_ts) = 2024 AND MONTH(order_ts) = 1
```

2. **Limit Result Sets**:
```sql
-- Always use LIMIT for large result sets
SELECT * FROM vw_order_summary 
ORDER BY order_ts DESC 
LIMIT 100;
```

3. **Use Appropriate JOINs**:
```sql
-- Use INNER JOIN when relationship must exist
SELECT o.*, c.name
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;

-- Use LEFT JOIN for optional relationships
SELECT o.*, s.ship_ts
FROM orders o
LEFT JOIN shipments s ON o.order_id = s.order_id;
```

### Connection Pooling

For production applications, use connection pooling:

**Java (HikariCP)**:
```java
HikariConfig config = new HikariConfig();
config.setJdbcUrl("jdbc:mysql://localhost:3306/o2c");
config.setUsername("app");
config.setPassword("app_pw");
config.setMaximumPoolSize(10);
```

**Python (SQLAlchemy)**:
```python
from sqlalchemy import create_engine
engine = create_engine(
    'mysql+pymysql://app:app_pw@localhost/o2c',
    pool_size=10,
    max_overflow=20
)
```

## Error Handling

### Common Error Codes

| Error Code | Description | Resolution |
|------------|-------------|------------|
| 1062 | Duplicate entry | Check for existing records before INSERT |
| 1452 | Foreign key constraint fails | Ensure parent record exists |
| 1264 | Out of range value | Check data types and ranges |
| 1406 | Data too long | Validate string lengths |
| 1146 | Table doesn't exist | Verify database setup |

### Error Handling Examples

**Python**:
```python
import pymysql

try:
    connection = pymysql.connect(host='localhost', user='app', 
                                password='app_pw', database='o2c')
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM vw_order_summary LIMIT 10")
        result = cursor.fetchall()
except pymysql.err.OperationalError as e:
    print(f"Database connection failed: {e}")
except pymysql.err.ProgrammingError as e:
    print(f"SQL syntax error: {e}")
finally:
    if connection:
        connection.close()
```

**Node.js**:
```javascript
connection.query('SELECT * FROM vw_order_summary LIMIT 10', (error, results) => {
    if (error) {
        console.error('Database query error:', error.code, error.message);
        return;
    }
    console.log('Results:', results);
});
```

### Transaction Management

Always use transactions for multi-table operations:

```sql
START TRANSACTION;

BEGIN
    -- Multiple operations
    INSERT INTO orders ...;
    INSERT INTO order_items ...;
    UPDATE inventory ...;
    
    -- Check for errors
    IF (SELECT COUNT(*) FROM ...) > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Business rule violation';
    END IF;
    
    COMMIT;
END;
```

## API Response Formats

### JSON Response Example

When building REST APIs on top of the database:

```json
{
    "status": "success",
    "data": {
        "order": {
            "order_id": 1234,
            "customer_name": "ABC Corp",
            "order_date": "2024-09-15T10:30:00Z",
            "status": "SHIPPED",
            "items": [
                {
                    "sku": "PROD-001",
                    "quantity": 5,
                    "unit_price": 99.99,
                    "line_total": 499.95
                }
            ],
            "total": 499.95
        }
    },
    "metadata": {
        "timestamp": "2024-09-15T14:23:45Z",
        "version": "1.0"
    }
}
```

### Pagination

For large result sets, implement pagination:

```sql
-- Page 1 (records 1-50)
SELECT * FROM vw_order_summary 
ORDER BY order_id 
LIMIT 50 OFFSET 0;

-- Page 2 (records 51-100)
SELECT * FROM vw_order_summary 
ORDER BY order_id 
LIMIT 50 OFFSET 50;
```

## Rate Limiting

When exposing the database through an API, implement rate limiting:

```sql
-- Track API usage
CREATE TABLE api_usage (
    api_key VARCHAR(50),
    endpoint VARCHAR(100),
    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_api_usage (api_key, request_time)
);

-- Check rate limit (example: 100 requests per minute)
SELECT COUNT(*) as request_count
FROM api_usage
WHERE api_key = ?
  AND request_time >= DATE_SUB(NOW(), INTERVAL 1 MINUTE);
```

## Security Considerations

### SQL Injection Prevention

Always use parameterized queries:

```python
# Good - Parameterized
cursor.execute("SELECT * FROM orders WHERE customer_id = %s", (customer_id,))

# Bad - String concatenation
cursor.execute(f"SELECT * FROM orders WHERE customer_id = {customer_id}")
```

### Access Control

```sql
-- Create read-only user for reporting
CREATE USER 'report_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT ON o2c.* TO 'report_user'@'%';

-- Create application user with limited permissions
CREATE USER 'app_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE ON o2c.* TO 'app_user'@'%';
```

## Support and Resources

- **Database Schema**: See [database-schema.md](database-schema.md)
- **Business Requirements**: See [business-requirements.md](business-requirements.md)
- **Sample Queries**: See [examples/dashboard_queries.sql](../examples/dashboard_queries.sql)
- **GitHub Issues**: Report bugs or request features
- **Documentation**: Check the `/docs` folder for detailed information

---

*Last Updated: September 2024*
*Version: 1.0*
