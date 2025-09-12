-- =============================================
-- O2C LARGE DATASET GENERATION SCRIPT
-- Generates realistic data for comprehensive analytics testing
-- This creates a substantial dataset for meaningful business intelligence
-- =============================================

USE `o2c`;

-- Temporarily disable foreign key checks for faster bulk inserts
-- This prevents MySQL from validating relationships during each insert
-- Re-enabled at the end to maintain data integrity
SET foreign_key_checks = 0;

-- Clear all existing data to start fresh
-- Order matters due to foreign key relationships (child tables first)
TRUNCATE TABLE payments;
TRUNCATE TABLE returns; 
TRUNCATE TABLE shipments;
TRUNCATE TABLE invoices;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE inventory;
TRUNCATE TABLE products;
TRUNCATE TABLE customers;

-- =============================================
-- 1. GENERATE CUSTOMERS (75 total across segments)
-- Purpose: Create diverse customer base representing real business mix
-- Segment distribution: ~60% SMB, 27% Mid-market, 13% Enterprise (realistic proportions)
-- =============================================

INSERT INTO customers (name, segment, region, payment_terms, credit_limit, created_at) VALUES

-- SMB Customers (45 customers) - Small/Medium Business segment
-- Credit limits: $15K-$50K typical for smaller businesses
-- Mix of payment terms with Net30 being most common
('Sunrise Retail LLC', 'SMB', 'West', 'Net30', 45000, '2024-01-15 09:00:00'),
('Valley Sports Center', 'SMB', 'West', 'Net15', 35000, '2024-01-22 10:30:00'), -- Net15 for faster cash flow
('Desert Electronics Co', 'SMB', 'West', 'Net30', 28000, '2024-02-01 14:15:00'),
('Phoenix Auto Parts', 'SMB', 'West', 'Net30', 42000, '2024-02-10 11:20:00'),
('Cactus Corner Store', 'SMB', 'West', 'Prepaid', 15000, '2024-02-15 16:45:00'), -- Prepaid for new/risky customers
('Mountain View Retail', 'SMB', 'West', 'Net30', 50000, '2024-03-01 08:30:00'),
('Scottsdale Office Supply', 'SMB', 'West', 'Net15', 32000, '2024-03-10 12:00:00'),
('Arizona Outdoor Gear', 'SMB', 'West', 'Net30', 47000, '2024-03-15 14:30:00'),
('Tempe Tech Solutions', 'SMB', 'West', 'Net15', 29000, '2024-03-20 09:15:00'),
('Glendale General Store', 'SMB', 'West', 'Net30', 38000, '2024-04-01 11:45:00'),

-- Southern SMB customers (15 customers) - Geographic diversification
('Dallas Direct Sales', 'SMB', 'South', 'Net30', 46000, '2024-04-05 10:15:00'),
('Houston Hardware Hub', 'SMB', 'South', 'Net15', 33000, '2024-04-10 13:30:00'),
('Austin Electronics Express', 'SMB', 'South', 'Net30', 49000, '2024-04-15 15:20:00'),
('San Antonio Supplies', 'SMB', 'South', 'Net30', 41000, '2024-04-20 08:45:00'),
('Fort Worth Fashion', 'SMB', 'South', 'Prepaid', 22000, '2024-05-01 12:30:00'),
('Miami Metro Market', 'SMB', 'South', 'Net30', 44000, '2024-05-05 14:15:00'),
('Orlando Office Depot', 'SMB', 'South', 'Net15', 31000, '2024-05-10 09:30:00'),
('Tampa Technology', 'SMB', 'South', 'Net30', 43000, '2024-05-15 11:15:00'),
('Jacksonville Jewelers', 'SMB', 'South', 'Net30', 36000, '2024-05-20 16:00:00'),
('Atlanta Auto Accessories', 'SMB', 'South', 'Net15', 27000, '2024-06-01 10:45:00'),
('Nashville Novelties', 'SMB', 'South', 'Net30', 39000, '2024-06-05 13:15:00'),
('Charlotte Computer Co', 'SMB', 'South', 'Net15', 34000, '2024-06-10 15:30:00'),
('Raleigh Retail Plus', 'SMB', 'South', 'Net30', 45000, '2024-06-15 08:20:00'),
('Birmingham Business', 'SMB', 'South', 'Net30', 37000, '2024-06-20 12:15:00'),
('New Orleans Outfitters', 'SMB', 'South', 'Net30', 40000, '2024-07-01 14:45:00'),

-- Northern SMB customers (10 customers)
('Denver Digital Direct', 'SMB', 'North', 'Net30', 48000, '2024-07-05 09:30:00'),
('Colorado Springs Supply', 'SMB', 'North', 'Net15', 26000, '2024-07-10 11:30:00'),
('Salt Lake Solutions', 'SMB', 'North', 'Net30', 50000, '2024-07-15 13:45:00'),
('Portland Products Plus', 'SMB', 'North', 'Net30', 35000, '2024-07-20 16:15:00'),
('Seattle Systems Store', 'SMB', 'North', 'Prepaid', 18000, '2024-08-01 10:00:00'),
('Boise Business Bureau', 'SMB', 'North', 'Net30', 37000, '2024-08-05 12:30:00'),
('Spokane Specialty Shop', 'SMB', 'North', 'Net15', 25000, '2024-08-10 14:45:00'),
('Tacoma Tech Traders', 'SMB', 'North', 'Net30', 44000, '2024-08-15 09:15:00'),
('Reno Retail Resources', 'SMB', 'North', 'Net30', 41000, '2024-08-20 11:30:00'),
('Las Vegas Luxury', 'SMB', 'North', 'Net15', 33000, '2024-08-25 15:45:00'),

-- Eastern SMB customers (10 customers)
('Boston Business Basics', 'SMB', 'East', 'Net30', 46000, '2024-08-30 08:30:00'),
('New York Niche Market', 'SMB', 'East', 'Net15', 31000, '2024-09-05 10:15:00'),
('Philadelphia Products', 'SMB', 'East', 'Net30', 48000, '2024-09-10 12:45:00'),
('Baltimore Boutique', 'SMB', 'East', 'Net30', 39000, '2024-09-15 14:20:00'),
('Washington Wholesale', 'SMB', 'East', 'Net15', 29000, '2024-09-20 16:30:00'),

-- Mid-Market Customers (20 customers) - Regional distributors and larger retailers
-- Credit limits: $150K-$300K for established medium businesses
-- More Net45 terms due to larger order volumes and established relationships
('Regional Retail Chain West', 'Mid', 'West', 'Net30', 180000, '2024-01-10 09:30:00'),
('Western Wholesale Distribution', 'Mid', 'West', 'Net45', 220000, '2024-01-25 11:15:00'), -- Net45 for bulk orders
('California Commerce Corp', 'Mid', 'West', 'Net30', 195000, '2024-02-05 14:20:00'),
('Nevada Networks Inc', 'Mid', 'West', 'Net30', 160000, '2024-02-20 10:45:00'),
('Arizona Alliance Group', 'Mid', 'West', 'Net45', 240000, '2024-03-05 13:30:00'),
('Utah United Distributors', 'Mid', 'West', 'Net30', 175000, '2024-03-25 15:45:00'),
('Colorado Commercial Corp', 'Mid', 'North', 'Net30', 200000, '2024-04-10 08:15:00'),
('Northwestern Network LLC', 'Mid', 'North', 'Net45', 225000, '2024-04-25 12:45:00'),
('Pacific Partners Group', 'Mid', 'North', 'Net30', 185000, '2024-05-10 14:30:00'),
('Mountain States Distribution', 'Mid', 'North', 'Net30', 170000, '2024-05-25 09:15:00'),
('Southern Solutions Network', 'Mid', 'South', 'Net30', 190000, '2024-06-10 11:30:00'),
('Texas Trading Company', 'Mid', 'South', 'Net45', 210000, '2024-06-25 13:15:00'), -- Net45 for established relationship
('Gulf Coast Group LLC', 'Mid', 'South', 'Net30', 165000, '2024-07-10 15:30:00'),
('Florida Federation Inc', 'Mid', 'South', 'Net30', 180000, '2024-07-25 10:45:00'),
('Southeast Supply Syndicate', 'Mid', 'South', 'Net45', 205000, '2024-08-10 12:30:00'),
('Atlantic Alliance Corp', 'Mid', 'East', 'Net30', 175000, '2024-01-20 14:15:00'),
('Eastern Enterprise Group', 'Mid', 'East', 'Net30', 195000, '2024-02-15 16:30:00'),
('Northeast Network Inc', 'Mid', 'East', 'Net45', 230000, '2024-03-15 09:45:00'), -- Highest credit for established account
('Mid-Atlantic Markets', 'Mid', 'East', 'Net30', 185000, '2024-04-15 11:15:00'),
('Central Commerce Alliance', 'Mid', 'East', 'Net30', 200000, '2024-05-15 13:45:00'),

-- Enterprise Customers (10 customers) - Large corporations and national chains
-- Credit limits: $750K-$1.5M for enterprise accounts with high volume commitments
-- Mix of Net30 and Net45 based on negotiated enterprise agreements
('Global Retail Corporation', 'Enterprise', 'West', 'Net30', 850000, '2024-01-05 08:00:00'), -- Large retail chain
('National Distribution Network', 'Enterprise', 'North', 'Net45', 1200000, '2024-01-15 10:30:00'), -- Highest credit for major distributor
('Mega Mall Systems Inc', 'Enterprise', 'South', 'Net30', 950000, '2024-02-01 12:15:00'),
('Continental Commerce Corp', 'Enterprise', 'East', 'Net45', 1100000, '2024-02-15 14:45:00'), -- Extended terms for volume commitment
('American Retail Alliance', 'Enterprise', 'West', 'Net30', 900000, '2024-03-01 09:30:00'),
('United Supply Chain Solutions', 'Enterprise', 'North', 'Net45', 1050000, '2024-03-15 11:45:00'),
('International Trading Company', 'Enterprise', 'South', 'Net30', 800000, '2024-04-01 13:30:00'), -- Lowest enterprise credit
('Premier Distribution Network', 'Enterprise', 'East', 'Net45', 1300000, '2024-04-15 15:15:00'), -- Premium enterprise account
('Nationwide Retail Group', 'Enterprise', 'West', 'Net30', 975000, '2024-05-01 10:15:00'),
('Supreme Supply Solutions', 'Enterprise', 'North', 'Net45', 1150000, '2024-05-15 12:45:00');

-- =============================================
-- 2. GENERATE PRODUCTS (30 products across categories)
-- Purpose: Create diverse product catalog with realistic pricing strategies
-- Category mix: Electronics (high margin), Apparel (volume), Home (steady demand)
-- Pricing follows typical 2x markup strategy (100% gross margin target)
-- =============================================

INSERT INTO products (sku, category, unit_cost, list_price, safety_stock) VALUES

-- Electronics Category (12 products) - High-value, lower volume items
-- Safety stock: 25-100 units due to longer lead times and higher costs
-- Margin typically 40-60% for electronics
('ELE-SMARTPHONE-PRO', 'Electronics', 285.00, 599.99, 75), -- Premium smartphone, 110% markup
('ELE-TABLET-10IN', 'Electronics', 165.00, 349.99, 50), -- Mid-range tablet, 112% markup  
('ELE-LAPTOP-BUSINESS', 'Electronics', 420.00, 899.99, 25), -- Business laptop, 114% markup
('ELE-HEADPHONE-WIRELESS', 'Electronics', 48.00, 119.99, 100), -- Wireless headphones, 150% markup
('ELE-SPEAKER-BLUETOOTH', 'Electronics', 32.50, 79.99, 80), -- Bluetooth speaker, 146% markup
('ELE-CAMERA-DIGITAL', 'Electronics', 195.00, 449.99, 40), -- Digital camera, 131% markup
('ELE-SMARTWATCH-FITNESS', 'Electronics', 89.00, 199.99, 60), -- Fitness smartwatch, 125% markup
('ELE-CHARGER-FAST', 'Electronics', 12.50, 34.99, 200), -- Fast charger, 180% markup (accessories high margin)
('ELE-CASE-PROTECTIVE', 'Electronics', 8.25, 24.99, 250), -- Protective case, 203% markup
('ELE-CABLE-USB-C', 'Electronics', 4.50, 19.99, 300), -- USB-C cable, 344% markup (cables very high margin)
('ELE-MONITOR-24IN', 'Electronics', 118.00, 249.99, 35), -- 24" monitor, 112% markup
('ELE-KEYBOARD-MECHANICAL', 'Electronics', 45.50, 99.99, 75), -- Mechanical keyboard, 120% markup

-- Apparel Category (12 products) - Volume sellers with moderate margins
-- Safety stock: 100-300 units due to seasonal demand and size variations
-- Margin typically 50-70% for apparel (industry standard)
('APP-TSHIRT-COTTON-BASIC', 'Apparel', 8.75, 19.99, 250), -- Basic t-shirt, 128% markup
('APP-TSHIRT-PREMIUM', 'Apparel', 12.50, 29.99, 200), -- Premium t-shirt, 140% markup
('APP-POLO-CLASSIC', 'Apparel', 18.25, 39.99, 150), -- Classic polo, 119% markup
('APP-HOODIE-FLEECE', 'Apparel', 22.50, 54.99, 120), -- Fleece hoodie, 144% markup
('APP-JEANS-DENIM', 'Apparel', 28.75, 69.99, 180), -- Denim jeans, 143% markup
('APP-JACKET-WINDBREAKER', 'Apparel', 38.50, 89.99, 100), -- Windbreaker jacket, 134% markup
('APP-DRESS-CASUAL', 'Apparel', 19.25, 49.99, 110), -- Casual dress, 160% markup
('APP-SHORTS-ATHLETIC', 'Apparel', 14.50, 34.99, 180), -- Athletic shorts, 141% markup
('APP-SWEATER-WOOL', 'Apparel', 32.75, 79.99, 90), -- Wool sweater, 144% markup
('APP-BLOUSE-SILK', 'Apparel', 24.50, 59.99, 95), -- Silk blouse, 145% markup
('APP-PANTS-CHINO', 'Apparel', 21.25, 49.99, 140), -- Chino pants, 135% markup
('APP-CARDIGAN-COTTON', 'Apparel', 26.50, 64.99, 85), -- Cotton cardigan, 145% markup

-- Home Category (6 products) - Steady demand, seasonal variations
-- Safety stock: 75-200 units, moderate turnover
-- Margin varies widely: 40-80% depending on item type
('HOME-LAMP-TABLE-LED', 'Home', 28.50, 69.99, 85), -- LED table lamp, 146% markup
('HOME-PILLOW-MEMORY-FOAM', 'Home', 12.75, 34.99, 150), -- Memory foam pillow, 174% markup
('HOME-BLANKET-THROW', 'Home', 18.25, 44.99, 120), -- Throw blanket, 147% markup
('HOME-CANDLE-AROMATHERAPY', 'Home', 6.50, 18.99, 200), -- Aromatherapy candle, 192% markup (consumable high margin)
('HOME-VASE-CERAMIC', 'Home', 15.75, 39.99, 75), -- Ceramic vase, 154% markup
('HOME-MIRROR-WALL-DECORATIVE', 'Home', 22.50, 54.99, 60); -- Decorative wall mirror, 144% markup

-- =============================================
-- 3. GENERATE INVENTORY (Multi-location strategy)
-- Purpose: Realistic inventory distribution across warehouses
-- PHX-01: Primary distribution center (60% of total inventory)
-- DAL-01: Secondary distribution center (40% of total inventory)
-- Stock levels vary by product velocity and category
-- =============================================

INSERT INTO inventory (product_id, loc_code, on_hand_qty, reserved_qty, updated_at) VALUES

-- Phoenix Warehouse (PHX-01) - Primary Distribution Center
-- Higher stock levels for main warehouse, covers Western US primarily
(1, 'PHX-01', 850, 0, '2024-09-11 11:41:54'), -- Smartphones: moderate stock, high value
(2, 'PHX-01', 650, 0, '2024-09-11 11:41:54'), -- Tablets: moderate stock
(3, 'PHX-01', 300, 0, '2024-09-11 11:41:54'), -- Laptops: lower stock due to high cost
(4, 'PHX-01', 1200, 0, '2024-09-11 11:41:54'), -- Headphones: high stock, popular item
(5, 'PHX-01', 950, 0, '2024-09-11 11:41:54'), -- Speakers: good stock level
(6, 'PHX-01', 450, 0, '2024-09-11 11:41:54'), -- Cameras: moderate stock, specialty item
(7, 'PHX-01', 750, 0, '2024-09-11 11:41:54'), -- Smartwatches: growing category
(8, 'PHX-01', 2200, 0, '2024-09-11 11:41:54'), -- Chargers: high stock, fast-moving accessory
(9, 'PHX-01', 2800, 0, '2024-09-11 11:41:54'), -- Cases: very high stock, low cost/high margin
(10, 'PHX-01', 3500, 0, '2024-09-11 11:41:54'), -- Cables: highest stock, consumable
(11, 'PHX-01', 380, 0, '2024-09-11 11:41:54'), -- Monitors: lower stock, bulky/expensive
(12, 'PHX-01', 820, 0, '2024-09-11 11:41:54'), -- Keyboards: moderate stock

-- Apparel inventory at PHX-01 (higher stock for volume sales)
(13, 'PHX-01', 2800, 0, '2024-09-11 11:41:54'), -- Basic t-shirts: highest stock, staple item
(14, 'PHX-01', 2200, 0, '2024-09-11 11:41:54'), -- Premium t-shirts: high stock
(15, 'PHX-01', 1650, 0, '2024-09-11 11:41:54'), -- Polos: good stock level
(16, 'PHX-01', 1350, 0, '2024-09-11 11:41:54'), -- Hoodies: seasonal demand consideration
(17, 'PHX-01', 1980, 0, '2024-09-11 11:41:54'), -- Jeans: staple item, high stock
(18, 'PHX-01', 1100, 0, '2024-09-11 11:41:54'), -- Jackets: seasonal, moderate stock
(19, 'PHX-01', 1250, 0, '2024-09-11 11:41:54'), -- Dresses: steady demand
(20, 'PHX-01', 1850, 0, '2024-09-11 11:41:54'), -- Shorts: seasonal high demand
(21, 'PHX-01', 980, 0, '2024-09-11 11:41:54'), -- Sweaters: seasonal item
(22, 'PHX-01', 1180, 0, '2024-09-11 11:41:54'), -- Blouses: steady seller
(23, 'PHX-01', 1520, 0, '2024-09-11 11:41:54'), -- Chinos: business casual trend
(24, 'PHX-01', 920, 0, '2024-09-11 11:41:54'), -- Cardigans: moderate demand

-- Home goods inventory at PHX-01
(25, 'PHX-01', 950, 0, '2024-09-11 11:41:54'), -- Lamps: steady home decor demand
(26, 'PHX-01', 1580, 0, '2024-09-11 11:41:54'), -- Pillows: high demand comfort item
(27, 'PHX-01', 1250, 0, '2024-09-11 11:41:54'), -- Blankets: seasonal variation
(28, 'PHX-01', 2400, 0, '2024-09-11 11:41:54'), -- Candles: consumable, high stock
(29, 'PHX-01', 820, 0, '2024-09-11 11:41:54'), -- Vases: decorative, moderate demand
(30, 'PHX-01', 680, 0, '2024-09-11 11:41:54'), -- Mirrors: lower turnover, decorative

-- Dallas Warehouse (DAL-01) - Secondary Distribution Center
-- Approximately 60% of Phoenix levels, serves Central/Eastern US
-- Optimized for different regional preferences and shipping efficiency
(1, 'DAL-01', 510, 0, '2024-09-11 11:41:54'), -- 60% of PHX stock levels
(2, 'DAL-01', 390, 0, '2024-09-11 11:41:54'),
(3, 'DAL-01', 180, 0, '2024-09-11 11:41:54'),
(4, 'DAL-01', 720, 0, '2024-09-11 11:41:54'),
(5, 'DAL-01', 570, 0, '2024-09-11 11:41:54'),
(6, 'DAL-01', 270, 0, '2024-09-11 11:41:54'),
(7, 'DAL-01', 450, 0, '2024-09-11 11:41:54'),
(8, 'DAL-01', 1320, 0, '2024-09-11 11:41:54'),
(9, 'DAL-01', 1680, 0, '2024-09-11 11:41:54'),
(10, 'DAL-01', 2100, 0, '2024-09-11 11:41:54'),
(11, 'DAL-01', 228, 0, '2024-09-11 11:41:54'),
(12, 'DAL-01', 492, 0, '2024-09-11 11:41:54'),

-- Apparel at DAL-01 (regional preferences may vary)
(13, 'DAL-01', 1680, 0, '2024-09-11 11:41:54'),
(14, 'DAL-01', 1320, 0, '2024-09-11 11:41:54'),
(15, 'DAL-01', 990, 0, '2024-09-11 11:41:54'),
(16, 'DAL-01', 810, 0, '2024-09-11 11:41:54'),
(17, 'DAL-01', 1188, 0, '2024-09-11 11:41:54'),
(18, 'DAL-01', 660, 0, '2024-09-11 11:41:54'),
(19, 'DAL-01', 750, 0, '2024-09-11 11:41:54'),
(20, 'DAL-01', 1110, 0, '2024-09-11 11:41:54'),
(21, 'DAL-01', 588, 0, '2024-09-11 11:41:54'),
(22, 'DAL-01', 708, 0, '2024-09-11 11:41:54'),
(23, 'DAL-01', 912, 0, '2024-09-11 11:41:54'),
(24, 'DAL-01', 552, 0, '2024-09-11 11:41:54'),

-- Home goods at DAL-01
(25, 'DAL-01', 570, 0, '2024-09-11 11:41:54'),
(26, 'DAL-01', 948, 0, '2024-09-11 11:41:54'),
(27, 'DAL-01', 750, 0, '2024-09-11 11:41:54'),
(28, 'DAL-01', 1440, 0, '2024-09-11 11:41:54'),
(29, 'DAL-01', 492, 0, '2024-09-11 11:41:54'),
(30, 'DAL-01', 408, 0, '2024-09-11 11:41:54');

-- =============================================
-- 4. DATA GENERATION STORED PROCEDURE
-- Purpose: Create realistic transactional data with proper business logic
-- Generates 800+ orders over 8 months with seasonal patterns
-- Includes complete order-to-cash flow: orders → items → shipments → invoices → payments
-- =============================================

DELIMITER $

CREATE PROCEDURE GenerateRealisticTransactions()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_customer_id INT;
    DECLARE v_order_id INT;
    DECLARE v_product_id INT;
    DECLARE v_qty INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_order_date DATETIME;
    DECLARE v_ship_date DATETIME;
    DECLARE v_invoice_date DATETIME;
    DECLARE v_due_date DATE;
    DECLARE v_payment_date DATETIME;
    DECLARE v_order_value DECIMAL(12,2);
    DECLARE v_customer_segment VARCHAR(20);
    DECLARE v_payment_terms VARCHAR(10);
    DECLARE v_shipment_id INT;
    DECLARE v_invoice_id INT;
    DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE order_count INT DEFAULT 800; -- Target: 800 orders for robust analytics
    
    -- Clear existing transactional data (keep master data)
    TRUNCATE TABLE payments;
    TRUNCATE TABLE returns;
    TRUNCATE TABLE invoices;  
    TRUNCATE TABLE shipments;
    TRUNCATE TABLE order_items;
    TRUNCATE TABLE orders;
    
    -- =============================================
    -- GENERATE ORDERS WITH REALISTIC PATTERNS
    -- Distribution: 50% SMB, 35% Mid-market, 15% Enterprise (realistic business mix)
    -- Seasonal patterns: Higher volume in Q4, lower in Q1
    -- =============================================
    
    SET i = 1;
    WHILE i <= order_count DO
        
        -- Select customer based on realistic segment distribution
        -- SMB customers order more frequently but smaller amounts
        -- Enterprise customers order less frequently but larger amounts
        IF i <= (order_count * 0.50) THEN -- 50% of orders from SMB (400 orders)
            SET v_customer_id = 1 + FLOOR(RAND() * 45); -- SMB customers (IDs 1-45)
        ELSEIF i <= (order_count * 0.85) THEN -- 35% from Mid-market (280 orders)  
            SET v_customer_id = 46 + FLOOR(RAND() * 20); -- Mid customers (IDs 46-65)
        ELSE -- 15% from Enterprise (120 orders)
            SET v_customer_id = 66 + FLOOR(RAND() * 10); -- Enterprise customers (IDs 66-75)
        END IF;
        
        -- Get customer details for business logic
        SELECT segment, payment_terms INTO v_customer_segment, v_payment_terms 
        FROM customers WHERE customer_id = v_customer_id;
        
        -- Generate realistic order dates with seasonal patterns
        -- Higher volume in Oct-Dec (holiday season), lower in Jan-Feb
        SET v_order_date = CASE
            WHEN RAND() < 0.15 THEN DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 59) DAY) -- Jan-Feb: 15% of orders
            WHEN RAND() < 0.25 THEN DATE_ADD('2024-03-01', INTERVAL FLOOR(RAND() * 61) DAY) -- Mar-May: 25% 
            WHEN RAND() < 0.35 THEN DATE_ADD('2024-06-01', INTERVAL FLOOR(RAND() * 92) DAY) -- Jun-Aug: 35%
            ELSE DATE_ADD('2024-09-01', INTERVAL FLOOR(RAND() * 92) DAY) -- Sep-Nov: 35% (holiday season)
        END + INTERVAL FLOOR(RAND() * 24) HOUR + INTERVAL FLOOR(RAND() * 60) MINUTE;
        
        -- Insert order with realistic channel distribution
        -- SMB: More web/marketplace, Mid/Enterprise: More inside sales
        INSERT INTO orders (customer_id, order_ts, status, channel, requested_ship_date, promo_code) VALUES
        (v_customer_id, 
         v_order_date,
         'DELIVERED', -- Most orders completed for analytics (90%+ completion rate is realistic)
         CASE v_customer_segment
            WHEN 'SMB' THEN CASE 
                WHEN RAND() < 0.45 THEN 'Web' -- SMB prefers self-service
                WHEN RAND() < 0.75 THEN 'Marketplace' 
                ELSE 'InsideSales' 
            END
            WHEN 'Mid' THEN CASE
                WHEN RAND() < 0.25 THEN 'Web' 
                WHEN RAND() < 0.35 THEN 'Marketplace'
                ELSE 'InsideSales' -- Mid-market needs more consultation
            END
            ELSE 'InsideSales' -- Enterprise always uses inside sales
         END,
         DATE_ADD(DATE(v_order_date), INTERVAL 2 DAY), -- Standard 2-day lead time request
         CASE 
            WHEN RAND() < 0.15 AND v_customer_segment = 'SMB' THEN 'SAVE10' -- 15% use promos
            WHEN RAND() < 0.25 AND v_customer_segment = 'Mid' THEN 'BULK15' -- Bulk discount
            WHEN RAND() < 0.10 AND v_customer_segment = 'Enterprise' THEN 'ENTERPRISE20' -- Enterprise discount
            ELSE NULL -- Most orders have no promo code
         END
        );
        
        SET v_order_id = LAST_INSERT_ID();
        
        -- =============================================
        -- GENERATE ORDER ITEMS (1-8 items per order)
        -- SMB: 1-3 items typical, Mid: 2-5 items, Enterprise: 3-8 items
        -- Product selection based on customer segment preferences
        -- =============================================
        
        SET j = 1;
        SET v_order_value = 0;
        
        -- Determine number of line items based on customer segment
        SET @max_items = CASE v_customer_segment 
            WHEN 'SMB' THEN 1 + FLOOR(RAND() * 3) -- 1-3 items
            WHEN 'Mid' THEN 2 + FLOOR(RAND() * 4) -- 2-5 items  
            ELSE 3 + FLOOR(RAND() * 6) -- 3-8 items for Enterprise
        END;
        
        WHILE j <= @max_items DO
            
            -- Select products with realistic distribution by segment
            -- SMB: More apparel/accessories, Mid: Mixed, Enterprise: More electronics/bulk
            SET v_product_id = CASE v_customer_segment
                WHEN 'SMB' THEN CASE
                    WHEN RAND() < 0.20 THEN 1 + FLOOR(RAND() * 12) -- 20% electronics
                    WHEN RAND() < 0.70 THEN 13 + FLOOR(RAND() * 12) -- 50% apparel  
                    ELSE 25 + FLOOR(RAND() * 6) -- 30% home goods
                END
                WHEN 'Mid' THEN CASE
                    WHEN RAND() < 0.40 THEN 1 + FLOOR(RAND() * 12) -- 40% electronics
                    WHEN RAND() < 0.75 THEN 13 + FLOOR(RAND() * 12) -- 35% apparel
                    ELSE 25 + FLOOR(RAND() * 6) -- 25% home goods
                END  
                ELSE CASE -- Enterprise prefers higher-value electronics
                    WHEN RAND() < 0.60 THEN 1 + FLOOR(RAND() * 12) -- 60% electronics
                    WHEN RAND() < 0.80 THEN 13 + FLOOR(RAND() * 12) -- 20% apparel
                    ELSE 25 + FLOOR(RAND() * 6) -- 20% home goods
                END
            END;
            
            -- Get product price for calculations
            SELECT list_price INTO v_price FROM products WHERE product_id = v_product_id;
            
            -- Generate realistic quantities based on segment and product type
            -- Higher quantities for lower-priced items and larger customers
            SET v_qty = CASE v_customer_segment
                WHEN 'SMB' THEN CASE
                    WHEN v_price < 50 THEN 1 + FLOOR(RAND() * 10) -- 1-10 for cheap items
                    WHEN v_price < 200 THEN 1 + FLOOR(RAND() * 5) -- 1-5 for mid-range
                    ELSE 1 + FLOOR(RAND() * 2) -- 1-2 for expensive items
                END
                WHEN 'Mid' THEN CASE  
                    WHEN v_price < 50 THEN 5 + FLOOR(RAND() * 20) -- 5-25 for bulk buying
                    WHEN v_price < 200 THEN 2 + FLOOR(RAND() * 8) -- 2-10 for mid-range
                    ELSE 1 + FLOOR(RAND() * 3) -- 1-3 for expensive
                END
                ELSE CASE -- Enterprise orders in larger quantities
                    WHEN v_price < 50 THEN 10 + FLOOR(RAND() * 40) -- 10-50 bulk orders
                    WHEN v_price < 200 THEN 5 + FLOOR(RAND() * 15) -- 5-20 mid-range
                    ELSE 2 + FLOOR(RAND() * 5) -- 2-6 for expensive items
                END
            END;
            
            -- Calculate discounts based on quantity and customer segment
            -- Volume discounts: More quantity = higher discount
            -- Segment discounts: Enterprise > Mid > SMB
            SET @discount = CASE
                WHEN v_qty >= 20 AND v_customer_segment = 'Enterprise' THEN v_price * 0.15 -- 15% bulk discount
                WHEN v_qty >= 15 AND v_customer_segment = 'Mid' THEN v_price * 0.10 -- 10% volume discount
                WHEN v_qty >= 10 AND v_customer_segment = 'SMB' THEN v_price * 0.05 -- 5% small bulk discount
                WHEN v_customer_segment = 'Enterprise' THEN v_price * 0.08 -- 8% enterprise discount
                WHEN v_customer_segment = 'Mid' THEN v_price * 0.04 -- 4% mid-market discount
                ELSE 0 -- No discount for SMB standard orders
            END;
            
            -- Calculate tax (8.5% sales tax rate - typical US rate)
            SET @tax = (v_price * v_qty - @discount) * 0.085;
            
            -- Insert order item with realistic pricing
            INSERT IGNORE INTO order_items (order_id, product_id, qty, unit_price, discount, tax) VALUES
            (v_order_id, v_product_id, v_qty, v_price, @discount, @tax);
            
            -- Track order value for invoice generation
            SET v_order_value = v_order_value + (v_price * v_qty - @discount);
            
            SET j = j + 1;
        END WHILE;
        
        -- =============================================
        -- GENERATE SHIPMENT RECORDS
        -- Realistic lead times: 1-3 days for processing + shipping time
        -- On-time performance: 85% (industry average)
        -- =============================================
        
        -- Calculate realistic ship date (1-3 days processing time)
        SET v_ship_date = DATE_ADD(v_order_date, INTERVAL 1 + FLOOR(RAND() * 3) DAY);
        
        INSERT INTO shipments (order_id, ship_ts, promised_delivery_ts, actual_delivery_ts, status, ship_from_loc, carrier, tracking_number) VALUES
        (v_order_id, 
         v_ship_date,
         DATE_ADD(v_ship_date, INTERVAL 3 + FLOOR(RAND() * 2) DAY), -- 3-4 day shipping promise
         -- 85% on-time delivery rate (15% are late)
         CASE WHEN RAND() < 0.85 
              THEN DATE_ADD(v_ship_date, INTERVAL 2 + FLOOR(RAND() * 3) DAY) -- On time: 2-4 days
              ELSE DATE_ADD(v_ship_date, INTERVAL 4 + FLOOR(RAND() * 3) DAY) -- Late: 4-6 days
         END,
         'DELIVERED',
         CASE WHEN RAND() < 0.60 THEN 'PHX-01' ELSE 'DAL-01' END, -- 60% ship from Phoenix (primary)
         CASE WHEN RAND() < 0.55 THEN 'UPS' ELSE 'FedEx' END, -- Carrier split based on contracts
         CONCAT('TRK', LPAD(v_order_id, 8, '0')) -- Generate realistic tracking number
        );
        
        SET v_shipment_id = LAST_INSERT_ID();
        
        -- =============================================
        -- GENERATE INVOICE RECORDS  
        -- Invoice generated 1 day after shipment (standard business practice)
        -- Due date based on customer payment terms
        -- =============================================
        
        SET v_invoice_date = DATE_ADD(v_ship_date, INTERVAL 1 DAY);
        
        -- Calculate due date based on payment terms
        SET v_due_date = CASE v_payment_terms
            WHEN 'Prepaid' THEN DATE(v_order_date) -- Due immediately (already paid)
            WHEN 'Net15' THEN DATE_ADD(v_invoice_date, INTERVAL 15 DAY) -- 15 days from invoice
            WHEN 'Net30' THEN DATE_ADD(v_invoice_date, INTERVAL 30 DAY) -- 30 days from invoice  
            WHEN 'Net45' THEN DATE_ADD(v_invoice_date, INTERVAL 45 DAY) -- 45 days from invoice
            ELSE DATE_ADD(v_invoice_date, INTERVAL 30 DAY) -- Default to Net30
        END;
        
        -- Calculate realistic freight charges based on order value and distance
        -- Higher freight for lower value orders (percentage), flat rate for high value
        SET @freight = CASE 
            WHEN v_order_value < 100 THEN 15.00 + (RAND() * 10) -- $15-25 for small orders
            WHEN v_order_value < 500 THEN 25.00 + (RAND() * 15) -- $25-40 for medium orders  
            WHEN v_order_value < 2000 THEN 35.00 + (RAND() * 20) -- $35-55 for large orders
            ELSE 50.00 + (RAND() * 25) -- $50-75 for very large orders
        END;
        
        -- Get total tax from order items for invoice
        SELECT COALESCE(SUM(tax), 0) INTO @total_tax 
        FROM order_items WHERE order_id = v_order_id;
        
        INSERT INTO invoices (order_id, invoice_ts, due_date, subtotal, tax, freight, total) VALUES
        (v_order_id, v_invoice_date, v_due_date, v_order_value, @total_tax, @freight, 
         v_order_value + @total_tax + @freight);
        
        SET v_invoice_id = LAST_INSERT_ID();
        
        -- =============================================
        -- GENERATE PAYMENT RECORDS
        -- Payment behavior varies by customer segment and payment terms
        -- 90% of invoices get paid (10% remain outstanding for realistic AR aging)
        -- Payment timing varies: some early, some on-time, some late
        -- =============================================
        
        -- Only generate payments for 90% of invoices (realistic collection rate)
        IF RAND() < 0.90 THEN
            
            -- Calculate payment date with realistic behavior patterns
            -- Prepaid: Already paid (payment before invoice date)
            -- Net15/30/45: Mix of early, on-time, and late payments
            SET v_payment_date = CASE v_payment_terms
                WHEN 'Prepaid' THEN v_order_date -- Prepaid customers pay at order time
                ELSE CASE 
                    -- 25% pay early (5-10 days before due date)
                    WHEN RAND() < 0.25 THEN DATE_SUB(v_due_date, INTERVAL 5 + FLOOR(RAND() * 6) DAY)
                    -- 50% pay on time (within 5 days of due date) 
                    WHEN RAND() < 0.75 THEN DATE_ADD(v_due_date, INTERVAL -2 + FLOOR(RAND() * 5) DAY)
                    -- 25% pay late (5-20 days after due date)
                    ELSE DATE_ADD(v_due_date, INTERVAL 5 + FLOOR(RAND() * 16) DAY)
                END
            END + INTERVAL FLOOR(RAND() * 12) HOUR; -- Random time of day
            
            -- Payment method distribution varies by customer segment
            -- Enterprise: More ACH/Wire (lower fees for large amounts)
            -- SMB: More Card payments (convenience despite fees)
            -- Mid: Balanced mix
            SET @payment_method = CASE v_customer_segment
                WHEN 'Enterprise' THEN CASE
                    WHEN RAND() < 0.45 THEN 'ACH' -- Preferred for large amounts
                    WHEN RAND() < 0.75 THEN 'Wire' -- For urgent payments
                    WHEN RAND() < 0.90 THEN 'Check' -- Traditional method
                    ELSE 'Card' -- Minimal card usage for large amounts
                END
                WHEN 'Mid' THEN CASE
                    WHEN RAND() < 0.35 THEN 'ACH' -- Growing adoption
                    WHEN RAND() < 0.55 THEN 'Card' -- Popular for convenience
                    WHEN RAND() < 0.80 THEN 'Check' -- Still common
                    ELSE 'Wire' -- For urgent situations
                END
                ELSE CASE -- SMB prefers simple methods
                    WHEN RAND() < 0.45 THEN 'Card' -- Most convenient
                    WHEN RAND() < 0.70 THEN 'ACH' -- Lower cost option
                    WHEN RAND() < 0.90 THEN 'Check' -- Traditional
                    ELSE 'Wire' -- Rare for SMB
                END
            END;
            
            -- Calculate payment amount (95% pay in full, 5% make partial payments)
            SET @payment_amount = CASE 
                WHEN RAND() < 0.95 THEN v_order_value + @total_tax + @freight -- Full payment
                ELSE (v_order_value + @total_tax + @freight) * (0.3 + RAND() * 0.6) -- 30-90% partial payment
            END;
            
            INSERT INTO payments (invoice_id, payment_ts, method, amount, reference_number) VALUES
            (v_invoice_id, v_payment_date, @payment_method, @payment_amount, 
             CONCAT(@payment_method, DATE_FORMAT(v_payment_date, '%Y%m%d'), LPAD(v_invoice_id, 4, '0')));
        END IF;
        
        -- =============================================
        -- GENERATE RETURNS (5% of orders have returns)
        -- Return reasons: Damaged (30%), Wrong Item (25%), Customer Error (20%), 
        --                Defective (15%), Size Issues (10%)
        -- Return timing: 5-30 days after delivery
        -- =============================================
        
        IF RAND() < 0.05 THEN -- 5% return rate (industry average for retail)
            
            -- Select a random product from the order to return
            SELECT product_id, qty INTO @return_product_id, @original_qty 
            FROM order_items 
            WHERE order_id = v_order_id 
            ORDER BY RAND() 
            LIMIT 1;
            
            -- Return quantity: usually partial (20-80% of original quantity)
            SET @return_qty = GREATEST(1, FLOOR(@original_qty * (0.2 + RAND() * 0.6)));
            
            -- Return date: 5-30 days after delivery (realistic return window)
            SET @return_date = DATE_ADD(
                (SELECT actual_delivery_ts FROM shipments WHERE order_id = v_order_id),
                INTERVAL 5 + FLOOR(RAND() * 26) DAY
            );
            
            -- Reason codes with realistic distribution
            SET @reason_code = CASE 
                WHEN RAND() < 0.30 THEN 'Damaged' -- Most common: shipping damage
                WHEN RAND() < 0.55 THEN 'Wrong Item' -- Fulfillment error
                WHEN RAND() < 0.75 THEN 'Customer Error' -- Wrong size/color ordered
                WHEN RAND() < 0.90 THEN 'Defective' -- Manufacturing defect
                ELSE 'Size Issues' -- Fit problems (mainly apparel)
            END;
            
            -- Disposition based on reason code
            SET @disposition = CASE @reason_code
                WHEN 'Damaged' THEN 'Scrap' -- Damaged items usually scrapped
                WHEN 'Wrong Item' THEN 'Resell' -- Can be resold if not opened
                WHEN 'Customer Error' THEN 'Resell' -- Usually resellable
                WHEN 'Defective' THEN 'Refurbish' -- May be repairable
                WHEN 'Size Issues' THEN 'Resell' -- Different size needed
                ELSE 'Resell'
            END;
            
            -- Calculate refund amount (usually full refund for legitimate returns)
            SELECT unit_price INTO @unit_price 
            FROM order_items 
            WHERE order_id = v_order_id AND product_id = @return_product_id;
            
            SET @refund_amount = @return_qty * @unit_price;
            
            INSERT INTO returns (order_id, product_id, qty, reason_code, rma_ts, disposition, refund_amount, processed_by) VALUES
            (@return_product_id, @return_product_id, @return_qty, @reason_code, @return_date, 
             @disposition, @refund_amount, 'returns_system');
        END IF;
        
        SET i = i + 1;
        
        -- Progress indicator every 100 orders
        IF MOD(i, 100) = 0 THEN
            SELECT CONCAT('Generated ', i, ' orders of ', order_count, ' (', ROUND(i/order_count*100, 1), '% complete)') as progress;
        END IF;
        
    END WHILE;
    
    -- =============================================
    -- DATA GENERATION SUMMARY
    -- =============================================
    
    SELECT 'TRANSACTION DATA GENERATION COMPLETE!' as status;
    
    -- Display comprehensive summary statistics
    SELECT 
        'customers' as entity_type, 
        COUNT(*) as total_count,
        'Master data' as notes
    FROM customers
    UNION ALL
    SELECT 
        'products', 
        COUNT(*), 
        'Master data with 30 SKUs across 3 categories'
    FROM products
    UNION ALL  
    SELECT 
        'orders', 
        COUNT(*),
        CONCAT('Generated over 8-month period with seasonal patterns')
    FROM orders
    UNION ALL
    SELECT 
        'order_items', 
        COUNT(*),
        CONCAT('Average ', ROUND(COUNT(*)/(SELECT COUNT(*) FROM orders), 1), ' items per order')
    FROM order_items
    UNION ALL
    SELECT 
        'shipments', 
        COUNT(*),
        CONCAT(ROUND(COUNT(CASE WHEN actual_delivery_ts <= promised_delivery_ts THEN 1 END)/COUNT(*)*100, 1), '% on-time delivery rate')
    FROM shipments
    UNION ALL
    SELECT 
        'invoices', 
        COUNT(*),
        CONCAT(', FORMAT(SUM(total), 0), ' total invoiced')
    FROM invoices
    UNION ALL
    SELECT 
        'payments', 
        COUNT(*),
        CONCAT(', FORMAT(SUM(amount), 0), ' total collected (', ROUND(COUNT(*)/(SELECT COUNT(*) FROM invoices)*100, 1), '% payment rate)')
    FROM payments
    UNION ALL
    SELECT 
        'returns', 
        COUNT(*),
        CONCAT(ROUND(COUNT(*)/(SELECT COUNT(*) FROM orders)*100, 2), '% return rate')
    FROM returns
    UNION ALL
    SELECT
        'inventory_locations',
        COUNT(*),
        '2 warehouses (PHX-01, DAL-01)'
    FROM inventory;
    
    -- Business Intelligence Summary
    SELECT 'BUSINESS INTELLIGENCE READY!' as analytics_status;
    
    SELECT
        'Total Revenue Generated' as metric_name,
        CONCAT(', FORMAT(SUM(oi.qty * oi.unit_price - oi.discount), 0)) as metric_value
    FROM order_items oi
    UNION ALL
    SELECT
        'Average Order Value',
        CONCAT(', FORMAT(AVG(order_totals.order_value), 0))
    FROM (
        SELECT SUM(oi.qty * oi.unit_price - oi.discount) as order_value
        FROM order_items oi 
        GROUP BY oi.order_id
    ) order_totals
    UNION ALL
    SELECT
        'Outstanding A/R Balance',
        CONCAT(', FORMAT(SUM(i.total - COALESCE(p.amount, 0)), 0))
    FROM invoices i
    LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p 
        ON i.invoice_id = p.invoice_id
    WHERE i.total > COALESCE(p.amount, 0)
    UNION ALL
    SELECT
        'Days Sales Outstanding (DSO)',
        CONCAT(ROUND(
            (SELECT SUM(i.total - COALESCE(p.amount, 0)) 
             FROM invoices i
             LEFT JOIN (SELECT invoice_id, SUM(amount) as amount FROM payments GROUP BY invoice_id) p 
                 ON i.invoice_id = p.invoice_id
             WHERE i.total > COALESCE(p.amount, 0)) / -- Outstanding AR
            (SELECT SUM(oi.qty * oi.unit_price - oi.discount) / 30 -- Daily sales average
             FROM orders o
             JOIN order_items oi ON o.order_id = oi.order_id
             WHERE o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 30 DAY))
        , 1), ' days');

END$

DELIMITER ;

-- =============================================
-- EXECUTE DATA GENERATION
-- This creates the complete realistic dataset
-- Runtime: Approximately 30-60 seconds depending on system
-- =============================================

CALL GenerateRealisticTransactions();

-- Clean up the procedure (optional - remove if you want to run again)
DROP PROCEDURE IF EXISTS GenerateRealisticTransactions;

-- Re-enable foreign key checks to maintain data integrity
SET foreign_key_checks = 1;

-- =============================================
-- FINAL VERIFICATION AND OPTIMIZATION
-- =============================================

-- Update inventory reserved quantities based on pending orders
-- This makes inventory data more realistic by showing some reserved stock
UPDATE inventory i 
SET reserved_qty = (
    SELECT COALESCE(SUM(oi.qty), 0) * 0.1 -- Reserve 10% of recent sales
    FROM order_items oi 
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.product_id = i.product_id 
      AND o.order_ts >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) -- Last 7 days
      AND o.status IN ('NEW', 'ALLOCATED') -- Only pending orders
)
WHERE i.reserved_qty = 0;

-- Create indexes for better query performance (if not already existing)
-- These indexes optimize the most common analytical queries
CREATE INDEX IF NOT EXISTS idx_orders_date_segment ON orders(order_ts);
CREATE INDEX IF NOT EXISTS idx_order_items_product_date ON order_items(product_id);  
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_payments_date_method ON payments(payment_ts, method);
CREATE INDEX IF NOT EXISTS idx_shipments_performance ON shipments(actual_delivery_ts, promised_delivery_ts);

-- Final status message
SELECT 
    'LARGE DATASET GENERATION COMPLETE!' as final_status,
    'Ready for comprehensive business analytics' as next_steps,
    'Run sample queries from examples/dashboard_queries.sql' as recommendation;
