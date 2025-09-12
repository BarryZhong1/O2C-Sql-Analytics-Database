# Order-to-Cash (O2C) Analytics Database Project

A comprehensive SQL database project modeling a complete Order-to-Cash business process with realistic data for business intelligence and analytics.

![O2C Process Flow](https://img.shields.io/badge/Process-Order%20to%20Cash-blue) ![Database](https://img.shields.io/badge/Database-MySQL%208.0-orange) ![Records](https://img.shields.io/badge/Dataset-500%2B%20Orders-green)

## 📋 Project Overview

This project provides a complete Order-to-Cash (O2C) database system that tracks the entire customer transaction lifecycle from order placement through cash collection. It includes realistic sample data and pre-built analytical views for business intelligence.

### Business Process Coverage
- **Customer Management**: Customer segmentation, credit limits, payment terms
- **Product Catalog**: Multi-category inventory with pricing and cost tracking
- **Order Management**: Multi-channel order processing with promotional codes
- **Inventory Control**: Real-time stock tracking across multiple locations
- **Fulfillment**: Shipment tracking with carrier and delivery performance
- **Billing**: Automated invoice generation with tax and freight calculations
- **Collections**: Payment processing with multiple payment methods
- **Returns**: Return merchandise authorization and disposition tracking

## 🗄️ Database Schema

### Core Tables (9 tables)
- `customers` - Customer master data with segmentation
- `products` - Product catalog with pricing and inventory parameters
- `orders` - Order header information with status tracking
- `order_items` - Order line items with pricing and discounts
- `inventory` - Real-time inventory levels by location
- `shipments` - Shipment tracking and delivery performance
- `invoices` - Billing information with tax and freight
- `payments` - Payment collection and cash application
- `returns` - Return processing and refund tracking

### Key Relationships
```
Customers → Orders → Order Items → Products
    ↓         ↓         ↓
  Orders → Shipments → Invoices → Payments
    ↓
  Returns
```

## 🚀 Quick Start

### Option 1: Complete Setup (Recommended)
```bash
# Clone the repository
git clone <your-repo-url>
cd o2c-analytics-project

# Run complete setup (creates everything)
mysql -u username -p < sql/complete_setup.sql
```

### Option 2: Step-by-Step Setup
```bash
# 1. Create database and tables
mysql -u username -p < sql/01-setup/create_database.sql
mysql -u username -p < sql/01-setup/create_tables.sql

# 2. Load sample data
mysql -u username -p o2c < sql/02-data/sample_data.sql

# 3. Create business views
mysql -u username -p o2c < sql/03-views/business_views.sql
```

### Option 3: Large Dataset Generation
```bash
# Generate 500+ orders with realistic data
mysql -u username -p o2c < sql/02-data/generate_large_dataset.sql
```

## 📊 Sample Data Overview

- **60 Customers** across 3 segments (SMB/Mid/Enterprise) and 4 regions
- **25 Products** across Electronics, Apparel, and Home categories  
- **500+ Orders** spanning 6 months with realistic seasonal patterns
- **1000+ Order Items** with varied quantities and pricing
- **Complete Transaction Flow** including shipments, invoices, and payments
- **Realistic Business Scenarios** (partial payments, returns, multichannel orders)

## 🔍 Key Business Views

### Customer Analytics
```sql
SELECT * FROM vw_customer_analytics 
ORDER BY total_revenue DESC;
```

### Product Performance
```sql
SELECT * FROM vw_product_performance 
WHERE gross_margin_pct > 40;
```

### Cash Flow Analysis
```sql
SELECT * FROM vw_cash_flow_analysis 
WHERE payment_status = 'UNPAID';
```

### Operational Performance
```sql
SELECT * FROM vw_operational_performance 
WHERE total_o2c_cycle_days > 45;
```

## 📈 Sample Analytics Queries

### Monthly Revenue Trends
```sql
SELECT 
    DATE_FORMAT(order_ts, '%Y-%m') as month,
    COUNT(*) as total_orders,
    SUM(net_amount) as revenue,
    AVG(net_amount) as avg_order_value
FROM vw_order_summary 
GROUP BY DATE_FORMAT(order_ts, '%Y-%m')
ORDER BY month;
```

### Customer Segment Performance  
```sql
SELECT 
    customer_segment,
    COUNT(*) as customers,
    SUM(total_revenue) as segment_revenue,
    AVG(total_revenue) as avg_customer_value
FROM vw_customer_analytics 
GROUP BY customer_segment;
```

### Top Performing Products
```sql
SELECT 
    category,
    sku,
    net_revenue,
    gross_margin_pct,
    turnover_ratio
FROM vw_product_performance 
ORDER BY net_revenue DESC
LIMIT 10;
```

## 🛠️ Project Structure

```
o2c-analytics-project/
├── sql/
│   ├── 01-setup/          # Database and table creation
│   ├── 02-data/           # Data loading and generation
│   ├── 03-views/          # Business intelligence views
│   ├── 04-reports/        # Sample analytical queries
│   └── complete_setup.sql # One-click complete setup
├── docs/                  # Detailed documentation
├── tests/                 # Data validation queries
├── examples/              # Sample dashboard queries
└── scripts/               # Automation scripts
```

## 💼 Use Cases

### Business Intelligence
- Customer profitability analysis
- Product performance tracking
- Regional sales analysis
- Channel effectiveness measurement

### Operations Management
- Order-to-cash cycle optimization
- Inventory turnover analysis
- Delivery performance monitoring
- Payment collection efficiency (DSO)

### Financial Analysis
- Revenue recognition tracking
- Accounts receivable aging
- Cash flow forecasting
- Return rate analysis

## 🧪 Testing & Validation

Run data validation tests:
```sql
-- Check data integrity
source tests/data_validation.sql

-- Verify business logic
SELECT * FROM vw_order_summary WHERE net_amount < 0;
```

## 🔗 Advanced Features

### Custom Time Periods
All views support date filtering for custom analysis periods.

### Drill-Down Capability  
Views are designed for hierarchical analysis (segment → customer → order → item).

### Performance Optimized
Includes proper indexing for fast query performance on large datasets.

## 📚 Documentation

- [Database Schema Details](docs/database-schema.md)
- [Business Requirements](docs/business-requirements.md)
- [API Documentation](docs/api-documentation.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your enhancements (new views, reports, or optimizations)
4. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🎯 Next Steps

After setup, try these sample queries from the `examples/` folder:
- Customer segmentation analysis
- Product profitability dashboard
- Operational KPI monitoring
- Cash flow management reports

---

**Ready to explore your O2C data?** Start with the Quick Start guide above!
