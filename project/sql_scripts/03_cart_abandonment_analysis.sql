-- ============================================================================
-- E-Commerce Cart Abandonment Analysis - Core Analytics Queries
-- ============================================================================
-- Author: Product Analytics Team
-- Date: September 2025
-- Purpose: SQL queries to answer key business questions about cart abandonment

USE ecommerce_analysis;

-- ============================================================================
-- 1. OVERALL CART ABANDONMENT RATE
-- ============================================================================

SELECT 
    'Overall Cart Abandonment Analysis' as analysis_type,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as abandonment_rate_pct,
    ROUND(SUM(is_completed) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as completion_rate_pct
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed');

-- Monthly abandonment trend
SELECT 
    order_year,
    order_month,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as abandonment_rate
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- ============================================================================
-- 2. ABANDONMENT BY PRODUCT CATEGORY
-- ============================================================================

SELECT 
    COALESCE(primary_category_english, 'Unknown') as product_category,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(cart_size), 1) as avg_cart_size
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY primary_category_english
HAVING total_orders >= 50  -- Filter for statistical significance
ORDER BY abandonment_rate DESC, total_orders DESC;

-- Top categories by abandoned cart value
SELECT 
    COALESCE(primary_category_english, 'Unknown') as product_category,
    SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) as total_abandoned_value,
    COUNT(CASE WHEN is_abandoned = 1 THEN 1 END) as abandoned_count,
    ROUND(AVG(CASE WHEN is_abandoned = 1 THEN cart_value END), 2) as avg_abandoned_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY primary_category_english
HAVING abandoned_count >= 10
ORDER BY total_abandoned_value DESC
LIMIT 15;

-- ============================================================================
-- 3. ABANDONMENT BY PAYMENT TYPE
-- ============================================================================

SELECT 
    COALESCE(primary_payment_type, 'Unknown') as payment_type,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(payment_installments), 1) as avg_installments
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY primary_payment_type
ORDER BY abandonment_rate DESC;

-- Payment installments impact on abandonment
SELECT 
    CASE 
        WHEN payment_installments = 1 THEN '1 (No Installment)'
        WHEN payment_installments BETWEEN 2 AND 3 THEN '2-3 Installments'
        WHEN payment_installments BETWEEN 4 AND 6 THEN '4-6 Installments'
        WHEN payment_installments BETWEEN 7 AND 12 THEN '7-12 Installments'
        ELSE '13+ Installments'
    END as installment_group,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed') 
AND primary_payment_type IS NOT NULL
GROUP BY installment_group
ORDER BY abandonment_rate DESC;

-- ============================================================================
-- 4. CART SIZE AND VALUE ANALYSIS
-- ============================================================================

-- Cart size distribution
SELECT 
    CASE 
        WHEN cart_size = 1 THEN '1 item'
        WHEN cart_size BETWEEN 2 AND 3 THEN '2-3 items'
        WHEN cart_size BETWEEN 4 AND 5 THEN '4-5 items'
        WHEN cart_size BETWEEN 6 AND 10 THEN '6-10 items'
        ELSE '11+ items'
    END as cart_size_group,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed') AND cart_size > 0
GROUP BY cart_size_group
ORDER BY 
    CASE 
        WHEN cart_size_group = '1 item' THEN 1
        WHEN cart_size_group = '2-3 items' THEN 2
        WHEN cart_size_group = '4-5 items' THEN 3
        WHEN cart_size_group = '6-10 items' THEN 4
        ELSE 5
    END;

-- Cart value distribution
SELECT 
    CASE 
        WHEN cart_value <= 50 THEN '≤ $50'
        WHEN cart_value <= 100 THEN '$51-100'
        WHEN cart_value <= 200 THEN '$101-200'
        WHEN cart_value <= 500 THEN '$201-500'
        WHEN cart_value <= 1000 THEN '$501-1000'
        ELSE '> $1000'
    END as cart_value_group,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_size), 1) as avg_cart_size
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed') AND cart_value > 0
GROUP BY cart_value_group
ORDER BY 
    CASE 
        WHEN cart_value_group = '≤ $50' THEN 1
        WHEN cart_value_group = '$51-100' THEN 2
        WHEN cart_value_group = '$101-200' THEN 3
        WHEN cart_value_group = '$201-500' THEN 4
        WHEN cart_value_group = '$501-1000' THEN 5
        ELSE 6
    END;

-- Comparison of abandoned vs completed carts
SELECT 
    cart_status,
    COUNT(*) as order_count,
    ROUND(AVG(cart_size), 2) as avg_cart_size,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(avg_item_price), 2) as avg_item_price,
    ROUND(AVG(unique_sellers), 2) as avg_unique_sellers,
    ROUND(AVG(unique_categories), 2) as avg_unique_categories
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY cart_status;

-- ============================================================================
-- 5. TIME TO PURCHASE ANALYSIS
-- ============================================================================

-- Time to approval analysis
SELECT 
    CASE 
        WHEN hours_to_approval IS NULL THEN 'No Approval'
        WHEN hours_to_approval <= 1 THEN '≤ 1 hour'
        WHEN hours_to_approval <= 6 THEN '1-6 hours'
        WHEN hours_to_approval <= 24 THEN '6-24 hours'
        WHEN hours_to_approval <= 72 THEN '1-3 days'
        ELSE '> 3 days'
    END as approval_time_group,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY approval_time_group
ORDER BY abandonment_rate DESC;

-- Purchase patterns by hour of day
SELECT 
    order_hour,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY order_hour
ORDER BY order_hour;

-- Purchase patterns by day of week
SELECT 
    order_day_name,
    day_type,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY order_day_name, day_type, order_day_of_week
ORDER BY order_day_of_week;

-- ============================================================================
-- 6. GEOGRAPHIC ANALYSIS
-- ============================================================================

-- State-wise abandonment analysis
SELECT 
    customer_state,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    SUM(is_completed) as completed_orders,
    ROUND(SUM(is_abandoned) * 100.0 / (SUM(is_abandoned) + SUM(is_completed)), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as total_abandoned_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY customer_state
HAVING total_orders >= 100  -- Filter for statistical significance
ORDER BY abandonment_rate DESC;

-- Top cities by abandoned cart value
SELECT 
    customer_city,
    customer_state,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as total_abandoned_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY customer_city, customer_state
HAVING total_orders >= 50
ORDER BY total_abandoned_value DESC
LIMIT 20;

-- ============================================================================
-- 7. FUNNEL ANALYSIS
-- ============================================================================

-- E-commerce funnel stages
SELECT 
    'Step 1: Cart Created' as funnel_stage,
    COUNT(*) as order_count,
    100.0 as conversion_rate
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed', 'pending')

UNION ALL

SELECT 
    'Step 2: Payment Attempted',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cart_abandonment_facts WHERE cart_status IN ('abandoned', 'completed', 'pending')), 2)
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed', 'pending') AND total_payment_value > 0

UNION ALL

SELECT 
    'Step 3: Order Approved',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cart_abandonment_facts WHERE cart_status IN ('abandoned', 'completed', 'pending')), 2)
FROM cart_abandonment_facts
WHERE cart_status IN ('completed', 'pending') AND order_approved_at IS NOT NULL

UNION ALL

SELECT 
    'Step 4: Order Completed',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cart_abandonment_facts WHERE cart_status IN ('abandoned', 'completed', 'pending')), 2)
FROM cart_abandonment_facts
WHERE cart_status = 'completed'

ORDER BY 
    CASE 
        WHEN funnel_stage = 'Step 1: Cart Created' THEN 1
        WHEN funnel_stage = 'Step 2: Payment Attempted' THEN 2
        WHEN funnel_stage = 'Step 3: Order Approved' THEN 3
        WHEN funnel_stage = 'Step 4: Order Completed' THEN 4
    END;
