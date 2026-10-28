# Power BI Data Modeling & Star Schema Architecture

## 1. Why Dimensional Modeling Matters in Analytics
A frequent mistake junior analysts make in their portfolios is loading a single flat Excel sheet and building visuals directly off it. In enterprise business intelligence, **dimensional modeling (Star Schema)** is the industry standard because it:
1. **Accelerates Performance**: Reduces redundant string storage and enhances VertiPaq engine columnar compression.
2. **Enables Robust Time Intelligence**: Allows DAX functions like `SAMEPERIODLASTYEAR()`, `DATESYTD()`, and `DATEADD()` to function without date gaps.
3. **Improves Model Maintainability**: Separates numerical facts (transactions) from descriptive attributes (customers, geography, products).

---

## 2. Schema Architecture

```
                  +-------------------+
                  |      DimDate      |
                  +-------------------+
                  | Date (PK)         |
                  | Year              |
                  | Quarter           |
                  | Month Name        |
                  | Year-Month        |
                  +---------+---------+
                            | 1
                            |
                            | *
+-----------------+       +-----------------------+       +-------------------+
|   DimCustomer   |       |   superstore_orders   |       |    DimProduct     |
+-----------------+       +-----------------------+       +-------------------+
| customer_id(PK) | 1   * | row_id (PK)           | *   1 | product_id (PK)   |
| customer_name   +-------+ customer_id (FK)      +-------+ product_name      |
| segment         |       | product_id (FK)       |       | category          |
+-----------------+       | order_date (FK)       |       | sub_category      |
                          | sales, profit, etc.   |       +-------------------+
                          +-----------+-----------+
                                      | *
                                      |
                                      | 1
                          +-----------+-----------+
                          |     DimGeography      |
                          +-----------------------+
                          | postal_code (PK)      |
                          | city, state, region   |
                          +-----------------------+
```

---

## 3. Creating the Calendar Dimension (`DimDate`) in Power BI
To ensure full compatibility with Power BI time intelligence functions, create a dedicated DAX Date table:

### Step 1: Create Date Table in Power BI
1. In Power BI Desktop, click **Modeling** ribbon &rarr; **New Table**.
2. Paste the following DAX code:

```dax
DimDate = 
VAR MinDate = MIN(superstore_orders[order_date])
VAR MaxDate = MAX(superstore_orders[ship_date])
VAR StartYear = YEAR(MinDate)
VAR EndYear = YEAR(MaxDate)
RETURN
ADDCOLUMNS(
    CALENDAR(DATE(StartYear, 1, 1), DATE(EndYear, 12, 31)),
    "Year", YEAR([Date]),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "Year Quarter", YEAR([Date]) & "-Q" & FORMAT([Date], "Q"),
    "Month Number", MONTH([Date]),
    "Month Name", FORMAT([Date], "mmm"),
    "Month Year", FORMAT([Date], "mmm yyyy"),
    "Year Month Sort", YEAR([Date]) * 100 + MONTH([Date]),
    "Day of Week", FORMAT([Date], "ddd"),
    "Day of Week Number", WEEKDAY([Date], 2),
    "Is Weekend", IF(WEEKDAY([Date], 2) IN {6, 7}, "Weekend", "Weekday")
)
```

### Step 2: Configure Date Sort & Properties
1. Select the `Month Year` column &rarr; click **Column tools** &rarr; **Sort by Column** &rarr; Select `Year Month Sort`. This prevents chronological alphabetical sorting (e.g. April before January).
2. Right-click the `DimDate` table in the Fields list &rarr; click **Mark as date table** &rarr; select column `Date`.

---

## 4. Establishing Relationships in Model View
1. Switch to the **Model View** (left navigation bar, third icon).
2. Drag `DimDate[Date]` to `superstore_orders[order_date]`:
   - Cardinality: **One to Many (1:*)**
   - Cross filter direction: **Single**
   - Make this relationship active: **Checked**
3. Drag `superstore_orders[ship_date]` to `DimDate[Date]` (optional secondary relationship):
   - Power BI will create a **dotted inactive relationship**, which can be invoked in DAX when analyzing fulfillment lag via `USERELATIONSHIP()`.

---

## 5. Storage Mode Decision: Import vs. DirectQuery
For a dataset of 10,000 to 1,000,000 rows:
- **Selected Mode**: **Import Mode** (In-Memory VertiPaq).
- **Justification**:
  - Delivers sub-second visual rendering and instantaneous cross-filtering.
  - Supports the entire DAX formula library (certain time intelligence and distinct count functions have strict limitations or high latency under DirectQuery).
  - Minimizes compute load on the local MySQL server during interactive stakeholder slicing.
