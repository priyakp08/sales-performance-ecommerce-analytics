# Power BI Dashboard Design & Implementation Guide

This guide provides end-to-end instructions for connecting Power BI to MySQL, configuring the data model, and building an executive-ready, 2-page interactive dashboard.

---

## 1. Connecting MySQL to Power BI Desktop

### Prerequisites
1. Power BI Desktop installed (Windows).
2. MySQL Server running with database `ecommerce_sales_db` loaded.
3. **MySQL Connector/NET** (official Oracle driver) or **ODBC Driver for MySQL** installed. If not already installed, download it from [MySQL Official Downloads](https://dev.mysql.com/downloads/connector/net/).

### Step-by-Step Connection Instructions
1. Open **Power BI Desktop**.
2. Click **Get Data** &rarr; Select **MySQL database** &rarr; Click **Connect**.
3. In the dialog:
   - **Server**: `localhost:3306` (or `127.0.0.1:3306`)
   - **Database**: `ecommerce_sales_db`
   - **Data Connectivity mode**: Select **Import** (Recommended for performance and full DAX support).
4. When prompted for credentials:
   - Select **Database** on the left tab.
   - Enter User Name: `root` (or your MySQL username).
   - Enter Password: `<your_mysql_password>`.
   - Encryption: Select "OK" or "Use Unencrypted Connection" if working locally.
5. In the **Navigator** window:
   - Check `superstore_orders` (and optionally `superstore_managers` and `superstore_returns`).
   - Click **Load** (or **Transform Data** to verify data types).

> [!TIP]
> **Zero-Dependency Fallback**: If you experience MySQL driver configuration issues on your machine, you can simply click **Get Data &rarr; Text/CSV** and select `data/processed/cleaned_superstore.csv`. The schema, column names, and DAX measures will work identically.

---

## 2. Professional Design System & Theme Specifications

Executive dashboards must prioritize clarity, visual contrast, and immediate insight over decorative embellishments.

### Palette Hierarchy
| Color Role | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Canvas Background** | `#F8FAFC` | Light neutral canvas reducing eye strain |
| **Card / Container Fill** | `#FFFFFF` | Clean white cards with 1px border (`#E2E8F0`) |
| **Primary Text / Banners**| `#0F172A` | High-contrast slate charcoal for titles |
| **Secondary / Muted Text**| `#64748B` | Subtle gray for axis labels and captions |
| **Primary Accent (Sales)**| `#2563EB` | Professional cobalt blue for revenue & volumes |
| **Success (Profitable)** | `#10B981` | Emerald green for healthy margins & positive profit |
| **Warning (Low Margin)** | `#F59E0B` | Muted amber for margins below 10% |
| **Critical Alert (Losses)**| `#EF4444` | Clear crimson red for negative profit / bleeders |

### Visual Layout Guidelines
- **Canvas Size**: 16:9 Standard (`1280 x 720` or `1920 x 1080`).
- **Typography**: `Segoe UI` across all titles, cards, and tooltips.
- **Card Styling**: 8px rounded corners, 0px drop shadow, 1px solid border `#E2E8F0`.
- **Formatting Rules**:
  - Currency metrics: `$#,##0` (or `$#,##0.00` for AOV).
  - Percentages: `0.0%` (always 1 decimal place).
  - Quantities / Orders: Whole numbers with commas (`#,##0`).

---

## 3. Page 1: Executive Sales & Profitability Performance

### Purpose
High-level operational overview for VP of Sales and Chief Commercial Officer to monitor revenue trajectory, profitability, and geographic distribution.

### Wireframe Layout
```
+-----------------------------------------------------------------------------------------+
| [LOGO]  SUPERSTORE E-COMMERCE PERFORMANCE OVERVIEW        | Slicers: [Region] [Segment] |
+-----------------------------------------------------------------------------------------+
| [ KPI 1: Revenue ]  [ KPI 2: Net Profit ]  [ KPI 3: Margin % ]  [ KPI 4: Orders ]  [ KPI 5: AOV ] |
|   $2.30M (+20% YoY)     $286.4K (12.5%)           12.47%              5,009            $458.61   |
+-----------------------------------------------------------------------------------------+
|                                              |                                          |
|  Monthly Revenue & Profit Margin Trend       |  Category & Sub-Category Performance     |
|  (Line and Clustered Column Chart)           |  (Horizontal Clustered Bar Chart)        |
|  - Columns: [Total Sales]                    |  - Y-Axis: Category / Sub-Category       |
|  - Line: [Profit Margin %]                   |  - X-Axis: [Total Sales]                 |
|  - X-Axis: DimDate[Month Year]               |  - Color: [Profit Color Alert]           |
|                                              |                                          |
+----------------------------------------------+------------------------------------------+
|                                              |                                          |
|  Regional Profitability Breakdown            |  Customer Segment Mix                    |
|  (Clustered Bar Chart / Map)                 |  (Donut Chart / Small Multi-Cards)       |
|  - West: $108.4K Profit                      |  - Consumer: 50.6% ($1.16M)              |
|  - East: $91.5K Profit                       |  - Corporate: 30.7% ($706K)              |
|  - Central: $39.7K Profit                    |  - Home Office: 18.7% ($430K)            |
|  - South: $46.7K Profit                      |                                          |
+-----------------------------------------------------------------------------------------+
```

### Visual Configuration Steps:
1. **Top Slicer Bar (Position: Y=10, Height=50)**:
   - Slicer 1: `DimDate[Year]` (Tile or Dropdown).
   - Slicer 2: `superstore_orders[region]` (Dropdown).
   - Slicer 3: `superstore_orders[segment]` (Dropdown).
2. **Top Row KPI Cards (Position: Y=70, Height=100)**:
   - Use the **New Card Visual** (or 5 standard Cards):
     - Card 1: Value = `[Total Sales]`, Label = "Total Revenue".
     - Card 2: Value = `[Total Profit]`, Label = "Net Profit".
     - Card 3: Value = `[Profit Margin %]`, Label = "Profit Margin".
     - Card 4: Value = `[Total Orders]`, Label = "Distinct Orders".
     - Card 5: Value = `[Average Order Value]`, Label = "Avg Order Value (AOV)".
3. **Monthly Trend Visual (Position: X=20, Y=180, Width=600, Height=300)**:
   - Visual Type: **Line and clustered column chart**.
   - Shared X-axis: `DimDate[Month Year]`.
   - Column y-axis: `[Total Sales]`.
   - Line y-axis: `[Profit Margin %]`.
   - Styling: Blue columns (`#2563EB`), Emerald trend line (`#10B981`).
4. **Category Breakdown (Position: X=640, Y=180, Width=600, Height=300)**:
   - Visual Type: **Clustered Bar Chart**.
   - Y-axis: `superstore_orders[sub_category]`.
   - X-axis: `[Total Sales]`.
   - Tooltips: `[Total Profit]`, `[Profit Margin %]`.
   - Data Colors: Conditional formatting using Field Value &rarr; `[Profit Color Alert]`.
5. **Regional Matrix / Bar Chart (Position: X=20, Y=500, Width=600, Height=200)**:
   - Visual Type: **Bar Chart**.
   - Y-axis: `superstore_orders[region]`.
   - X-axis: `[Total Profit]`.
6. **Segment Distribution (Position: X=640, Y=500, Width=600, Height=200)**:
   - Visual Type: **Donut Chart**.
   - Legend: `superstore_orders[segment]`.
   - Values: `[Total Sales]`.

---

## 4. Page 2: Product & Discount Diagnostics (Root Cause Deep-Dive)

### Purpose
Diagnostic tool for Category Managers and Merchandising Directors to pinpoint root causes behind margin degradation and identify loss-making products.

### Wireframe Layout
```
+-----------------------------------------------------------------------------------------+
| ROOT CAUSE ANALYSIS: MARGIN BLEED & DISCOUNT SENSITIVITY  | Filters: [Category] [State] |
+-----------------------------------------------------------------------------------------+
| [ Total Dollar Loss ]   [ Loss-Making Lines ]   [ Unprofitable % ]  [ Avg Discount on Loss ] |
|       $-156,131                 1,871                  18.7%                  39.2%          |
+-----------------------------------------------------------------------------------------+
|                                              |                                          |
|  Discount Tier Margin Collapse               |  Top 10 Profit Bleeders (Loss Makers)    |
|  (Clustered Column Chart)                    |  (Table with Data Bars)                  |
|  - Shows margin collapsing from +29.5% at    |  - Product Name                          |
|    0% discount to -77.4% at >40% discount    |  - Sub-Category                          |
|                                              |  - Sales | Loss ($) | Avg Discount       |
|                                              |                                          |
+----------------------------------------------+------------------------------------------+
|                                                                                         |
|  State-Level Profitability Disparity (Loss Map / Table)                                 |
|  - Highlights Texas (-$25.7K), Ohio (-$16.9K), Pennsylvania (-$15.6K), Illinois (-$12.6K)|
|  - Demonstrates excessive regional discounting policies as the driving culprit          |
+-----------------------------------------------------------------------------------------+
```

### Visual Configuration Steps:
1. **Diagnostic KPI Banner**:
   - Card 1: `[Total Profit Loss]` (Value: `$-156,131`, Color: `#EF4444`).
   - Card 2: `[Loss Making Lines Count]` (Value: `1,871`).
   - Card 3: `[Unprofitable Line %]` (Value: `18.7%`).
   - Card 4: Subtitle Card: "Critical Insight: 84% of all losses originate from discounts >20%".
2. **Discount Sensitivity Visual (Clustered Column Chart)**:
   - Create a Calculated Column in `superstore_orders`:
     ```dax
     Discount Tier = 
     SWITCH(
         TRUE(),
         superstore_orders[discount] = 0, "0% (No Discount)",
         superstore_orders[discount] <= 0.10, "1% - 10%",
         superstore_orders[discount] <= 0.20, "11% - 20%",
         superstore_orders[discount] <= 0.40, "21% - 40%",
         "> 40% (Heavy Discount)"
     )
     ```
   - X-axis: `Discount Tier`.
   - Y-axis: `[Profit Margin %]`.
   - Conditional Color: Positive margin = `#10B981`, Negative margin = `#EF4444`.
3. **Top 10 Profit Bleeders (Table Visual)**:
   - Values: `product_name`, `sub_category`, `[Total Sales]`, `[Total Profit Loss]`, `[Average Discount %]`.
   - Sort: `[Total Profit Loss]` Ascending.
   - Top N Filter: Filter pane &rarr; `product_name` &rarr; Top N: Bottom 10 by `[Total Profit]`.
   - Conditional Formatting: Add Red Data Bars to `Total Profit Loss`.

---

## 5. Report Publishing & Portfolio Presentation
1. In Power BI Desktop, click **File** &rarr; **Save As** &rarr; Save as `sales_performance_superstore.pbix`.
2. Click **File** &rarr; **Export** &rarr; **Export to PDF** to create a static executive deck for your GitHub portfolio.
3. Take high-resolution screenshots of both pages and place them into `docs/screenshots/` for display in the GitHub `README.md`.
