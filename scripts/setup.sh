#!/bin/bash

# =============================================
# O2C Analytics Project Setup Script
# Automates the complete database setup process
# =============================================

echo "🚀 O2C Analytics Database Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if MySQL is available
print_step "Checking MySQL availability..."
if ! command -v mysql &> /dev/null; then
    print_error "MySQL client not found. Please install MySQL."
    exit 1
fi
print_success "MySQL client found"

# Get database connection details
echo ""
echo "Enter your MySQL connection details:"
read -p "Host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Port (default: 3306): " DB_PORT
DB_PORT=${DB_PORT:-3306}

read -p "Username (default: root): " DB_USER
DB_USER=${DB_USER:-root}

read -s -p "Password: " DB_PASS
echo ""

# Test connection
print_step "Testing MySQL connection..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "Failed to connect to MySQL. Please check your credentials."
    exit 1
fi
print_success "MySQL connection successful"

# Setup options
echo ""
echo "Choose setup option:"
echo "1) Complete setup (database + large dataset + views) [RECOMMENDED]"
echo "2) Basic setup (database + sample data)"
echo "3) Schema only (just tables, no data)"
echo "4) Large dataset only (assumes existing schema)"
read -p "Enter choice (1-4): " SETUP_CHOICE

case $SETUP_CHOICE in
    1)
        print_step "Running complete setup..."
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/complete_setup.sql
        if [ $? -eq 0 ]; then
            print_success "Complete setup finished successfully!"
        else
            print_error "Setup failed. Check the error messages above."
            exit 1
        fi
        ;;
    2)
        print_step "Running basic setup..."
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/01-setup/create_database.sql
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/01-setup/create_tables.sql
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/02-data/sample_data.sql
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/03-views/business_views.sql
        print_success "Basic setup completed!"
        ;;
    3)
        print_step "Creating schema only..."
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/01-setup/create_database.sql
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" < sql/01-setup/create_tables.sql
        print_success "Schema creation completed!"
        ;;
    4)
        print_step "Loading large dataset..."
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" o2c < sql/02-data/generate_large_dataset.sql
        print_success "Large dataset loaded!"
        ;;
    *)
        print_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

# Run validation tests
print_step "Running validation tests..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" o2c < tests/data_validation.sql > /dev/null
print_success "Validation completed"

# Display summary
echo ""
echo "======================================"
echo -e "${GREEN}🎉 SETUP COMPLETE!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Connect to your database: mysql -h$DB_HOST -u$DB_USER -p o2c"
echo "2. Try sample queries: source examples/dashboard_queries.sql"
echo "3. Explore business views: SELECT * FROM vw_order_summary LIMIT 10;"
echo ""
echo "📊 Available Views:"
echo "   - vw_order_summary"
echo "   - vw_customer_analytics"
echo "   - vw_product_performance"
echo "   - vw_cash_flow_analysis"
echo "   - vw_operational_performance"
echo ""
echo "📁 Documentation: Check the docs/ folder for detailed information"
echo "🔍 Sample queries: Look in examples/ folder for dashboard queries"
echo ""
print_success "Happy analyzing! 🚀"
