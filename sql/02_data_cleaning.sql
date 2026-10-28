-- ==============================================================================
-- PROJECT: Sales Performance & E-Commerce Analytics
-- FILE: 02_data_cleaning.sql
-- PURPOSE: Post-ingestion validation, data hygiene checks, duplicate audits,
--          date integrity, and data quality sanity checks.
-- AUTHOR: Junior Data Analyst Portfolio
-- ==============================================================================

USE ecommerce_sales_db;

-- ------------------------------------------------------------------------------
-- 1. VERIFY TOTAL INGESTED VOLUME
-- ------------------------------------------------------------------------------
-- Target: 9,994 rows for standard Superstore dataset.
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS total_distinct_orders,
    COUNT(DISTINCT customer_id) AS total_unique_customers,
    COUNT(DISTINCT product_id) AS total_unique_products
FROM superstore_orders;


-- ------------------------------------------------------------------------------
-- 2. NULL AND MISSING VALUE AUDIT
-- ------------------------------------------------------------------------------
-- Verifying that no critical operational fields contain NULLs.
SELECT 
    SUM(CASE WHEN row_id IS NULL THEN 1 ELSE 0 END) AS null_row_ids,
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_dates,
    SUM(CASE WHEN ship_date IS NULL THEN 1 ELSE 0 END) AS null_ship_dates,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN postal_code IS NULL OR postal_code = '' THEN 1 ELSE 0 END) AS null_postal_codes
FROM superstore_orders;


-- ------------------------------------------------------------------------------
-- 3. DUPLICATE AUDIT: ORDER LINES VS. DUPLICATE RECORDS
-- ------------------------------------------------------------------------------
-- IMPORTANT ANALYTIC DISTINCTION:
-- An e-commerce customer often orders multiple products in a single checkout session.
-- Therefore, multiple rows with the same `order_id` are LEGITIMATE LINE ITEMS.
-- A true duplicate would be identical order_id AND product_id, or duplicate row_id.

-- 3a. Check for Primary Key Collisions (Should return 0 rows)
SELECT 
    row_id, 
    COUNT(*) AS occurrences
FROM superstore_orders
GROUP BY row_id
HAVING COUNT(*) > 1;

-- 3b. Inspect legitimate multi-item orders (Cart Size distribution)
SELECT 
    items_in_order,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total_orders
FROM (
    SELECT order_id, COUNT(*) AS items_in_order
    FROM superstore_orders
    GROUP BY order_id
) order_sizes
GROUP BY items_in_order
ORDER BY items_in_order ASC;

-- 3c. Check for true duplicate lines (same order_id and same product_id)
SELECT 
    order_id, 
    product_id, 
    COUNT(*) AS duplicate_line_count
FROM superstore_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------------------------
-- 4. DATE AND CHRONOLOGY INTEGRITY AUDIT
-- ------------------------------------------------------------------------------
-- 4a. Check for illogical date sequences where shipping precedes order placement.
SELECT 
    order_id, 
    order_date, 
    ship_date, 
    DATEDIFF(ship_date, order_date) AS lead_time_days
FROM superstore_orders
WHERE ship_date < order_date;

-- 4b. Summary of shipping lead time metrics across ship modes
SELECT 
    ship_mode,
    COUNT(*) AS total_shipments,
    MIN(DATEDIFF(ship_date, order_date)) AS min_days,
    MAX(DATEDIFF(ship_date, order_date)) AS max_days,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS avg_lead_time_days
FROM superstore_orders
GROUP BY ship_mode
ORDER BY avg_lead_time_days ASC;

-- 4c. Time horizon coverage
SELECT 
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    TIMESTAMPDIFF(YEAR, MIN(order_date), MAX(order_date)) AS span_in_years
FROM superstore_orders;


-- ------------------------------------------------------------------------------
-- 5. NUMERICAL BOUNDS & DATA ANOMALY VALIDATION
-- ------------------------------------------------------------------------------
-- Check for impossible negative sales, negative quantity, or discounts outside [0, 1]
SELECT 
    COUNT(CASE WHEN sales <= 0 THEN 1 END) AS invalid_sales_count,
    COUNT(CASE WHEN quantity <= 0 THEN 1 END) AS invalid_quantity_count,
    COUNT(CASE WHEN discount < 0 OR discount > 1 THEN 1 END) AS invalid_discount_count
FROM superstore_orders;

-- Audit negative profit transactions (Loss-making orders are common in retail due to heavy discounting)
SELECT 
    COUNT(*) AS total_loss_transactions,
    ROUND(SUM(profit), 2) AS total_loss_amount,
    ROUND(AVG(discount) * 100, 2) AS avg_discount_on_losses_pct
FROM superstore_orders
WHERE profit < 0;
