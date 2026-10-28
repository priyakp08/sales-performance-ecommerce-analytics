-- ==============================================================================
-- PROJECT: Sales Performance & E-Commerce Analytics
-- FILE: 03_business_queries.sql
-- PURPOSE: 10 Core Business Analysis Queries for Business Decision Support.
--          Demonstrates CTEs, Window Functions (LAG, DENSE_RANK), Aggregations,
--          Accurate Order-Level Calculations, and Business Insights.
-- AUTHOR: Junior Data Analyst Portfolio
-- ==============================================================================

USE ecommerce_sales_db;

-- ==============================================================================
-- QUERY 1: EXECUTIVE KPI SCORECARD
-- Business Intent: Provides executive leadership with an instant overview of
--                  top-line revenue, bottom-line profitability, and basket size.
-- Technical Note:  True Average Order Value (AOV) must divide Total Revenue by
--                  DISTINCT orders, NOT total rows.
-- ==============================================================================
SELECT 
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    SUM(quantity) AS total_units_sold,
    COUNT(DISTINCT order_id) AS total_distinct_orders,
    COUNT(row_id) AS total_order_lines,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS true_average_order_value,
    ROUND(CAST(COUNT(row_id) AS DECIMAL(10,2)) / COUNT(DISTINCT order_id), 2) AS avg_items_per_order
FROM superstore_orders;


-- ==============================================================================
-- QUERY 2: MONTHLY TRENDS & MONTH-OVER-MONTH (MoM) GROWTH
-- Business Intent: Tracks seasonality, identifying peak shopping months (Q4 holiday surge)
--                  and periods of margin contraction.
-- Technical Note:  Uses a CTE to aggregate by Year-Month, then applies the LAG()
--                  window function to calculate MoM percentage changes.
-- ==============================================================================
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS order_year_month,
        ROUND(SUM(sales), 2) AS monthly_revenue,
        ROUND(SUM(profit), 2) AS monthly_profit,
        COUNT(DISTINCT order_id) AS monthly_orders
    FROM superstore_orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    order_year_month,
    monthly_revenue,
    monthly_profit,
    ROUND((monthly_profit / monthly_revenue) * 100, 2) AS monthly_margin_pct,
    monthly_orders,
    LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month) AS prior_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month)) 
        / LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month)) * 100, 
        2
    ) AS mom_revenue_growth_pct
FROM monthly_sales
ORDER BY order_year_month ASC;


-- ==============================================================================
-- QUERY 3: YEAR-OVER-YEAR (YoY) TRAJECTORY
-- Business Intent: Measures long-term business expansion across annual periods.
-- Technical Note:  Extracts YEAR(order_date) and computes annual growth rates.
-- ==============================================================================
WITH annual_summary AS (
    SELECT 
        YEAR(order_date) AS order_year,
        ROUND(SUM(sales), 2) AS annual_revenue,
        ROUND(SUM(profit), 2) AS annual_profit,
        COUNT(DISTINCT order_id) AS annual_orders,
        ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS annual_aov
    FROM superstore_orders
    GROUP BY YEAR(order_date)
)
SELECT 
    order_year,
    annual_revenue,
    LAG(annual_revenue) OVER (ORDER BY order_year) AS prev_year_revenue,
    ROUND(
        ((annual_revenue - LAG(annual_revenue) OVER (ORDER BY order_year)) 
        / LAG(annual_revenue) OVER (ORDER BY order_year)) * 100, 
        2
    ) AS yoy_revenue_growth_pct,
    annual_profit,
    ROUND((annual_profit / annual_revenue) * 100, 2) AS profit_margin_pct,
    annual_orders,
    annual_aov
FROM annual_summary
ORDER BY order_year ASC;


-- ==============================================================================
-- QUERY 4: CATEGORY & SUB-CATEGORY PROFITABILITY MATRIX
-- Business Intent: Identifies which product lines generate healthy margins versus
--                  those that generate high sales volume but bleed profits.
-- Business Insight: Tables and Bookcases frequently suffer heavy losses due to
--                   high freight costs and aggressive promotional discounting.
-- ==============================================================================
SELECT 
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    SUM(quantity) AS units_sold,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct,
    CASE 
        WHEN SUM(profit) < 0 THEN 'Loss Maker (Critical Review)'
        WHEN (SUM(profit) / SUM(sales)) * 100 < 10 THEN 'Low Margin'
        ELSE 'Healthy Margin'
    END AS profitability_status
FROM superstore_orders
GROUP BY category, sub_category
ORDER BY total_profit ASC;


-- ==============================================================================
-- QUERY 5: DISCOUNT SENSITIVITY & MARGIN COLLAPSE THRESHOLD
-- Business Intent: Evaluates the exact discount bracket where transactions turn
--                  unprofitable. Critical for setting corporate discounting policy.
-- Key Takeaway: Discounts up to 20% remain profitable; discounts above 20%
--               lead to steep negative margins.
-- ==============================================================================
SELECT 
    CASE 
        WHEN discount = 0 THEN '0% (No Discount)'
        WHEN discount > 0 AND discount <= 0.10 THEN '0.01% - 10%'
        WHEN discount > 0.10 AND discount <= 0.20 THEN '10.01% - 20%'
        WHEN discount > 0.20 AND discount <= 0.40 THEN '20.01% - 40%'
        ELSE 'Over 40% (Deep Discount)'
    END AS discount_tier,
    COUNT(*) AS total_order_lines,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    COUNT(CASE WHEN profit < 0 THEN 1 END) AS loss_making_lines_count
FROM superstore_orders
GROUP BY discount_tier
ORDER BY MIN(discount) ASC;


-- ==============================================================================
-- QUERY 6: REGIONAL & STATE PERFORMANCE (PROFIT LEADERS VS PROFIT DRAINERS)
-- Business Intent: Reveals geographic profit disparity. While California and New
--                  York drive positive profit, Texas and Ohio produce heavy losses.
-- Technical Note:  Ranks states using DENSE_RANK() by total profit.
-- ==============================================================================
WITH state_performance AS (
    SELECT 
        region,
        state,
        ROUND(SUM(sales), 2) AS state_revenue,
        ROUND(SUM(profit), 2) AS state_profit,
        ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS state_margin_pct,
        ROUND(AVG(discount) * 100, 1) AS avg_discount_pct,
        COUNT(DISTINCT order_id) AS order_count
    FROM superstore_orders
    GROUP BY region, state
)
SELECT 
    region,
    state,
    state_revenue,
    state_profit,
    state_margin_pct,
    avg_discount_pct,
    order_count,
    DENSE_RANK() OVER (ORDER BY state_profit DESC) AS profit_rank_highest,
    DENSE_RANK() OVER (ORDER BY state_profit ASC) AS profit_rank_lowest
FROM state_performance
ORDER BY state_profit ASC;


-- ==============================================================================
-- QUERY 7: CUSTOMER SEGMENT PROFILE & TRUE ORDER METRICS
-- Business Intent: Compares B2B (Corporate/Home Office) vs B2C (Consumer)
--                  purchasing behavior, basket sizes, and profitability.
-- Technical Note:  Calculates Order-Level totals in an inner CTE first to ensure
--                  the Average Order Value is technically accurate.
-- ==============================================================================
WITH order_level_metrics AS (
    SELECT 
        order_id,
        segment,
        SUM(sales) AS order_revenue,
        SUM(profit) AS order_profit,
        SUM(quantity) AS order_units
    FROM superstore_orders
    GROUP BY order_id, segment
)
SELECT 
    segment,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_revenue), 2) AS total_revenue,
    ROUND(SUM(order_profit), 2) AS total_profit,
    ROUND((SUM(order_profit) / SUM(order_revenue)) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(order_revenue), 2) AS true_average_order_value,
    ROUND(AVG(order_units), 1) AS avg_units_per_order
FROM order_level_metrics
GROUP BY segment
ORDER BY total_revenue DESC;


-- ==============================================================================
-- QUERY 8: TOP 10 HIGH-VALUE CUSTOMERS (REVENUE VS PROFIT CONTRIBUTION)
-- Business Intent: Identifies whether the highest-spending customers are actually
--                  generating bottom-line value or receiving unprofitable discounts.
-- ==============================================================================
SELECT 
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales), 2) AS total_spend,
    ROUND(SUM(profit), 2) AS net_profit_generated,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS customer_margin_pct,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_received
FROM superstore_orders
GROUP BY customer_id, customer_name, segment
ORDER BY total_spend DESC
LIMIT 10;


-- ==============================================================================
-- QUERY 9: TOP 10 WORST PERFORMING PRODUCTS (PROFIT BLEEDERS)
-- Business Intent: SKU-level root cause analysis. Identifies the specific products
--                  causing the steepest cumulative financial losses.
-- Actionable Insight: Products with repeated negative margins should either have
--                     discount caps enforced or be discontinued from catalog.
-- ==============================================================================
SELECT 
    product_id,
    product_name,
    category,
    sub_category,
    COUNT(*) AS times_ordered,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_net_loss,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM superstore_orders
GROUP BY product_id, product_name, category, sub_category
HAVING SUM(profit) < 0
ORDER BY total_net_loss ASC
LIMIT 10;


-- ==============================================================================
-- QUERY 10: SHIPPING PERFORMANCE & LEAD TIME IMPACT
-- Business Intent: Analyzes operational logistics performance across ship modes
--                  and its correlation with order volume and profitability.
-- ==============================================================================
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) AS distinct_orders_fulfilled,
    ROUND(SUM(sales), 2) AS total_sales_shipped,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS avg_lead_time_days,
    MIN(DATEDIFF(ship_date, order_date)) AS fastest_ship_days,
    MAX(DATEDIFF(ship_date, order_date)) AS slowest_ship_days,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM superstore_orders
GROUP BY ship_mode
ORDER BY avg_lead_time_days ASC;
