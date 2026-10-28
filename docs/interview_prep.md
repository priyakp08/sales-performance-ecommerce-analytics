# Data Analyst Interview Preparation Guide

This guide prepares you to confidently articulate the technical architecture, SQL queries, DAX formulas, and business recommendations from this project during technical screenings and hiring manager interviews.

---

### Question 1: How did you calculate Average Order Value (AOV), and why is it frequently miscalculated in retail datasets?
**Answer:**
> "In transactional retail datasets like Superstore, each row represents an individual line item (a product SKU) rather than an entire checkout basket. A customer frequently purchases multiple items in a single order—in our dataset, the average basket size is 2.0 items per order.
> 
> A common mistake junior analysts make is writing `AVG(sales)`, which calculates the **Average Line Item Value** ($229.86), drastically understating customer checkout size.
> 
> To calculate **True Average Order Value**, I used two approaches:
> 1. In **SQL**: I divided total revenue by distinct orders: `SUM(sales) / COUNT(DISTINCT order_id)`, yielding **$458.61**. Alternatively, I used a CTE to aggregate total revenue per `order_id` first and then computed `AVG(order_revenue)`.
> 2. In **Power BI DAX**: I created explicit measures `[Total Sales]` and `[Total Orders] = DISTINCTCOUNT(superstore_orders[order_id])`, then defined `[Average Order Value] = DIVIDE([Total Sales], [Total Orders], 0)`."

---

### Question 2: What was the most significant commercial insight you discovered from your discount analysis?
**Answer:**
> "By segmenting discounts into five distinct brackets (`0%`, `1-10%`, `11-20%`, `21-40%`, and `>40%`), I identified an immediate **profit cliff at the 20% discount mark**:
> - Orders sold at **0% discount** generated a healthy **+29.5% profit margin** ($321K profit).
> - Orders with **11% to 20% discount** remained profitable at **+11.6% margin** ($91.8K profit).
> - However, the moment discounts exceeded 20%, margins turned sharply negative: discounts between **21% and 40%** produced a **-15.3% margin** (-$35.8K loss), and discounts **above 40%** suffered an catastrophic **-77.4% margin** (-$99.6K loss).
> 
> In total, 18.7% of all transaction lines were unprofitable, resulting in **$156,131 in cumulative losses**. Over 84% of these losses were directly attributable to discounts exceeding 20%."

---

### Question 3: Can you explain your SQL logic for calculating Month-over-Month (MoM) growth?
**Answer:**
> "To calculate Month-over-Month revenue growth without creating messy self-joins, I used a **Common Table Expression (CTE)** combined with the `LAG()` window function:
> 
> ```sql
> WITH monthly_sales AS (
>     SELECT 
>         DATE_FORMAT(order_date, '%Y-%m') AS order_year_month,
>         ROUND(SUM(sales), 2) AS monthly_revenue
>     FROM superstore_orders
>     GROUP BY DATE_FORMAT(order_date, '%Y-%m')
> )
> SELECT 
>     order_year_month,
>     monthly_revenue,
>     LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month) AS prior_month_revenue,
>     ROUND(
>         ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month)) 
>         / LAG(monthly_revenue, 1) OVER (ORDER BY order_year_month)) * 100, 2
>     ) AS mom_growth_pct
> FROM monthly_sales;
> ```
> 
> The `LAG()` function inspects the immediately preceding row along the sorted time dimension, making the calculation concise, readable, and computationally efficient on MySQL 8.0."

---

### Question 4: How did you distinguish between duplicate records and legitimate multi-item orders?
**Answer:**
> "When auditing the data, I recognized that multiple rows containing the same `order_id` are **legitimate multi-line transactions**. If a customer orders an office chair and a pack of printer paper in the same purchase, both lines share the same `order_id` and timestamp, but possess different `product_id` and `row_id` values.
> 
> A **true duplicate** is defined as an identical composite key (`order_id` + `product_id`) or duplicate `row_id`. In SQL, I verified this using:
> ```sql
> SELECT order_id, product_id, COUNT(*)
> FROM superstore_orders
> GROUP BY order_id, product_id
> HAVING COUNT(*) > 1;
> ```
> Deleting rows purely based on duplicate `order_id` would have destroyed over 4,985 legitimate line items and distorted all sales figures."

---

### Question 5: Why did you build a Star Schema and a dedicated Date Dimension in Power BI instead of using a single flat table?
**Answer:**
> "While Power BI can technically load a flat CSV, enterprise modeling standards require a **Star Schema** for three reasons:
> 1. **Time Intelligence Integrity**: Built-in DAX time functions (`SAMEPERIODLASTYEAR`, `DATESYTD`) require a contiguous, uninterrupted calendar table marked as a 'Date Table'. Using raw transaction dates causes errors if there are days with zero sales (e.g. holidays).
> 2. **VertiPaq Engine Optimization**: Storing repeated customer names or product descriptions in a single fact table inflates memory. Separating them into dimension tables maximizes columnar compression and query speed.
> 3. **Clean Dimensional Filtering**: A central fact table surrounded by dimension tables enables standard 1-to-many single-direction filtering, preventing ambiguous relationship paths and circular dependencies."

---

### Question 6: What data quality anomalies did you discover during the initial Python / SQL inspection?
**Answer:**
> "I uncovered two key real-world data quality issues:
> 1. **Concatenated Metadata Sheets**: In the raw repository dump, three distinct Excel tabs (`Orders`, `People`, `Returns`) were vertically merged into a single CSV. The bottom 806 rows had NULL dates because they represented regional managers and returns logs. I engineered an automated Python parser to cleanly separate the 9,994 transaction rows from the metadata tables.
> 2. **Missing Postal Codes**: Exactly 11 rows had missing postal codes, all located in Burlington, Vermont. Instead of dropping these transactions and losing revenue data, I researched the official Burlington zip code (`05408`) and imputed it as a string to preserve the leading zero."

---

### Question 7: Why do high-revenue states like Texas and Ohio show net negative profits?
**Answer:**
> "During geographic analysis, I ranked states using `DENSE_RANK() OVER (ORDER BY SUM(profit) ASC)`. Despite Texas generating $170.2K in revenue (ranking 3rd in sales volume), it suffered the highest net loss of **-$25,729** (-15.1% margin). Similarly, Ohio lost -$16,971 (-21.7% margin) and Pennsylvania lost -$15,560 (-13.4% margin).
> 
> When cross-referencing average discounts, Texas had an average discount rate of **37.0%**, and Ohio had **32.5%**, compared to profitable states like California (7.3% discount, +$76.4K profit) and New York (5.5% discount, +$74.0K profit). Regional sales teams in Texas were utilizing excessive discounting to inflate sales volume at the expense of profitability."

---

### Question 8: Which product sub-categories are bleeding money, and what would you recommend to management?
**Answer:**
> "The Furniture category, specifically **Tables** (-$17,725 loss; -8.56% margin) and **Bookcases** (-$3,473 loss; -3.02% margin), are the primary profit bleeders.
> 
> My strategic recommendations would be:
> 1. **Hard Discount Caps**: Implement an ERP rule restricting sales reps from offering discounts greater than 15% on Tables and Bookcases.
> 2. **Freight / Shipping Surcharges**: Furniture items are heavy and incur high shipping costs. Transition bulky items from free shipping to weight-based freight surcharges.
> 3. **SKU Rationalization**: Phase out the bottom 5 individual SKUs (such as the *Chromcraft Round Conference Table* and *Bush Advantage Collection Desk*) that generated repeated four-figure losses."

---

### Question 9: Why did you choose Import Mode over DirectQuery in Power BI?
**Answer:**
> "For a retail dataset of 10,000 to 1,000,000 rows, **Import Mode** is the optimal choice. It loads the dataset into Power BI's in-memory columnar database (VertiPaq), which provides sub-second visual rendering, instantaneous slicer interaction, and access to the complete DAX library.
> 
> DirectQuery sends live SQL queries back to the database on every visual interaction. For our size, DirectQuery would have introduced unnecessary network latency, disabled certain time intelligence functions, and placed unnecessary query overhead on the local MySQL server."

---

### Question 10: If you presented this dashboard to the Chief Commercial Officer, what 3 immediate actions would you recommend?
**Answer:**
> "1. **Establish a 20% Maximum Discount Policy**: Ban discounts above 20% without VP approval, as our sensitivity analysis proves anything beyond 20% immediately produces a net financial loss.
> 2. **Restructure Regional Sales Incentives**: Transition regional manager bonuses away from top-line gross revenue and tie them directly to **Net Profit Margin**, directly addressing the profit destruction observed in Texas, Ohio, and Pennsylvania.
> 3. **Bundle Bulky Furniture with High-Margin Accessories**: Protect margins on Tables and Bookcases by requiring them to be purchased alongside high-margin Technology accessories (e.g. Copiers and Phones, which have 30%+ margins)."
