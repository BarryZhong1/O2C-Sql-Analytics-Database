## Database Overview
The O2C database represents a complete order-to-cash business process with 9 interconnected tables covering the full customer lifecycle from order placement to payment collection.

## Table Structure Analysis

### Core Business Entities

#### 1. **customers** (Master Data)
- **Purpose**: Customer master data with segmentation and credit terms
- **Key Fields**: customer_id (PK), name, segment (SMB/Mid/Enterprise), region, payment_terms, credit_limit
- **Business Logic**: Credit limits vary by segment (SMB: $50K, Mid: $250K, Enterprise: $1M)

#### 2. **products** (Master Data)
- **Purpose**: Product catalog with pricing and inventory parameters
- **Key Fields**: product_id (PK), sku, category, unit_cost, list_price, safety_stock
- **Categories**: Apparel, Electronics, Home
- **Pricing Strategy**: List prices are typically 2x unit cost (100% markup)

#### 3. **inventory** (Operational Data)
- **Purpose**: Real-time inventory tracking by product and location
- **Key Fields**: product_id + loc_code (Composite PK), on_hand_qty, reserved_qty
- **Current Location**: PHX-01 (Phoenix warehouse)

### Transaction Flow Tables

#### 4. **orders** (Transaction Header)
- **Purpose**: Customer order header information
- **Key Fields**: order_id (PK), customer_id (FK), order_ts, status, channel
- **Statuses**: NEW → ALLOCATED → SHIPPED → DELIVERED → CANCELLED
- **Channels**: Web, Marketplace, InsideSales

#### 5. **order_items** (Transaction Detail)
- **Purpose**: Line-level order details with pricing and discounts
- **Key Fields**: order_id + product_id (Composite PK), qty, unit_price, discount, tax
- **Business Logic**: Supports item-level discounts and tax calculations

#### 6. **shipments** (Fulfillment)
- **Purpose**: Shipment tracking and delivery management
- **Key Fields**: shipment_id (PK), order_id (FK), ship_ts, promised/actual_delivery_ts
- **Carriers**: UPS, FedEx
- **Performance Tracking**: Promised vs actual delivery times

#### 7. **invoices** (Billing)
- **Purpose**: Invoice generation based on shipped orders
- **Key Fields**: invoice_id (PK), order_id (FK), subtotal, tax, freight, total
- **Timing**: Generated after shipment
- **Components**: Subtotal + Tax + Freight = Total

#### 8. **payments** (Collection)
- **Purpose**: Payment processing and cash collection
- **Key Fields**: payment_id (PK), invoice_id (FK), payment_ts, method, amount
- **Methods**: ACH, Wire, Card, Check
- **Status**: Partial payments supported (invoice 1 shows $1,500 paid vs $2,704.50 total)

#### 9. **returns** (Reverse Logistics)
- **Purpose**: Return merchandise authorization and processing
- **Key Fields**: return_id (PK), order_id + product_id (FK), qty, reason_code, disposition
- **Dispositions**: Resell, Refurbish, Scrap
- **Financial Impact**: Tracks refund amounts

## Data Quality Observations

### Positive Aspects
- **Referential Integrity**: All foreign key relationships properly defined
- **Data Types**: Appropriate use of DECIMAL for monetary values, ENUM for controlled vocabularies
- **Indexing**: Key indexes on foreign keys and commonly queried fields
- **Timestamps**: Proper tracking of transaction timing

### Potential Issues
- **Missing Data**: Some shipments have NULL actual_delivery_ts (order 4 still in transit)
- **Partial Payments**: Invoice 1 shows underpayment ($1,500 vs $2,704.50 due)
- **Data Consistency**: Tax calculations in order_items vs invoices may not align perfectly

## Business Process Flow
```
Customer → Order → Order Items → Inventory Check → Shipment → Invoice → Payment
    ↓                                                                      ↑
  Returns ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

## Key Business Metrics Supported
- Order-to-cash cycle time
- Customer profitability analysis
- Inventory turnover and availability
- Payment collection efficiency (DSO)
- Return rate analysis
- Channel performance
- Regional sales analysis
- Product category profitability

## Sample Data Insights
- **Customer Distribution**: 1 SMB, 1 Mid-market, 1 Enterprise
- **Order Volume**: 4 orders total, $13,150 in subtotal revenue
- **Product Mix**: 5 SKUs across 3 categories
- **Geographic**: All shipments from PHX-01 warehouse
- **Payment Efficiency**: Mixed performance (1 underpayment, 1 on-time, 1 early payment)

## Next Steps for Project Development
1. Create comprehensive reporting views
2. Build analytical queries for KPI calculation  
3. Develop data validation and quality checks
4. Implement business intelligence dashboards
5. Add operational monitoring queries
