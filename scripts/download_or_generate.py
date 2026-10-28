"""
Data Preparation, Quality Audit, & Cleaning Script
Project: Sales Performance & E-Commerce Analytics
Author: Junior Data Analyst Portfolio

Description:
1. Downloads or loads the verified public Tableau Sample Superstore dataset.
2. Identifies and handles composite sheet concatenation anomalies (Orders, People, Returns).
3. Cleanses missing values (e.g. 11 missing Burlington, VT zip codes).
4. Validates date formats and standardizes to ISO-8601 (YYYY-MM-DD) for MySQL compatibility.
5. Computes ground-truth baseline metrics for SQL and Power BI cross-validation.
6. Exports cleaned CSV files ready for database ingestion and BI reporting.
"""

import os
import urllib.request
import pandas as pd
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
DATA_PROC_DIR = os.path.join(BASE_DIR, "data", "processed")

os.makedirs(DATA_RAW_DIR, exist_ok=True)
os.makedirs(DATA_PROC_DIR, exist_ok=True)

RAW_FILE_PATH = os.path.join(DATA_RAW_DIR, "Sample_Superstore_raw.csv")
CLEANED_ORDERS_PATH = os.path.join(DATA_PROC_DIR, "cleaned_superstore.csv")
RETURNS_PATH = os.path.join(DATA_PROC_DIR, "superstore_returns.csv")
PEOPLE_PATH = os.path.join(DATA_PROC_DIR, "superstore_people.csv")

DATASET_URL = "https://raw.githubusercontent.com/leonism/sample-superstore/master/data/superstore.csv"

def download_data():
    if not os.path.exists(RAW_FILE_PATH):
        print(f"[*] Downloading raw dataset from: {DATASET_URL}")
        req = urllib.request.Request(DATASET_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as response, open(RAW_FILE_PATH, "wb") as out_file:
            out_file.write(response.read())
        print(f"[+] Download complete: {RAW_FILE_PATH}")
    else:
        print(f"[+] Found existing raw dataset: {RAW_FILE_PATH}")

def run_data_pipeline():
    download_data()
    print("\n=======================================================")
    print("      DATA INGESTION & DATA QUALITY AUDIT PIPELINE      ")
    print("=======================================================")

    df_raw = pd.read_csv(RAW_FILE_PATH, encoding="latin-1")
    total_raw_rows, total_raw_cols = df_raw.shape
    print(f"Total Raw Rows: {total_raw_rows} | Total Columns: {total_raw_cols}")

    # Section 1: Sheet Concatenation Anomaly Detection
    # In classic Superstore datasets, multi-sheet Excel files sometimes have 'People' and 'Returns' appended.
    # Canonical Orders table is exactly rows 0 to 9993 (9,994 rows).
    orders_slice = df_raw.iloc[:9994].copy()
    people_returns_slice = df_raw.iloc[9994:].copy()

    print(f"\n[1] ANOMALY DETECTION: MULTI-SHEET DATA ISOLATION")
    print(f" - Primary Transaction Order Lines: {len(orders_slice)} rows")
    print(f" - Appended Metadata Rows (People & Returns): {len(people_returns_slice)} rows")

    # Extract People metadata
    # Row 9994 is header ('Person', 'Region'), rows 9995-9998 are regional managers
    people_rows = df_raw.iloc[9995:9999, :2].copy()
    people_rows.columns = ["person", "region"]
    people_rows.to_csv(PEOPLE_PATH, index=False)
    print(f" - Exported People (Regional Managers) to: {os.path.basename(PEOPLE_PATH)}")

    # Extract Returns metadata
    # Row 9999 is header ('Returned', 'Order ID'), row 10000+ are returned orders
    returns_rows = df_raw.iloc[10000:, :2].copy()
    returns_rows.columns = ["returned", "order_id"]
    returns_rows = returns_rows.dropna(subset=["order_id"]).drop_duplicates(subset=["order_id"])
    returns_rows.to_csv(RETURNS_PATH, index=False)
    print(f" - Exported Returns ({len(returns_rows)} distinct returned orders) to: {os.path.basename(RETURNS_PATH)}")

    # Section 2: Order Table Cleaning & Formatting
    print(f"\n[2] TRANSACTION ORDER CLEANING & VALIDATION")
    df = orders_slice

    # Missing value handling
    null_postal = df["Postal Code"].isnull().sum()
    print(f" - Missing Postal Codes: {null_postal} rows (all in Burlington, Vermont).")
    # Impute standard Burlington, VT postal code '05408'
    df["Postal Code"] = df["Postal Code"].fillna("05408")
    df["Postal Code"] = df["Postal Code"].astype(str).str.replace(r"\.0$", "", regex=True).str.zfill(5)

    # Date parsing and format conversion to ISO-8601 (YYYY-MM-DD)
    df["Order Date"] = pd.to_datetime(df["Order Date"], format="mixed")
    df["Ship Date"] = pd.to_datetime(df["Ship Date"], format="mixed")

    # Business rule validation: Ship Date >= Order Date
    invalid_shipping = df[df["Ship Date"] < df["Order Date"]]
    print(f" - Date Integrity Check (Ship Date < Order Date): {len(invalid_shipping)} violations found.")

    shipping_days = (df["Ship Date"] - df["Order Date"]).dt.days
    print(f" - Shipping Lead Times: Min = {shipping_days.min()} days, Max = {shipping_days.max()} days, Avg = {shipping_days.mean():.2f} days")

    df["Order Date"] = df["Order Date"].dt.strftime("%Y-%m-%d")
    df["Ship Date"] = df["Ship Date"].dt.strftime("%Y-%m-%d")

    # Numerical formatting
    df["Row ID"] = df["Row ID"].astype(int)
    df["Sales"] = pd.to_numeric(df["Sales"]).round(4)
    df["Quantity"] = pd.to_numeric(df["Quantity"]).astype(int)
    df["Discount"] = pd.to_numeric(df["Discount"]).round(2)
    df["Profit"] = pd.to_numeric(df["Profit"]).round(4)

    # Section 3: Duplicate Order Line vs Multiple Item Validation
    distinct_orders = df["Order ID"].nunique()
    exact_duplicates = df.duplicated().sum()
    print(f"\n[3] DUPLICATE & TRANSACTION GRANULARITY AUDIT")
    print(f" - Exact duplicate rows across all columns: {exact_duplicates}")
    print(f" - Total Transaction Order Lines: {len(df):,}")
    print(f" - Unique Orders (Distinct Order IDs): {distinct_orders:,}")
    print(f" - Average Items per Order: {len(df) / distinct_orders:.2f} items")

    # Section 4: Ground-Truth Financial Metrics
    total_sales = df["Sales"].sum()
    total_profit = df["Profit"].sum()
    overall_profit_margin = (total_profit / total_sales) * 100
    true_aov = total_sales / distinct_orders
    loss_lines = df[df["Profit"] < 0]

    print(f"\n[4] BASELINE FINANCIAL GROUND-TRUTH (FOR SQL & POWER BI CROSS-CHECK)")
    print(f" - Total Verified Sales:        ${total_sales:,.2f}")
    print(f" - Total Verified Profit:       ${total_profit:,.2f}")
    print(f" - Overall Profit Margin:       {overall_profit_margin:.2f}%")
    print(f" - True Average Order Value:    ${true_aov:,.2f}")
    print(f" - Total Quantity Sold:         {df['Quantity'].sum():,} units")
    print(f" - Loss-Making Line Items:      {len(loss_lines):,} rows ({len(loss_lines)/len(df)*100:.2f}%)")
    print(f" - Total Dollar Loss:           ${loss_lines['Profit'].sum():,.2f}")

    # Section 5: Column Standardization & Export
    col_mapping = {
        "Row ID": "row_id",
        "Order ID": "order_id",
        "Order Date": "order_date",
        "Ship Date": "ship_date",
        "Ship Mode": "ship_mode",
        "Customer ID": "customer_id",
        "Customer Name": "customer_name",
        "Segment": "segment",
        "Country": "country",
        "City": "city",
        "State": "state",
        "Postal Code": "postal_code",
        "Region": "region",
        "Product ID": "product_id",
        "Category": "category",
        "Sub-Category": "sub_category",
        "Product Name": "product_name",
        "Sales": "sales",
        "Quantity": "quantity",
        "Discount": "discount",
        "Profit": "profit"
    }
    df_clean = df.rename(columns=col_mapping)
    df_clean.to_csv(CLEANED_ORDERS_PATH, index=False)
    print(f"\n[+] Successfully saved cleaned dataset to:\n    {CLEANED_ORDERS_PATH}")
    print("=======================================================\n")

if __name__ == "__main__":
    run_data_pipeline()
