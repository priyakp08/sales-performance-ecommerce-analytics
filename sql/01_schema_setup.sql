-- ==============================================================================
-- PROJECT: Sales Performance & E-Commerce Analytics
-- FILE: 01_schema_setup.sql
-- PURPOSE: Database initialization, Table DDL with optimized types and indexes,
--          and data ingestion scripts.
-- AUTHOR: Junior Data Analyst Portfolio
-- ==============================================================================

-- 1. Create Database
CREATE DATABASE IF NOT EXISTS ecommerce_sales_db;
USE ecommerce_sales_db;

-- 2. Drop existing table if recreating
DROP TABLE IF EXISTS superstore_orders;

-- 3. Create Main Orders Table
-- Granularity: Order Line Item (One row per product purchased in an order)
CREATE TABLE superstore_orders (
    row_id INT NOT NULL,
    order_id VARCHAR(25) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(25) NOT NULL,
    customer_id VARCHAR(25) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(25) NOT NULL,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(15) NULL,
    region VARCHAR(25) NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    category VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    sales DECIMAL(10, 4) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(5, 2) NOT NULL,
    profit DECIMAL(10, 4) NOT NULL,
    CONSTRAINT pk_superstore_orders PRIMARY KEY (row_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Create Performance Indexes
-- Essential for speeding up analytical queries (aggregations, filters, time-series, and joins)
CREATE INDEX idx_orders_order_id ON superstore_orders (order_id);
CREATE INDEX idx_orders_order_date ON superstore_orders (order_date);
CREATE INDEX idx_orders_customer_id ON superstore_orders (customer_id);
CREATE INDEX idx_orders_category_subcategory ON superstore_orders (category, sub_category);
CREATE INDEX idx_orders_region_state ON superstore_orders (region, state);

-- 5. Optional Supplementary Tables (Returns & Regional Managers)
DROP TABLE IF EXISTS superstore_returns;
CREATE TABLE superstore_returns (
    returned VARCHAR(10) NOT NULL,
    order_id VARCHAR(25) NOT NULL,
    CONSTRAINT pk_superstore_returns PRIMARY KEY (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS superstore_managers;
CREATE TABLE superstore_managers (
    person VARCHAR(100) NOT NULL,
    region VARCHAR(25) NOT NULL,
    CONSTRAINT pk_superstore_managers PRIMARY KEY (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==============================================================================
-- DATA INGESTION INSTRUCTIONS
-- ==============================================================================
/*
METHOD A: MySQL Workbench Table Data Import Wizard (Simplest GUI Method)
------------------------------------------------------------------------
1. Open MySQL Workbench and connect to your local MySQL instance.
2. In the 'Navigator' pane (left side), double click `ecommerce_sales_db` to select it.
3. Right-click the `superstore_orders` table and select "Table Data Import Wizard".
4. Browse to: <project_folder>/data/processed/cleaned_superstore.csv
5. Select "Use existing table: superstore_orders".
6. Verify the column mapping (all headers match exactly: row_id, order_id, order_date, etc.).
7. Click "Next" to execute import. Total expected rows imported: 9,994.

METHOD B: Fast Command-Line LOAD DATA INFILE (High-Performance Method)
------------------------------------------------------------------------
If local_infile is enabled on your server:

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/priya/.gemini/antigravity/scratch/sales-performance-ecommerce-analytics/data/processed/cleaned_superstore.csv'
INTO TABLE superstore_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name,
 segment, country, city, state, postal_code, region, product_id, category, 
 sub_category, product_name, sales, quantity, discount, profit);

METHOD C: Python Automated Pipeline
------------------------------------
Run:
python scripts/load_to_mysql.py
*/
