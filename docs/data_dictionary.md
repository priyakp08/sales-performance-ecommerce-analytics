# Data Dictionary: Superstore E-Commerce Dataset

This document defines the schema, data types, business definitions, and operational constraints for all attributes within the `superstore_orders` table.

## Primary Table: `superstore_orders`
- **Granularity**: Order Line Item (one row per SKU purchased within an order).
- **Total Record Count**: 9,994 rows.
- **Primary Key**: `row_id` (Unique integer assigned to each transaction line item).

| Column Name | Data Type (MySQL) | Nullable | Description & Business Meaning | Example Value |
| :--- | :--- | :--- | :--- | :--- |
| `row_id` | `INT` | No | Unique auto-incremented primary key for the transaction row. | `1` |
| `order_id` | `VARCHAR(25)` | No | Unique identifier for a customer transaction. Multiple rows can share the same Order ID if multiple products were bought together. | `CA-2017-152156` |
| `order_date` | `DATE` | No | Date on which the customer placed the order (ISO `YYYY-MM-DD`). | `2017-11-08` |
| `ship_date` | `DATE` | No | Date on which the order was shipped from the warehouse. | `2017-11-11` |
| `ship_mode` | `VARCHAR(25)` | No | Shipping service tier: `Standard Class`, `Second Class`, `First Class`, or `Same Day`. | `Second Class` |
| `customer_id` | `VARCHAR(25)` | No | Unique alpha-numeric identifier for individual customer profile. | `CG-12520` |
| `customer_name` | `VARCHAR(100)` | No | Full legal or display name of the customer. | `Claire Gute` |
| `segment` | `VARCHAR(25)` | No | Market customer segment: `Consumer` (B2C), `Corporate` (B2B), or `Home Office`. | `Consumer` |
| `country` | `VARCHAR(50)` | No | Country of destination (all records are `United States`). | `United States` |
| `city` | `VARCHAR(50)` | No | Destination delivery city. | `Henderson` |
| `state` | `VARCHAR(50)` | No | Destination US state (49 unique states represented). | `Kentucky` |
| `postal_code` | `VARCHAR(15)` | Yes | 5-digit US ZIP code. Stored as string to preserve leading zeros. Burlington, VT rows imputed with `05408`. | `42420` |
| `region` | `VARCHAR(25)` | No | Commercial geographical sales division: `West`, `East`, `Central`, `South`. | `South` |
| `product_id` | `VARCHAR(30)` | No | Internal Stock Keeping Unit (SKU) identifier. | `FUR-BO-10001798` |
| `category` | `VARCHAR(30)` | No | Top-level departmental grouping: `Furniture`, `Office Supplies`, `Technology`. | `Furniture` |
| `sub_category` | `VARCHAR(30)` | No | Specific product category (17 distinct types, e.g., `Chairs`, `Phones`, `Tables`). | `Bookcases` |
| `product_name` | `VARCHAR(255)` | No | Full commercial product description title. | `Bush Somerset Collection Bookcase` |
| `sales` | `DECIMAL(10,4)`| No | Invoiced gross revenue for the line item (Unit Price $\times$ Quantity $\times (1 - \text{Discount})$). | `261.9600` |
| `quantity` | `INT` | No | Units of this specific product purchased. | `2` |
| `discount` | `DECIMAL(5,2)` | No | Applied discount percentage expressed as a decimal (e.g. `0.20` = 20%). Range: `0.00` to `0.80`. | `0.00` |
| `profit` | `DECIMAL(10,4)`| No | Net dollar gain or loss after subtracting Cost of Goods Sold (COGS) and allocated freight. Can be negative. | `41.9136` |

---

## Supplementary Metadata Tables

### 1. `superstore_returns`
Tracks customer returns logged by the logistics department.
- `order_id` (`VARCHAR(25)` - Primary Key): The returned transaction identifier.
- `returned` (`VARCHAR(10)`): Returns status flag (`Yes`).
- **Volume**: 296 distinct returned orders.

### 2. `superstore_managers`
Tracks corporate regional ownership.
- `region` (`VARCHAR(25)` - Primary Key): Sales region (`West`, `East`, `Central`, `South`).
- `person` (`VARCHAR(100)`): Regional director name (e.g., Anna Andreadi, Chuck Magee, Kelly Williams, Cassandra Brandow).
