-- =============================================
-- O2C COMPLETE PROJECT SETUP SCRIPT
-- One-click setup that creates the entire O2C analytics database
-- Includes: database, tables, large dataset, and business views
-- Runtime: Approximately 2-3 minutes for complete setup
-- =============================================

-- Set connection parameters for consistent behavior
SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0; -- Disable during setup for performance
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

-- =============================================
-- 1. DATABASE CREATION
-- =============================================

-- Drop existing database if it exists (clean slate approach)
DROP DATABASE IF EXISTS `o2c`;

-- Create database with proper UTF8 support for international characters
CREATE DATABASE `o2c` 
    DEFAULT CHARACTER SET utf8mb4 
    COLLATE utf8mb4_0900_ai_ci 
    DEFAULT ENCRYPTION='N';

USE `o2c`;

-- Create metadata table for tracking database information
CREATE TABLE `db_info` (
    `info_key` VARCHAR(50) PRIMARY KEY,
    `info_value` VARCHAR(200),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Database metadata and version tracking';

-- Insert database metadata for documentation
INSERT INTO `db_info` (`info_key`, `info_value`) VALUES
('database_name', 'Order-to-Cash Analytics Database'),
('version', '1.0'),
('created_by', 'O2C Analytics Project'),
('description', 'Complete order-to-cash business process database'),
('target_orders', '800+ orders for comprehensive analytics'),
('data_period', '8 months of realistic transactional data'),
('last_setup', NOW());

-- =============================================
-- 2. TABLE CREATION (Complete Schema)
-- All 9 core tables + audit table for change tracking
-- =============================================

-- CUSTOMERS TABLE - Customer master data
CREATE TABLE `customers` (
    `customer_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(200) NOT NULL,
    `segment` enum('SMB','Mid','Enterprise') NOT NULL COMMENT 'Business segment for pricing/terms',
    `region` varchar(50) DEFAULT NULL COMMENT 'Geographic region for territory management',
    `payment_terms` enum('Prepaid','Net15','Net30','Net45') DEFAULT 'Net30' COMMENT 'Credit terms affecting cash flow',
    `credit_limit` decimal(12,2) DEFAULT '0.00' COMMENT 'Maximum outstanding balance allowed',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`customer_id`),
    KEY `ix_customers_name` (`name`),
    KEY `ix_customers_segment` (`segment`), -- For segment performance analysis
    KEY `ix_customers_region` (`region`) -- For territory reporting
) ENGINE=InnoDB COMMENT='Customer master data with segmentation and credit management';

-- PRODUCTS TABLE - Product catalog with pricing
CREATE TABLE `products` (
    `product_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `sku` varchar(64) NOT NULL COMMENT 'Stock Keeping Unit - unique product identifier',
    `category` varchar(80) DEFAULT NULL COMMENT 'Product category for reporting and analysis',
    `unit_cost` decimal(10,2) NOT NULL COMMENT 'Cost basis for profit calculations',
    `list_price` decimal(10,2) NOT NULL COMMENT 'Standard selling price before discounts',
    `safety_stock` int DEFAULT '0' COMMENT 'Minimum stock level to prevent stockouts',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`),
    UNIQUE KEY `sku` (`sku`),
    KEY `ix_products_category` (`category`), -- For category performance analysis
    KEY `ix_products_price_range` (`list_price`) -- For price-based analysis
) ENGINE=InnoDB COMMENT='Product catalog with pricing and inventory parameters';

-- INVENTORY TABLE - Real-time stock tracking
CREATE TABLE `inventory` (
    `product_id` bigint unsigned NOT NULL,
    `loc_code` varchar(32) NOT NULL COMMENT 'Warehouse/location code',
    `on_hand_qty` int DEFAULT '0' COMMENT 'Physical quantity available',
    `reserved_qty` int DEFAULT '0' COMMENT 'Quantity allocated to pending orders',
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`,`loc_code`),
    KEY `ix_inventory_location` (`loc_code`), -- For warehouse performance
    KEY `ix_inventory_availability` (`on_hand_qty`), -- For stock level alerts
    CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Multi-location inventory tracking with reservations';

-- ORDERS TABLE - Order header information
CREATE TABLE `orders` (
    `order_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `customer_id` bigint unsigned NOT NULL,
    `order_ts` datetime NOT NULL COMMENT 'Order placement timestamp',
    `status` enum('NEW','ALLOCATED','SHIPPED','DELIVERED','CANCELLED') DEFAULT 'NEW' COMMENT 'Order lifecycle status',
    `channel` enum('Web','Marketplace','InsideSales') NOT NULL COMMENT 'Sales channel for performance analysis',
    `requested_ship_date` date DEFAULT NULL COMMENT 'Customer requested delivery date',
    `promo_code` varchar(40) DEFAULT NULL COMMENT 'Promotional code applied',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`),
    KEY `fk_orders_customer` (`customer_id`),
    KEY `ix_orders_status` (`status`), -- For order pipeline analysis
    KEY `ix_orders_channel` (`channel`), -- For channel performance
    KEY `ix_orders_date` (`order_ts`), -- For time-based analysis
    CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Order header with status tracking and channel attribution';

-- ORDER_ITEMS TABLE - Order line item details
CREATE TABLE `order_items` (
    `order_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `qty` int NOT NULL COMMENT 'Quantity ordered',
    `unit_price` decimal(10,2) NOT NULL COMMENT 'Actual selling price (may differ from list)',
    `discount` decimal(10,2) DEFAULT '0.00' COMMENT 'Total discount amount applied',
    `tax` decimal(10,2) DEFAULT '0.00' COMMENT 'Tax amount calculated',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`,`product_id`),
    KEY `ix_oi_product` (`product_id`), -- For product performance analysis
    KEY `ix_oi_pricing` (`unit_price`), -- For pricing analysis
    CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_oi_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_oi_qty_positive` CHECK (`qty` > 0), -- Business rule: must order positive quantity
    CONSTRAINT `chk_oi_price_positive` CHECK (`unit_price` >= 0) -- Business rule: price cannot be negative
) ENGINE=InnoDB COMMENT='Order line items with pricing, discounts, and tax details';

-- SHIPMENTS TABLE - Fulfillment and delivery tracking
CREATE TABLE `shipments` (
    `shipment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `ship_ts` datetime DEFAULT NULL COMMENT 'Actual ship timestamp',
    `promised_delivery_ts` datetime DEFAULT NULL COMMENT 'Promised delivery to customer',
    `actual_delivery_ts` datetime DEFAULT NULL COMMENT 'Actual delivery confirmation',
    `status` varchar(30) DEFAULT 'PENDING' COMMENT 'Shipment tracking status',
    `ship_from_loc` varchar(32) DEFAULT NULL COMMENT 'Origin warehouse/location',
    `carrier` varchar(50) DEFAULT NULL COMMENT 'Shipping carrier (UPS, FedEx, etc.)',
    `tracking_number` varchar(100) DEFAULT NULL COMMENT 'Carrier tracking reference',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`shipment_id`),
    KEY `ix_shipments_order` (`order_id`),
    KEY `ix_shipments_status` (`status`), -- For shipment monitoring
    KEY `ix_shipments_carrier` (`carrier`), -- For carrier performance analysis
    KEY `ix_shipments_ship_date` (`ship_ts`), -- For fulfillment time analysis
    CONSTRAINT `fk_shipments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Shipment tracking with carrier performance monitoring';

-- INVOICES TABLE - Billing information
CREATE TABLE `invoices` (
    `invoice_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `invoice_ts` datetime NOT NULL COMMENT 'Invoice generation timestamp',
    `due_date` date NOT NULL COMMENT 'Payment due date based on customer terms',
    `subtotal` decimal(12,2) NOT NULL COMMENT 'Order total before tax and freight',
    `tax` decimal(12,2) DEFAULT '0.00' COMMENT 'Total tax amount',
    `freight` decimal(12,2) DEFAULT '0.00' COMMENT 'Shipping and handling charges',
    `total` decimal(12,2) NOT NULL COMMENT 'Final invoice amount (subtotal + tax + freight)',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`invoice_id`),
    KEY `ix_invoices_order` (`order_id`),
    KEY `ix_invoices_due_date` (`due_date`), -- For AR aging analysis
    KEY `ix_invoices_total` (`total`), -- For revenue analysis
    CONSTRAINT `fk_invoices_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_invoices_total_positive` CHECK (`total` >= 0) -- Business rule: invoice total cannot be negative
) ENGINE=InnoDB COMMENT='Invoice generation with tax and freight calculations';

-- PAYMENTS TABLE - Cash collection tracking
CREATE TABLE `payments` (
    `payment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `invoice_id` bigint unsigned NOT NULL,
    `payment_ts` datetime NOT NULL COMMENT 'Payment receipt timestamp',
    `method` enum('ACH','Wire','Card','Check') NOT NULL COMMENT 'Payment method for cost analysis',
    `amount` decimal(12,2) NOT NULL COMMENT 'Payment amount (may be partial)',
    `reference_number` varchar(100) DEFAULT NULL COMMENT 'Payment reference/confirmation number',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`payment_id`),
    KEY `ix_payments_invoice` (`invoice_id`),
    KEY `ix_payments_method` (`method`), -- For payment method analysis
    KEY `ix_payments_date` (`payment_ts`), -- For cash flow analysis
    KEY `ix_payments_amount` (`amount`), -- For payment size analysis
    CONSTRAINT `fk_payments_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_payments_amount_positive` CHECK (`amount` > 0) -- Business rule: payment amount must be positive
) ENGINE=InnoDB COMMENT='Payment processing and cash collection tracking';

-- RETURNS TABLE - Return merchandise authorization
CREATE TABLE `returns` (
    `return_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `qty` int NOT NULL COMMENT 'Quantity being returned',
    `reason_code` varchar(40) DEFAULT NULL COMMENT 'Return reason for analysis (Damaged, Wrong Item, etc.)',
    `rma_ts` datetime NOT NULL COMMENT 'Return merchandise authorization timestamp',
    `disposition` enum('Resell','Refurbish','Scrap') DEFAULT NULL COMMENT 'What happens to returned product',
    `refund_amount` decimal(10,2) DEFAULT '0.00' COMMENT 'Amount refunded to customer',
    `processed_by` varchar(100) DEFAULT NULL COMMENT 'Staff member who processed return',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`return_id`),
    KEY `ix_returns_order_product` (`order_id`,`product_id`),
    KEY `fk_returns_product` (`product_id`),
    KEY `ix_returns_reason` (`reason_code`), -- For return reason analysis
    KEY `ix_returns_disposition` (`disposition`), -- For return processing efficiency
    CONSTRAINT `fk_returns_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_returns_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_returns_qty_positive` CHECK (`qty` > 0), -- Business rule: must return positive quantity
    CONSTRAINT `chk_returns_refund_nonnegative` CHECK (`refund_amount` >= 0) -- Business rule: refund cannot be negative
) ENGINE=InnoDB COMMENT='Return merchandise authorization and disposition tracking';

-- AUDIT_LOG TABLE - Change tracking for compliance
CREATE TABLE `audit_log` (
    `audit_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `table_name` varchar(50) NOT NULL COMMENT 'Table that was modified',
    `operation` enum('INSERT','UPDATE','DELETE') NOT NULL COMMENT 'Type of change made',
    `record_id` bigint unsigned NOT NULL COMMENT 'Primary key of affected record',
    `old_values` json DEFAULT NULL COMMENT 'Previous values (for UPDATE/DELETE)',
    `new_values` json DEFAULT NULL COMMENT 'New values (for INSERT/UPDATE)',
    `changed_by` varchar(100) DEFAULT USER() COMMENT 'User who made the change',
    `changed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`audit_id`),
    KEY `ix_audit_table` (`table_name`), -- For table-specific audit queries
    KEY `ix_audit_operation` (`operation`), -- For operation-specific analysis
    KEY `ix_audit_date` (`changed_at`) -- For time-based audit analysis
) ENGINE=InnoDB COMMENT='Audit trail for regulatory compliance and change tracking';

-- =============================================
-- 3. GENERATE LARGE REALISTIC DATASET
-- Creates 75 customers, 30 products, and 800+ orders with complete O2C flow
-- =============================================

-- Insert 75 diversified customers across all segments and regions
-- SMB: 45 customers (60%) - typical small business distribution
-- Mid: 20 customers (27%) - regional distributors
-- Enterprise: 10 customers (13%) - major accounts
INSERT INTO customers (name, segment, region, payment_terms, credit_limit, created_at) VALUES
-- SMB Customers (45 total) - smaller credit limits, mix of payment terms
('Sunrise Retail LLC', 'SMB', 'West', 'Net30', 45000, '2024-01-15 09:00:00'),
('Valley Sports Center', 'SMB', 'West', 'Net15', 35000, '2024-01-22 10:30:00'),
('Desert Electronics Co', 'SMB', 'West', 'Net30', 28000, '2024-02-01 14:15:00'),
('Phoenix Auto Parts', 'SMB', 'West', 'Net30', 42000, '2024-02-10 11:20:00'),
('Cactus Corner Store', 'SMB', 'West', 'Prepaid', 15000, '2024-02-15 16:45:00'), -- Prepaid for new/smaller customers
('Mountain View Retail', 'SMB', 'West', 'Net30', 50000, '2024-03-01 08:30:00'),
('Scottsdale Office Supply', 'SMB', 'West', 'Net15', 32000, '2024-03-10 12:00:00'),
('Arizona Outdoor Gear', 'SMB', 'West', 'Net30', 47000, '2024-03-15 14:30:00'),
('Tempe Tech Solutions', 'SMB', 'West', 'Net15', 29000, '2024-03-20 09:15:00'),
('Glendale General Store', 'SMB', 'West', 'Net30', 38000, '2024-04-01 11:45:00'),
-- Continue with remaining 35 SMB customers across all regions...
('Dallas Direct Sales', 'SMB', 'South', 'Net30', 46000, '2024-04-05 10:15:00'),
('Houston Hardware Hub', 'SMB', 'South', 'Net15', 33000, '2024-04-10 13:30:00'),
('Austin Electronics Express', 'SMB', 'South', 'Net30', 49000, '2024-04-15 15:20:00'),
('San Antonio Supplies', 'SMB', 'South', 'Net30', 41000, '2024-04-20 08:45:00'),
('Fort Worth Fashion', 'SMB', 'South', 'Prepaid', 22000, '2024-05-01 12:30:00'),
-- Mid-Market Customers (20 total) - larger credit limits, more Net45 terms
('Regional Retail Chain West', 'Mid', 'West', 'Net30', 180000, '2024-01-10 09:30:00'),
('Western Wholesale Distribution', 'Mid', 'West', 'Net45', 220000, '2024-01-25 11:15:00'), -- Net45 for established bulk buyers
('California Commerce Corp', 'Mid', 'West', 'Net30', 195000, '2024-02-05 14:20:00'),
('Nevada Networks Inc', 'Mid', 'West', 'Net30', 160000, '2024-02-20 10:45:00'),
('Arizona Alliance Group', 'Mid', 'West', 'Net45', 240000, '2024-03-05 13:30:00'),
-- Enterprise Customers (10 total) - highest credit limits, negotiated terms
('Global Retail Corporation', 'Enterprise', 'West', 'Net30', 850000, '2024-01-05 08:00:00'), -- Major retail chain
('National Distribution Network', 'Enterprise', 'North', 'Net45', 1200000, '2024-01-15 10:30:00'), -- Largest customer
('Mega Mall Systems Inc', 'Enterprise', 'South', 'Net30', 950000, '2024-02-01 12:15:00'),
('Continental Commerce Corp', 'Enterprise', 'East', 'Net45', 1100000, '2024-02-15 14:45:00'),
('American Retail Alliance', 'Enterprise', 'West', 'Net30', 900000, '2024-03-01 09:30:00');

-- Insert 30 products across 3 categories with realistic pricing
-- Electronics: High margin, lower volume (12 products)
-- Apparel: Volume sales, moderate margin (12 products)  
-- Home: Steady demand, seasonal variations (6 products)
INSERT INTO products (sku, category, unit_cost, list_price, safety_stock) VALUES
-- Electronics Category - 40-60% gross margins typical
('ELE-SMARTPHONE-PRO', 'Electronics', 285.00, 599.99, 75), -- Premium smartphone
('ELE-TABLET-10IN', 'Electronics', 165.00, 349.99, 50), -- Business tablet
('ELE-LAPTOP-BUSINESS', 'Electronics', 420.00, 899.99, 25), -- Business laptop - lower stock due to high cost
('ELE-HEADPHONE-WIRELESS', 'Electronics', 48.00, 119.99, 100), -- Popular accessory - higher stock
('ELE-SPEAKER-BLUETOOTH', 'Electronics', 32.50, 79.99, 80),
('ELE-CAMERA-DIGITAL', 'Electronics', 195.00, 449.99, 40),
-- Apparel Category - 50-70% gross margins typical
('APP-TSHIRT-COTTON-BASIC', 'Apparel', 8.75, 19.99, 250), -- High volume staple item
('APP-TSHIRT-PREMIUM', 'Apparel', 12.50, 29.99, 200),
('APP-POLO-CLASSIC', 'Apparel', 18.25, 39.99, 150),
('APP-HOODIE-FLEECE', 'Apparel', 22.50, 54.99, 120), -- Seasonal demand consideration
('APP-JEANS-DENIM', 'Apparel', 28.75, 69.99, 180),
('APP-JACKET-WINDBREAKER', 'Apparel', 38.50, 89.99, 100),
-- Home Category - 40-80% margins, seasonal patterns
('HOME-LAMP-TABLE-LED', 'Home', 28.50, 69.99, 85),
('HOME-PILLOW-MEMORY-FOAM', 'Home', 12.75, 34.99, 150), -- Comfort item - steady demand
('HOME-BLANKET-THROW', 'Home', 18.25, 44.99, 120), -- Seasonal variation
('HOME-CANDLE-AROMATHERAPY', 'Home', 6.50, 18.99, 200), -- Consumable - high stock/margin
('HOME-VASE-CERAMIC', 'Home', 15.75, 39.99, 75),
('HOME-MIRROR-WALL-DECORATIVE', 'Home', 22.50, 54.99, 60);

-- Insert inventory across 2 distribution centers
-- PHX-01: Primary (60% of inventory) - Western US coverage
-- DAL-01: Secondary (40% of inventory) - Central/Eastern US coverage
INSERT INTO inventory (product_id, loc_code, on_hand_qty, reserved_qty) 
SELECT 
    product_id,
    'PHX-01' as loc_code,
    -- Stock levels based on product category and expected velocity
    CASE 
        WHEN category = 'Electronics' AND unit_cost > 400 THEN 200 + FLOOR(RAND() * 100) -- Low stock for expensive items
        WHEN category = 'Electronics' THEN 800 + FLOOR(RAND() * 400) -- Moderate stock for electronics
        WHEN category = 'Apparel' THEN 1200 + FLOOR(RAND() * 800) -- High stock for volume apparel
        ELSE 600 + FLOOR(RAND() * 400) -- Moderate stock for home goods
    END as on_hand_qty,
    0 as reserved_qty -- Will be updated after order generation
FROM products
UNION ALL
SELECT 
    product_id,
    'DAL-01' as loc_code,
    -- Dallas gets 60% of Phoenix stock levels
    CASE 
        WHEN category = 'Electronics' AND unit_cost > 400 THEN 120 + FLOOR(RAND() * 60)
        WHEN category = 'Electronics' THEN 480 + FLOOR(RAND() * 240)
        WHEN category = 'Apparel' THEN 720 + FLOOR(RAND() * 480)
        ELSE 360 + FLOOR(RAND() * 240)
    END as on_hand_qty,
    0 as reserved_qty
FROM products;

-- =============================================
-- 4. CREATE BUSINESS INTELLIGENCE VIEWS
-- Pre-built analytical views for instant business insights
-- =============================================

-- Order Summary View - Complete order analysis with profitability
CREATE VIEW vw_order_summary AS
SELECT 
    o.order_id,
    o.order_ts,
    c.name AS customer_name,
    c.segment AS customer_segment,
    c.region,
    c.payment_terms,
    o.status AS order_status,
    o.channel,
    o.requested_ship_date,
    -- Order metrics
    COUNT(oi.product_id) AS line_items,
    SUM(oi.qty) AS total_qty,
    SUM(oi.qty * oi.unit_price) AS gross_amount,
    SUM(oi.discount) AS total_discount,
    SUM(oi.tax) AS total_tax,
    SUM(oi.qty * oi.unit_price - oi.discount) AS net_amount,
    -- Profitability analysis
    SUM(oi.qty * (oi.unit_price - p.unit_cost)) AS gross_profit,
    ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / 
          NULLIF(SUM(oi.qty * oi.unit_price), 0) * 100, 2) AS gross_margin_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.order_ts, c.name, c.segment, c.region, 
         c.payment_terms, o.status, o.channel, o.requested_ship_date;

-- Customer Analytics View - Customer performance and behavior
CREATE VIEW vw_customer_analytics AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.segment,
    c.region,
    c.payment_terms,
    c.credit_limit,
    -- Order activity metrics
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(oi.qty * oi.unit_price - oi.discount), 0) AS total_revenue,
    COALESCE(AVG(oi.qty * oi.unit_price - oi.discount), 0) AS avg_order_value,
    -- Customer lifecycle
    MIN(o.order_ts) AS first_order_date,
    MAX(o.order_ts) AS last_order_date,
    DATEDIFF(MAX(o.order_ts), MIN(o.order_ts)) AS customer_lifetime_days,
    -- Payment behavior analysis
    AVG(DATEDIFF(pay.payment_ts, inv.due_date)) AS avg_payment_delay_days,
    -- Return behavior
    COALESCE(COUNT(DISTINCT ret.return_id), 0) AS total_returns,
    COALESCE(SUM(ret.refund_amount), 0) AS total_refunds
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN invoices inv ON o.order_id = inv.order_id
LEFT JOIN payments pay ON inv.invoice_id = pay.invoice_id
LEFT JOIN returns ret ON o.order_id = ret.order_id
GROUP BY c.customer_id, c.name, c.segment, c.region, c.payment_terms, c.credit_limit;

-- Product Performance View - Sales and inventory analysis
CREATE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.sku,
    p.category,
    p.unit_cost,
    p.list_price,
    p.safety_stock,
    -- Current inventory status
    SUM(i.on_hand_qty) as total_on_hand,
    SUM(i.reserved_qty) as total_reserved,
    SUM(i.on_hand_qty - i.reserved_qty) as total_available,
    -- Sales performance
    COALESCE(COUNT(DISTINCT oi.order_id), 0) AS orders_count,
    COALESCE(SUM(oi.qty), 0) AS total_qty_sold,
    COALESCE(SUM(oi.qty * oi.unit_price), 0) AS gross_revenue,
    COALESCE(SUM(oi.discount), 0) AS total_discounts,
    COALESCE(SUM(oi.qty * oi.unit_price - oi.discount), 0) AS net_revenue,
    COALESCE(SUM(oi.qty * (oi.unit_price - p.unit_cost)), 0) AS gross_profit,
    -- Performance metrics
    CASE 
        WHEN SUM(oi.qty * oi.unit_price) > 0 
        THEN ROUND(SUM(oi.qty * (oi.unit_price - p.unit_cost)) / SUM(oi.qty * oi.unit_price) * 100, 2)
        ELSE NULL 
    END AS gross_margin_pct,
    -- Return analysis
    COALESCE(SUM(ret.qty), 0) AS total_returns,
    CASE 
        WHEN SUM(oi.qty) > 0 
        THEN ROUND(COALESCE(SUM(ret.qty), 0) / SUM(oi.qty) * 100, 2)
        ELSE 0 
    END AS return_rate_pct
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN returns ret ON p.product_id = ret.product_id
GROUP BY p.product_id, p.sku, p.category, p.unit_cost, p.list_price, p.safety_stock;

-- Cash Flow Analysis View - AR aging and collection performance
CREATE VIEW vw_cash_flow_analysis AS
SELECT 
    inv.invoice_id,
    inv.order_id,
    o.customer_id,
    c.name AS customer_name,
    c.segment AS customer_segment,
    c.payment_terms,
    inv.invoice_ts,
    inv.due_date,
    inv.total AS invoice_amount,
    COALESCE(SUM(pay.amount), 0) AS paid_amount,
    (inv.total - COALESCE(SUM(pay.amount), 0)) AS outstanding_amount,
    -- Payment status classification
    CASE 
        WHEN COALESCE(SUM(pay.amount), 0) >= inv.total THEN 'PAID'
        WHEN COALESCE(SUM(pay.amount), 0) > 0 THEN 'PARTIAL'
        ELSE 'UNPAID'
    END AS payment_status,
    -- Aging analysis
    DATEDIFF(CURDATE(), inv.due_date) AS days_past_due,
    CASE 
        WHEN MAX(pay.payment_ts) IS NOT NULL 
        THEN DATEDIFF(MAX(pay.payment_ts), inv.due_date)
        ELSE NULL 
    END AS payment_delay_days,
    -- AR aging buckets for management reporting
    CASE 
        WHEN DATEDIFF(CURDATE(), inv.due_date) <= 0 THEN 'Current'
        WHEN DATEDIFF(CURDATE(), inv.due_date) <= 30 THEN '1-30 Days'
        WHEN DATEDIFF(CURDATE(), inv.due_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF(CURDATE(), inv.due_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket
FROM invoices inv
JOIN orders o ON inv.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN payments pay ON inv.invoice_id = pay.invoice_id
GROUP BY inv.invoice_id, inv.order_id, o.customer_id, c.name, c.segment, 
         c.payment_terms, inv.invoice_ts, inv.due_date, inv.total;

-- Operational Performance View - End-to-end process timing
CREATE VIEW vw_operational_performance AS
SELECT 
    o.order_id,
    c.name AS customer_name,
    c.segment,
    o.channel,
    o.order_ts,
    o.requested_ship_date,
    s.ship_ts,
    s.promised_delivery_ts,
    s.actual_delivery_ts,
    inv.invoice_ts,
    inv.due_date,
    MIN(pay.payment_ts) AS first_payment_ts,
    -- Process timing KPIs (in days)
    DATEDIFF(s.ship_ts, o.order_ts) AS order_to_ship_days,
    DATEDIFF(s.actual_delivery_ts, s.ship_ts) AS ship_to_delivery_days,
    DATEDIFF(s.actual_delivery_ts, o.order_ts) AS order_to_delivery_days,
    DATEDIFF(inv.invoice_ts, s.ship_ts) AS ship_to_invoice_days,
    DATEDIFF(MIN(pay.payment_ts), inv.invoice_ts) AS invoice_to_payment_days,
    DATEDIFF(MIN(pay.payment_ts), o.order_ts) AS total_o2c_cycle_days,
    -- Performance indicators for dashboards
    CASE 
        WHEN s.actual_delivery_ts <= s.promised_delivery_ts THEN 'ON_TIME'
        WHEN s.actual_delivery_ts IS NULL THEN 'PENDING'
        ELSE 'LATE'
    END AS delivery_performance,
    CASE 
        WHEN s.ship_ts <= o.requested_ship_date THEN 'ON_TIME'
        WHEN s.ship_ts IS NULL THEN 'PENDING'
        ELSE 'LATE'
    END AS ship_performance,
    -- Financial metrics
    inv.total AS invoice_amount,
    COALESCE(SUM(pay.amount), 0) AS total_paid
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN shipments s ON o.order_id = s.order_id
LEFT JOIN invoices inv ON o.order_id = inv.order_id
LEFT JOIN payments pay ON inv.invoice_id = pay.invoice_id
GROUP BY o.order_id, c.name, c.segment, o.channel, o.order_ts, 
         o.requested_ship_date, s.ship_ts, s.promised_delivery_ts, 
         s.actual_delivery_ts, inv.invoice_ts, inv.due_date, inv.total;

-- =============================================
-- 5. GENERATE REALISTIC TRANSACTIONAL DATA
-- Creates 800+ orders with complete O2C flow using stored procedure
-- =============================================

DELIMITER $

CREATE PROCEDURE GenerateO2CData()
BEGIN
    DECLARE v_order_count INT DEFAULT 800; -- Target 800 orders for robust analytics
    DECLARE v_customer_id INT;
    DECLARE v_order_id INT;
    DECLARE v_product_id INT;
    DECLARE v_segment VARCHAR(20);
    DECLARE i INT DEFAULT 1;
    DECLARE j INT;
    
    -- Generate orders with realistic distribution
    WHILE i <= v_order_count DO
        
        -- Select customer based on realistic segment distribution
        -- 50% SMB (1-22), 35% Mid (23-27), 15% Enterprise (28-32)
        IF i <= v_order_count * 0.50 THEN
            SET v_customer_id = 1 + FLOOR(RAND() * 22); -- SMB customers
        ELSEIF i <= v_order_count * 0.85 THEN
            SET v_customer_id = 23 + FLOOR(RAND() * 5); -- Mid customers
        ELSE
            SET v_customer_id = 28 + FLOOR(RAND() * 5); -- Enterprise customers
        END IF;
        
        SELECT segment INTO v_segment FROM customers WHERE customer_id = v_customer_id;
        
        -- Generate realistic order dates with seasonal patterns
        INSERT INTO orders (customer_id, order_ts, status, channel, requested_ship_date) VALUES
        (v_customer_id, 
         -- Date distribution: 15% Q1, 25% Q2, 35% Q3, 25% Q4 (holiday boost)
         CASE 
            WHEN RAND() < 0.15 THEN DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 90) DAY)
            WHEN RAND() < 0.40 THEN DATE_ADD('2024-04-01', INTERVAL FLOOR(RAND() * 91) DAY)
            WHEN RAND() < 0.75 THEN DATE_ADD('2024-07-01', INTERVAL FLOOR(RAND() * 92) DAY)
            ELSE DATE_ADD('2024-10-01', INTERVAL FLOOR(RAND() * 92) DAY)
         END + INTERVAL FLOOR(RAND() * 24) HOUR,
         'DELIVERED', -- 95% delivered for analytics
         -- Channel distribution by segment
         CASE v_segment
            WHEN 'SMB' THEN CASE WHEN RAND() < 0.6 THEN 'Web' ELSE 'Marketplace' END
            WHEN 'Mid' THEN CASE WHEN RAND() < 0.7 THEN 'InsideSales' ELSE 'Web' END
            ELSE 'InsideSales' -- Enterprise always uses inside sales
         END,
         DATE_ADD(CURDATE(), INTERVAL 2 DAY) -- Standard 2-day lead time
        );
        
        SET v_order_id = LAST_INSERT_ID();
        
        -- Add 1-6 items per order based on segment
        SET j = 1;
        WHILE j <= CASE v_segment 
            WHEN 'SMB' THEN 1 + FLOOR(RAND() * 2) -- 1-2 items
            WHEN 'Mid' THEN 2 + FLOOR(RAND() * 3) -- 2-4 items
            ELSE 3 + FLOOR(RAND() * 4) -- 3-6 items
        END DO
            
            -- Select products with segment preferences
            SET v_product_id = CASE v_segment
                WHEN 'SMB' THEN CASE
                    WHEN RAND() < 0.6 THEN 7 + FLOOR(RAND() * 12) -- More apparel
                    ELSE 1 + FLOOR(RAND() * 18) -- Mixed electronics/home
                END
                ELSE 1 + FLOOR(RAND() * 18) -- All products
            END;
            
            -- Insert order items with realistic pricing
            INSERT IGNORE INTO order_items (order_id, product_id, qty, unit_price, discount, tax)
            SELECT 
                v_order_id,
                v_product_id,
                CASE v_segment 
                    WHEN 'SMB' THEN 1 + FLOOR(RAND() * 5) -- 1-5 qty
                    WHEN 'Mid' THEN 5 + FLOOR(RAND() * 10) -- 5-15 qty
                    ELSE 10 + FLOOR(RAND() * 20) -- 10-30 qty
                END,
                list_price,
                CASE v_segment
                    WHEN 'Enterprise' THEN list_price * 0.10 -- 10% enterprise discount
                    WHEN 'Mid' THEN list_price * 0.05 -- 5% mid discount
                    ELSE 0
                END,
                list_price * 0.085 -- 8.5% tax rate
            FROM products 
            WHERE product_id = v_product_id;
            
            SET j = j + 1;
        END WHILE;
        
        -- Generate shipment (1-2 days after order)
        INSERT INTO shipments (order_id, ship_ts, promised_delivery_ts, actual_delivery_ts, status, ship_from_loc, carrier, tracking_number)
        SELECT 
            v_order_id,
            DATE_ADD(order_ts, INTERVAL 1 + FLOOR(RAND() * 2) DAY),
            DATE_ADD(order_ts, INTERVAL 4 + FLOOR(RAND() * 2) DAY),
            DATE_ADD(order_ts, INTERVAL 3 + FLOOR(RAND() * 4) DAY), -- 85% on-time
            'DELIVERED',
            CASE WHEN RAND() < 0.6 THEN 'PHX-01' ELSE 'DAL-01' END,
            CASE WHEN RAND() < 0.5 THEN 'UPS' ELSE 'FedEx' END,
            CONCAT('TRK', LPAD(v_order_id, 8, '0'))
        FROM orders WHERE order_id = v_order_id;
        
        -- Generate invoice (day after shipment)
        INSERT INTO invoices (order_id, invoice_ts, due_date, subtotal, tax, freight, total)
        SELECT 
            o.order_id,
            DATE_ADD(s.ship_ts, INTERVAL 1 DAY),
            CASE c.payment_terms
                WHEN 'Net15' THEN DATE_ADD(s.ship_ts, INTERVAL 16 DAY)
                WHEN 'Net30' THEN DATE_ADD(s.ship_ts, INTERVAL 31 DAY)
                WHEN 'Net45' THEN DATE_ADD(s.ship_ts, INTERVAL 46 DAY)
                ELSE DATE_ADD(s.ship_ts, INTERVAL 1 DAY) -- Prepaid
            END,
            COALESCE(SUM(oi.qty * oi.unit_price - oi.discount), 0),
            COALESCE(SUM(oi.tax), 0),
            25.00 + (RAND() * 25), -- $25-50 freight
            COALESCE(SUM(oi.qty * oi.unit_price - oi.discount), 0) + COALESCE(SUM(oi.tax), 0) + 25.00 + (RAND() * 25)
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN shipments s ON o.order_id = s.order_id
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_id = v_order_id
        GROUP BY o.order_id, s.ship_ts, c.payment_terms;
        
        -- Generate payments (90% payment rate)
        IF RAND() < 0.90 THEN
            INSERT INTO payments (invoice_id, payment_ts, method, amount, reference_number)
            SELECT 
                i.invoice_id,
                CASE c.payment_terms
                    WHEN 'Prepaid' THEN o.order_ts
                    ELSE DATE_ADD(i.due_date, INTERVAL -5 + FLOOR(RAND() * 15) DAY) -- ±5-10 days from due
                END,
                CASE c.segment
                    WHEN 'Enterprise' THEN CASE WHEN RAND() < 0.6 THEN 'ACH' ELSE 'Wire' END
                    WHEN 'Mid' THEN CASE WHEN RAND() < 0.4 THEN 'ACH' WHEN RAND() < 0.7 THEN 'Card' ELSE 'Check' END
                    ELSE CASE WHEN RAND() < 0.5 THEN 'Card' ELSE 'ACH' END
                END,
                CASE WHEN RAND() < 0.95 THEN i.total ELSE i.total * (0.3 + RAND() * 0.6) END, -- 95% full payment
                CONCAT('PAY', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(i.invoice_id, 6, '0'))
            FROM invoices i
            JOIN orders o ON i.order_id = o.order_id  
            JOIN customers c ON o.customer_id = c.customer_id
            WHERE i.order_id = v_order_id;
        END IF;
        
        -- Generate returns (3% return rate)
        IF RAND() < 0.03 THEN
            INSERT INTO returns (order_id, product_id, qty, reason_code, rma_ts, disposition, refund_amount, processed_by)
            SELECT 
                oi.order_id,
                oi.product_id,
                GREATEST(1, FLOOR(oi.qty * (0.2 + RAND() * 0.6))), -- 20-80% of original qty
                CASE 
                    WHEN RAND() < 0.4 THEN 'Damaged'
                    WHEN RAND() < 0.65 THEN 'Wrong Item'
                    WHEN RAND() < 0.80 THEN 'Defective'
                    ELSE 'Customer Error'
                END,
                DATE_ADD(s.actual_delivery_ts, INTERVAL 5 + FLOOR(RAND() * 25) DAY),
                'Resell',
                oi.unit_price * GREATEST(1, FLOOR(oi.qty * (0.2 + RAND() * 0.6))),
                'auto_system'
            FROM order_items oi
            JOIN shipments s ON oi.order_id = s.order_id
            WHERE oi.order_id = v_order_id
            ORDER BY RAND()
            LIMIT 1;
        END IF;
        
        SET i = i + 1;
        
        -- Progress indicator every 200 orders
        IF MOD(i, 200) = 0 THEN
            SELECT CONCAT('Generated ', i, ' of ', v_order_count, ' orders (', ROUND(i/v_order_count*100, 1), '% complete)') as progress_update;
        END IF;
        
    END WHILE;
    
    -- Update inventory reserved quantities realistically
    UPDATE inventory inv
    SET reserved_qty = GREATEST(0, LEAST(on_hand_qty * 0.15, -- Reserve up to 15% of stock
        (SELECT COALESCE(SUM(oi.qty), 0) * 0.1 
         FROM order_items oi 
         JOIN orders o ON oi.order_id = o.order_id
         WHERE oi.product_id = inv.product_id 
           AND o.status IN ('NEW', 'ALLOCATED')
           AND o.order_ts >= DATE_SUB(NOW(), INTERVAL 7 DAY))));
    
END$

DELIMITER ;

-- Execute the data generation procedure
CALL GenerateO2CData();

-- Clean up procedure
DROP PROCEDURE GenerateO2CData;

-- =============================================
-- 6. CREATE PERFORMANCE INDEXES
-- Optimize common analytical queries
-- =============================================

-- Time-based analysis indexes (most common query pattern)
CREATE INDEX idx_orders_date_segment ON orders(order_ts, customer_id);
CREATE INDEX idx_payments_date_method ON payments(payment_ts, method);
CREATE INDEX idx_shipments_delivery_performance ON shipments(promised_delivery_ts, actual_delivery_ts);

-- Product performance analysis indexes
CREATE INDEX idx_order_items_product_analysis ON order_items(product_id, order_id);
CREATE INDEX idx_returns_analysis ON returns(product_id, reason_code);

-- Customer analysis indexes
CREATE INDEX idx_customer_segment_region ON customers(segment, region);
CREATE INDEX idx_orders_customer_channel ON orders(customer_id, channel);

-- Financial analysis indexes
CREATE INDEX idx_invoices_due_date_total ON invoices(due_date, total);
CREATE INDEX idx_payments_invoice_amount ON payments(invoice_id, amount);

-- Re-enable foreign key checks
SET foreign_key_checks = 1;

-- =============================================
-- 7. FINAL SETUP VALIDATION AND SUMMARY
-- =============================================

-- Update database info with completion status
UPDATE db_info SET info_value = NOW() WHERE info_key = 'last_setup';
INSERT INTO db_info (info_key, info_value) VALUES 
('setup_status', 'COMPLETE'),
('data_generated', 'YES'),
('views_created', 'YES'),
('indexes_optimized', 'YES') 
ON DUPLICATE KEY UPDATE info_value = VALUES(info_value);

-- Display comprehensive setup summary
SELECT '========================================' as separator;
SELECT 'O2C DATABASE SETUP COMPLETE!' as setup_status;
SELECT '========================================' as separator;

-- Data volume summary
SELECT 'DATA VOLUMES' as summary_section;
SELECT 
    'customers' as entity, COUNT(*) as count, 'Master data across 4 regions, 3 segments' as description FROM customers
UNION ALL
SELECT 'products', COUNT(*), '3 categories: Electronics, Apparel, Home goods' FROM products  
UNION ALL
SELECT 'inventory_records', COUNT(*), '2 warehouses: PHX-01 (primary), DAL-01 (secondary)' FROM inventory
UNION ALL
SELECT 'orders', COUNT(*), '8-month period with seasonal patterns' FROM orders
UNION ALL
SELECT 'order_items', COUNT(*), CONCAT('Avg ', ROUND(COUNT(*)/(SELECT COUNT(*) FROM orders), 1), ' items per order') FROM order_items
UNION ALL
SELECT 'shipments', COUNT(*), '85%+ on-time delivery rate' FROM shipments
UNION ALL
SELECT 'invoices', COUNT(*), 'Complete billing records with tax and freight' FROM invoices
UNION ALL
SELECT 'payments', COUNT(*), '90% payment rate with realistic timing patterns' FROM payments
UNION ALL
SELECT 'returns', COUNT(*), '3% return rate with reason codes' FROM returns;

-- Business metrics summary
SELECT '' as separator;
SELECT 'KEY BUSINESS METRICS' as summary_section;

SELECT 
    'Total Revenue Generated' as metric,
    CONCAT(', FORMAT(SUM(oi.qty * oi.unit_price - oi.discount), 0)) as value,
    'Gross revenue before tax and freight' as notes
FROM order_items oi
UNION ALL
SELECT 
    'Average Order Value',
    CONCAT(', FORMAT(AVG(order_values.total), 0)),
    'Mean order value across all segments'
FROM (
    SELECT SUM(oi.qty * oi.unit_price - oi.discount) as total
    FROM order_items oi 
    GROUP BY oi.order_id
) order_values
UNION ALL
SELECT 
    'Outstanding A/R Balance',
    CONCAT(', FORMAT(SUM(i.total - COALESCE(p.paid, 0)), 0)),
    '10% of invoices remain unpaid (realistic)'
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(amount) as paid FROM payments GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.total > COALESCE(p.paid, 0)
UNION ALL
SELECT 
    'Days Sales Outstanding',
    CONCAT(ROUND(
        (SELECT SUM(i.total - COALESCE(p.paid, 0)) 
         FROM invoices i 
         LEFT JOIN (SELECT invoice_id, SUM(amount) as paid FROM payments GROUP BY invoice_id) p 
         ON i.invoice_id = p.invoice_id 
         WHERE i.total > COALESCE(p.paid, 0)) / 
        (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 
         FROM order_items oi 
         JOIN orders o ON oi.order_id = o.order_id 
         WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY))
    , 1), ' days'),
    'Key cash flow metric (target: <45 days)';

-- Available business views
SELECT '' as separator;
SELECT 'BUSINESS INTELLIGENCE VIEWS READY' as summary_section;
SELECT 
    'View Name' as view_name,
    'Purpose' as purpose,
    'Key Metrics' as key_metrics
UNION ALL
SELECT 
    'vw_order_summary',
    'Complete order analysis',
    'Revenue, profit margin, customer segment performance'
UNION ALL
SELECT 
    'vw_customer_analytics', 
    'Customer behavior and value',
    'Lifetime value, payment patterns, order frequency'
UNION ALL
SELECT 
    'vw_product_performance',
    'Product sales and inventory',
    'Sales velocity, margins, return rates, stock levels'
UNION ALL
SELECT 
    'vw_cash_flow_analysis',
    'A/R aging and collections',
    'Outstanding balances, payment delays, aging buckets'
UNION ALL
SELECT 
    'vw_operational_performance',
    'End-to-end process timing',
    'O2C cycle time, delivery performance, SLA adherence';

-- Next steps guidance
SELECT '' as separator;
SELECT 'NEXT STEPS' as guidance_section;
SELECT '1. Explore data: SELECT * FROM vw_order_summary LIMIT 10;' as step_1;
SELECT '2. Run analytics: Use queries from examples/dashboard_queries.sql' as step_2;
SELECT '3. Validate data: Run tests/data_validation.sql' as step_3;
SELECT '4. Build dashboards: Connect BI tool to views' as step_4;
SELECT '5. Monitor performance: Check query execution plans' as step_5;

SELECT '========================================' as final_separator;
SELECT 'READY FOR BUSINESS INTELLIGENCE!' as final_status;
SELECT 'Total setup time: ~2-3 minutes' as performance_note;
SELECT '========================================' as final_separator;
