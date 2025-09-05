-- ============================================================================
-- E-Commerce Cart Abandonment Analysis - Data Preparation
-- ============================================================================
-- Author: Product Analytics Team
-- Date: September 2025
-- Purpose: Clean and prepare data for cart abandonment analysis

USE ecommerce_analysis;

-- ============================================================================
-- 1. CREATE ENHANCED VIEWS AND DERIVED TABLES
-- ============================================================================

-- Create comprehensive order analysis view
DROP VIEW IF EXISTS order_analysis_base;
CREATE VIEW order_analysis_base AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Time calculations
    TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_approved_at) as hours_to_approval,
    TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) as days_to_delivery,
    
    -- Date components for temporal analysis
    DATE(o.order_purchase_timestamp) as order_date,
    YEAR(o.order_purchase_timestamp) as order_year,
    MONTH(o.order_purchase_timestamp) as order_month,
    QUARTER(o.order_purchase_timestamp) as order_quarter,
    DAYOFWEEK(o.order_purchase_timestamp) as order_day_of_week,
    DAYNAME(o.order_purchase_timestamp) as order_day_name,
    HOUR(o.order_purchase_timestamp) as order_hour,
    
    -- Customer location
    c.customer_state,
    c.customer_city,
    c.customer_zip_code_prefix,
    
    -- Cart abandonment classification
    CASE 
        WHEN o.order_status IN ('canceled', 'unavailable') THEN 'abandoned'
        WHEN o.order_status IN ('delivered', 'shipped', 'invoiced', 'processing') THEN 'completed'
        WHEN o.order_status IN ('created', 'approved') THEN 'pending'
        ELSE 'other'
    END as cart_status,
    
    -- Binary flags for analysis
    CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 ELSE 0 END as is_abandoned,
    CASE WHEN o.order_status IN ('delivered', 'shipped', 'invoiced', 'processing') THEN 1 ELSE 0 END as is_completed,
    
    -- Weekend/weekday classification
    CASE WHEN DAYOFWEEK(o.order_purchase_timestamp) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END as day_type

FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

-- ============================================================================
-- 2. ORDER SUMMARY WITH CART METRICS
-- ============================================================================

-- Create order summary with cart size and value
DROP VIEW IF EXISTS order_summary;
CREATE VIEW order_summary AS
SELECT 
    oab.*,
    
    -- Cart metrics from order items
    COALESCE(oi_summary.total_items, 0) as cart_size,
    COALESCE(oi_summary.total_value, 0) as cart_value,
    COALESCE(oi_summary.avg_item_price, 0) as avg_item_price,
    COALESCE(oi_summary.total_freight, 0) as total_freight,
    COALESCE(oi_summary.unique_sellers, 0) as unique_sellers,
    
    -- Payment metrics
    COALESCE(payment_summary.total_payment_value, 0) as total_payment_value,
    COALESCE(payment_summary.payment_installments, 1) as payment_installments,
    payment_summary.primary_payment_type,
    
    -- Product categories (top category by value)
    product_summary.primary_category,
    product_summary.primary_category_english,
    COALESCE(product_summary.unique_categories, 0) as unique_categories

FROM order_analysis_base oab

-- Order items aggregation
LEFT JOIN (
    SELECT 
        oi.order_id,
        COUNT(*) as total_items,
        SUM(oi.price) as total_value,
        AVG(oi.price) as avg_item_price,
        SUM(oi.freight_value) as total_freight,
        COUNT(DISTINCT oi.seller_id) as unique_sellers
    FROM order_items oi
    GROUP BY oi.order_id
) oi_summary ON oab.order_id = oi_summary.order_id

-- Payment aggregation
LEFT JOIN (
    SELECT 
        op.order_id,
        SUM(op.payment_value) as total_payment_value,
        MAX(op.payment_installments) as payment_installments,
        (SELECT payment_type 
         FROM order_payments op2 
         WHERE op2.order_id = op.order_id 
         ORDER BY op2.payment_value DESC 
         LIMIT 1) as primary_payment_type
    FROM order_payments op
    GROUP BY op.order_id
) payment_summary ON oab.order_id = payment_summary.order_id

-- Product category aggregation
LEFT JOIN (
    SELECT 
        oi.order_id,
        (SELECT p.product_category_name
         FROM order_items oi2
         JOIN products p ON oi2.product_id = p.product_id
         WHERE oi2.order_id = oi.order_id
         GROUP BY p.product_category_name
         ORDER BY SUM(oi2.price) DESC
         LIMIT 1) as primary_category,
        (SELECT pct.product_category_name_english
         FROM order_items oi3
         JOIN products p ON oi3.product_id = p.product_id
         JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
         WHERE oi3.order_id = oi.order_id
         GROUP BY pct.product_category_name_english
         ORDER BY SUM(oi3.price) DESC
         LIMIT 1) as primary_category_english,
        COUNT(DISTINCT p.product_category_name) as unique_categories
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.order_id
) product_summary ON oab.order_id = product_summary.order_id;

-- ============================================================================
-- 3. CREATE ANALYSIS-READY FACT TABLE
-- ============================================================================

-- Create materialized fact table for faster queries
DROP TABLE IF EXISTS cart_abandonment_facts;
CREATE TABLE cart_abandonment_facts AS
SELECT * FROM order_summary;

-- Add indexes for performance
ALTER TABLE cart_abandonment_facts ADD PRIMARY KEY (order_id);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_cart_status (cart_status);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_abandoned (is_abandoned);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_completed (is_completed);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_order_date (order_date);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_customer_state (customer_state);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_payment_type (primary_payment_type);
ALTER TABLE cart_abandonment_facts ADD INDEX idx_category (primary_category_english);

-- ============================================================================
-- 4. DATA QUALITY AND VALIDATION
-- ============================================================================

-- Summary of cart statuses
SELECT 
    cart_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cart_abandonment_facts), 2) as percentage
FROM cart_abandonment_facts
GROUP BY cart_status
ORDER BY order_count DESC;

-- Cart value distribution by status
SELECT 
    cart_status,
    COUNT(*) as orders,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(cart_size), 1) as avg_cart_size,
    MIN(cart_value) as min_cart_value,
    MAX(cart_value) as max_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY cart_status;

-- Geographic distribution
SELECT 
    customer_state,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY customer_state
HAVING total_orders >= 100
ORDER BY abandonment_rate DESC
LIMIT 10;

-- Validate data completeness
SELECT 
    'Total Orders' as metric,
    COUNT(*) as value
FROM cart_abandonment_facts
UNION ALL
SELECT 
    'Orders with Cart Data',
    COUNT(*)
FROM cart_abandonment_facts
WHERE cart_size > 0
UNION ALL
SELECT 
    'Orders with Payment Data',
    COUNT(*)
FROM cart_abandonment_facts
WHERE total_payment_value > 0
UNION ALL
SELECT 
    'Orders with Category Data',
    COUNT(*)
FROM cart_abandonment_facts
WHERE primary_category_english IS NOT NULL;
