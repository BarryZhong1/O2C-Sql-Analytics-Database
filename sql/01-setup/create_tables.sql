-- =============================================
-- O2C TABLE CREATION SCRIPT
-- Creates all tables for the O2C database
-- =============================================

USE `o2c`;

-- Disable foreign key checks during table creation
SET foreign_key_checks = 0;

-- =============================================
-- 1. CUSTOMERS TABLE
-- =============================================
CREATE TABLE `customers` (
    `customer_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(200) NOT NULL,
    `segment` enum('SMB','Mid','Enterprise') NOT NULL,
    `region` varchar(50) DEFAULT NULL,
    `payment_terms` enum('Prepaid','Net15','Net30','Net45') DEFAULT 'Net30',
    `credit_limit` decimal(12,2) DEFAULT '0.00',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`customer_id`),
    KEY `ix_customers_name` (`name`),
    KEY `ix_customers_segment` (`segment`),
    KEY `ix_customers_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Customer master data with segmentation and payment terms';

-- =============================================
-- 2. PRODUCTS TABLE
-- =============================================
CREATE TABLE `products` (
    `product_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `sku` varchar(64) NOT NULL,
    `category` varchar(80) DEFAULT NULL,
    `unit_cost` decimal(10,2) NOT NULL,
    `list_price` decimal(10,2) NOT NULL,
    `safety_stock` int DEFAULT '0',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`),
    UNIQUE KEY `sku` (`sku`),
    KEY `ix_products_category` (`category`),
    KEY `ix_products_price_range` (`list_price`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Product catalog with pricing and inventory parameters';

-- =============================================
-- 3. INVENTORY TABLE
-- =============================================
CREATE TABLE `inventory` (
    `product_id` bigint unsigned NOT NULL,
    `loc_code` varchar(32) NOT NULL,
    `on_hand_qty` int DEFAULT '0',
    `reserved_qty` int DEFAULT '0',
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`product_id`,`loc_code`),
    KEY `ix_inventory_location` (`loc_code`),
    KEY `ix_inventory_availability` (`on_hand_qty`),
    CONSTRAINT `fk_inventory_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Real-time inventory tracking by product and location';

-- =============================================
-- 4. ORDERS TABLE
-- =============================================
CREATE TABLE `orders` (
    `order_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `customer_id` bigint unsigned NOT NULL,
    `order_ts` datetime NOT NULL,
    `status` enum('NEW','ALLOCATED','SHIPPED','DELIVERED','CANCELLED') DEFAULT 'NEW',
    `channel` enum('Web','Marketplace','InsideSales') NOT NULL,
    `requested_ship_date` date DEFAULT NULL,
    `promo_code` varchar(40) DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`),
    KEY `fk_orders_customer` (`customer_id`),
    KEY `ix_orders_status` (`status`),
    KEY `ix_orders_channel` (`channel`),
    KEY `ix_orders_date` (`order_ts`),
    CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Customer order header information with status tracking';

-- =============================================
-- 5. ORDER_ITEMS TABLE
-- =============================================
CREATE TABLE `order_items` (
    `order_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `qty` int NOT NULL,
    `unit_price` decimal(10,2) NOT NULL,
    `discount` decimal(10,2) DEFAULT '0.00',
    `tax` decimal(10,2) DEFAULT '0.00',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`,`product_id`),
    KEY `ix_oi_product` (`product_id`),
    KEY `ix_oi_pricing` (`unit_price`),
    CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_oi_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_oi_qty_positive` CHECK (`qty` > 0),
    CONSTRAINT `chk_oi_price_positive` CHECK (`unit_price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Order line items with pricing, discounts, and tax details';

-- =============================================
-- 6. SHIPMENTS TABLE
-- =============================================
CREATE TABLE `shipments` (
    `shipment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `ship_ts` datetime DEFAULT NULL,
    `promised_delivery_ts` datetime DEFAULT NULL,
    `actual_delivery_ts` datetime DEFAULT NULL,
    `status` varchar(30) DEFAULT 'PENDING',
    `ship_from_loc` varchar(32) DEFAULT NULL,
    `carrier` varchar(50) DEFAULT NULL,
    `tracking_number` varchar(100) DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`shipment_id`),
    KEY `ix_shipments_order` (`order_id`),
    KEY `ix_shipments_status` (`status`),
    KEY `ix_shipments_carrier` (`carrier`),
    KEY `ix_shipments_ship_date` (`ship_ts`),
    CONSTRAINT `fk_shipments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Shipment tracking and delivery performance monitoring';

-- =============================================
-- 7. INVOICES TABLE
-- =============================================
CREATE TABLE `invoices` (
    `invoice_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `invoice_ts` datetime NOT NULL,
    `due_date` date NOT NULL,
    `subtotal` decimal(12,2) NOT NULL,
    `tax` decimal(12,2) DEFAULT '0.00',
    `freight` decimal(12,2) DEFAULT '0.00',
    `total` decimal(12,2) NOT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`invoice_id`),
    KEY `ix_invoices_order` (`order_id`),
    KEY `ix_invoices_due_date` (`due_date`),
    KEY `ix_invoices_total` (`total`),
    CONSTRAINT `fk_invoices_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_invoices_total_positive` CHECK (`total` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Invoice generation with tax and freight calculations';

-- =============================================
-- 8. PAYMENTS TABLE
-- =============================================
CREATE TABLE `payments` (
    `payment_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `invoice_id` bigint unsigned NOT NULL,
    `payment_ts` datetime NOT NULL,
    `method` enum('ACH','Wire','Card','Check') NOT NULL,
    `amount` decimal(12,2) NOT NULL,
    `reference_number` varchar(100) DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`payment_id`),
    KEY `ix_payments_invoice` (`invoice_id`),
    KEY `ix_payments_method` (`method`),
    KEY `ix_payments_date` (`payment_ts`),
    KEY `ix_payments_amount` (`amount`),
    CONSTRAINT `fk_payments_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_payments_amount_positive` CHECK (`amount` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Payment processing and cash collection tracking';

-- =============================================
-- 9. RETURNS TABLE
-- =============================================
CREATE TABLE `returns` (
    `return_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `order_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `qty` int NOT NULL,
    `reason_code` varchar(40) DEFAULT NULL,
    `rma_ts` datetime NOT NULL,
    `disposition` enum('Resell','Refurbish','Scrap') DEFAULT NULL,
    `refund_amount` decimal(10,2) DEFAULT '0.00',
    `processed_by` varchar(100) DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`return_id`),
    KEY `ix_returns_order_product` (`order_id`,`product_id`),
    KEY `fk_returns_product` (`product_id`),
    KEY `ix_returns_reason` (`reason_code`),
    KEY `ix_returns_disposition` (`disposition`),
    CONSTRAINT `fk_returns_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_returns_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE RESTRICT,
    CONSTRAINT `chk_returns_qty_positive` CHECK (`qty` > 0),
    CONSTRAINT `chk_returns_refund_nonnegative` CHECK (`refund_amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Return merchandise authorization and disposition tracking';

-- =============================================
-- 10. AUDIT TABLE (Optional - for change tracking)
-- =============================================
CREATE TABLE `audit_log` (
    `audit_id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `table_name` varchar(50) NOT NULL,
    `operation` enum('INSERT','UPDATE','DELETE') NOT NULL,
    `record_id` bigint unsigned NOT NULL,
    `old_values` json DEFAULT NULL,
    `new_values` json DEFAULT NULL,
    `changed_by` varchar(100) DEFAULT USER(),
    `changed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`audit_id`),
    KEY `ix_audit_table` (`table_name`),
    KEY `ix_audit_operation` (`operation`),
    KEY `ix_audit_date` (`changed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='Audit trail for data changes';

-- Re-enable foreign key checks
SET foreign_key_checks = 1;

-- =============================================
-- TABLE CREATION VERIFICATION
-- =============================================
SELECT 'Tables created successfully!' as Status;

-- Show table summary
SELECT 
    TABLE_NAME as 'Table Name',
    TABLE_ROWS as 'Est. Rows',
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) as 'Size (MB)',
    TABLE_COMMENT as 'Description'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'o2c' 
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
