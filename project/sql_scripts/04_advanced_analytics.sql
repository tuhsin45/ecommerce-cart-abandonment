-- ============================================================================
-- E-Commerce Cart Abandonment Analysis - Advanced Analytics & Insights
-- ============================================================================
-- Author: Product Analytics Team
-- Date: September 2025
-- Purpose: Advanced SQL analytics for actionable business insights

USE ecommerce_analysis;

-- ============================================================================
-- 1. COHORT ANALYSIS - CUSTOMER BEHAVIOR PATTERNS
-- ============================================================================

-- Customer purchase behavior and abandonment patterns
WITH customer_metrics AS (
    SELECT 
        customer_id,
        COUNT(*) as total_orders,
        SUM(is_abandoned) as abandoned_orders,
        SUM(is_completed) as completed_orders,
        ROUND(AVG(cart_value), 2) as avg_cart_value,
        ROUND(AVG(cart_size), 1) as avg_cart_size,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        DATEDIFF(MAX(order_date), MIN(order_date)) as customer_lifespan_days
    FROM cart_abandonment_facts
    WHERE cart_status IN ('abandoned', 'completed')
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'One-time Customer'
        WHEN total_orders BETWEEN 2 AND 3 THEN 'Occasional Customer'
        WHEN total_orders BETWEEN 4 AND 10 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(abandoned_orders * 100.0 / total_orders), 2) as avg_abandonment_rate,
    ROUND(AVG(avg_cart_value), 2) as segment_avg_cart_value,
    ROUND(AVG(customer_lifespan_days), 1) as avg_customer_lifespan_days
FROM customer_metrics
GROUP BY customer_segment
ORDER BY 
    CASE 
        WHEN customer_segment = 'One-time Customer' THEN 1
        WHEN customer_segment = 'Occasional Customer' THEN 2
        WHEN customer_segment = 'Regular Customer' THEN 3
        ELSE 4
    END;

-- ============================================================================
-- 2. SEASONAL AND TEMPORAL PATTERNS
-- ============================================================================

-- Quarterly abandonment trends
SELECT 
    order_year,
    order_quarter,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(SUM(cart_value), 2) as total_cart_value,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as abandoned_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY order_year, order_quarter
ORDER BY order_year, order_quarter;

-- Weekend vs Weekday performance
SELECT 
    day_type,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(cart_size), 1) as avg_cart_size
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY day_type;

-- Peak hours analysis
WITH hourly_stats AS (
    SELECT 
        order_hour,
        COUNT(*) as total_orders,
        SUM(is_abandoned) as abandoned_orders,
        ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate
    FROM cart_abandonment_facts
    WHERE cart_status IN ('abandoned', 'completed')
    GROUP BY order_hour
)
SELECT 
    CASE 
        WHEN order_hour BETWEEN 6 AND 11 THEN 'Morning (6-11 AM)'
        WHEN order_hour BETWEEN 12 AND 17 THEN 'Afternoon (12-5 PM)'
        WHEN order_hour BETWEEN 18 AND 22 THEN 'Evening (6-10 PM)'
        ELSE 'Night/Early Morning (11 PM - 5 AM)'
    END as time_period,
    SUM(total_orders) as total_orders,
    SUM(abandoned_orders) as abandoned_orders,
    ROUND(SUM(abandoned_orders) * 100.0 / SUM(total_orders), 2) as abandonment_rate
FROM hourly_stats
GROUP BY time_period
ORDER BY abandonment_rate DESC;

-- ============================================================================
-- 3. HIGH-VALUE ABANDONMENT ANALYSIS
-- ============================================================================

-- High-value abandoned carts (top 10% by value)
WITH cart_percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY cart_value) as p90_cart_value
    FROM cart_abandonment_facts
    WHERE is_abandoned = 1 AND cart_value > 0
)
SELECT 
    'High-Value Abandoned Carts (Top 10%)' as segment,
    COUNT(*) as cart_count,
    ROUND(SUM(cart_value), 2) as total_abandoned_value,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(cart_size), 1) as avg_cart_size,
    COUNT(DISTINCT primary_category_english) as unique_categories
FROM cart_abandonment_facts, cart_percentiles
WHERE is_abandoned = 1 
AND cart_value >= cart_percentiles.p90_cart_value

UNION ALL

SELECT 
    'Regular Abandoned Carts (Bottom 90%)',
    COUNT(*),
    ROUND(SUM(cart_value), 2),
    ROUND(AVG(cart_value), 2),
    ROUND(AVG(cart_size), 1),
    COUNT(DISTINCT primary_category_english)
FROM cart_abandonment_facts, cart_percentiles
WHERE is_abandoned = 1 
AND cart_value < cart_percentiles.p90_cart_value;

-- Categories with highest value at risk
SELECT 
    primary_category_english,
    COUNT(CASE WHEN is_abandoned = 1 THEN 1 END) as abandoned_count,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as total_abandoned_value,
    ROUND(AVG(CASE WHEN is_abandoned = 1 THEN cart_value END), 2) as avg_abandoned_cart_value,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    -- Potential revenue recovery if abandonment reduced by 25%
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) * 0.25, 2) as potential_recovery_25pct
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND primary_category_english IS NOT NULL
GROUP BY primary_category_english
HAVING COUNT(*) >= 100
ORDER BY total_abandoned_value DESC
LIMIT 15;

-- ============================================================================
-- 4. PAYMENT AND CHECKOUT FRICTION ANALYSIS
-- ============================================================================

-- Payment type vs cart value correlation
SELECT 
    primary_payment_type,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value,
    ROUND(AVG(CASE WHEN is_abandoned = 1 THEN cart_value END), 2) as avg_abandoned_cart_value,
    ROUND(AVG(payment_installments), 1) as avg_installments
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND primary_payment_type IS NOT NULL
GROUP BY primary_payment_type
ORDER BY abandonment_rate DESC;

-- Complex checkout scenarios (high abandonment indicators)
SELECT 
    'Multiple Sellers in Cart' as friction_factor,
    COUNT(*) as affected_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(AVG(cart_value), 2) as avg_cart_value
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND unique_sellers > 1

UNION ALL

SELECT 
    'Multiple Categories in Cart',
    COUNT(*),
    SUM(is_abandoned),
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2),
    ROUND(AVG(cart_value), 2)
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND unique_categories > 1

UNION ALL

SELECT 
    'High Installment Payments (7+)',
    COUNT(*),
    SUM(is_abandoned),
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2),
    ROUND(AVG(cart_value), 2)
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND payment_installments >= 7

UNION ALL

SELECT 
    'Large Cart Size (6+ items)',
    COUNT(*),
    SUM(is_abandoned),
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2),
    ROUND(AVG(cart_value), 2)
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND cart_size >= 6;

-- ============================================================================
-- 5. GEOGRAPHIC INSIGHTS FOR TARGETED INTERVENTIONS
-- ============================================================================

-- States with highest abandoned cart value requiring attention
SELECT 
    customer_state,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as total_abandoned_value,
    ROUND(AVG(CASE WHEN is_abandoned = 1 THEN cart_value END), 2) as avg_abandoned_cart_value,
    -- Potential revenue if abandonment reduced to national average
    ROUND(
        SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) * 
        (1 - (SELECT SUM(is_abandoned) * 1.0 / COUNT(*) FROM cart_abandonment_facts WHERE cart_status IN ('abandoned', 'completed'))) / 
        (SUM(is_abandoned) * 1.0 / COUNT(*)), 
        2
    ) as potential_revenue_at_national_avg
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
GROUP BY customer_state
HAVING total_orders >= 200  -- Focus on significant markets
ORDER BY total_abandoned_value DESC
LIMIT 10;

-- ============================================================================
-- 6. RECOMMENDATIONS SCORING MODEL
-- ============================================================================

-- Create recommendation priority matrix
SELECT 
    primary_category_english as category,
    COUNT(*) as total_orders,
    SUM(is_abandoned) as abandoned_orders,
    ROUND(SUM(is_abandoned) * 100.0 / COUNT(*), 2) as abandonment_rate,
    ROUND(SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END), 2) as abandoned_value,
    
    -- Priority scoring (higher score = higher priority)
    ROUND(
        (SUM(is_abandoned) * 100.0 / COUNT(*)) * 0.4 +  -- 40% weight on abandonment rate
        (SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) / 1000) * 0.3 +  -- 30% weight on value at risk
        (COUNT(*) / 100) * 0.3,  -- 30% weight on volume
        2
    ) as priority_score,
    
    CASE 
        WHEN SUM(is_abandoned) * 100.0 / COUNT(*) > 25 AND SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) > 5000 THEN 'HIGH'
        WHEN SUM(is_abandoned) * 100.0 / COUNT(*) > 20 OR SUM(CASE WHEN is_abandoned = 1 THEN cart_value ELSE 0 END) > 3000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as intervention_priority
    
FROM cart_abandonment_facts
WHERE cart_status IN ('abandoned', 'completed')
AND primary_category_english IS NOT NULL
GROUP BY primary_category_english
HAVING total_orders >= 50
ORDER BY priority_score DESC;
