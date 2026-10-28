"""
Automated MySQL Database Loader Script
Project: Sales Performance & E-Commerce Analytics

Description:
Connects to local MySQL Server, creates the `ecommerce_sales_db` database,
executes table creation DDL, and batches the cleaned dataset into MySQL.
Also handles fallback to command-line MySQL or MySQL Workbench instructions.
"""

import os
import sys
import getpass
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLEANED_CSV = os.path.join(BASE_DIR, "data", "processed", "cleaned_superstore.csv")
SCHEMA_SQL = os.path.join(BASE_DIR, "sql", "01_schema_setup.sql")

def run_loader():
    print("==================================================")
    print("      MYSQL DATABASE INGESTION LOADER TOOL        ")
    print("==================================================")

    if not os.path.exists(CLEANED_CSV):
        print(f"[!] Error: Cleaned data file not found at {CLEANED_CSV}")
        print("    Please run: python scripts/download_or_generate.py first.")
        return

    print("Choose ingestion method:")
    print("1. Automated Python load (Requires pymysql or mysql-connector-python)")
    print("2. Display MySQL Workbench & LOAD DATA INFILE instructions (Recommended & Zero Dependencies)")
    
    # Check if dependencies are installed
    has_connector = False
    try:
        import pymysql
        has_connector = "pymysql"
    except ImportError:
        try:
            import mysql.connector
            has_connector = "mysql.connector"
        except ImportError:
            pass

    if not has_connector:
        print("\n[*] Python MySQL driver not detected (pymysql / mysql-connector-python).")
        print("[*] To load via Python, run: pip install pymysql sqlalchemy")
        print("\n--- STANDARD MYSQL WORKBENCH / CLI IMPORT METHOD ---")
        print("1. Open MySQL Workbench or your terminal.")
        print("2. Run the schema creation script:")
        print(f"   mysql -u root -p < \"{SCHEMA_SQL}\"")
        print("3. In MySQL Workbench:")
        print("   - Right-click `superstore_orders` table -> 'Table Data Import Wizard'.")
        print(f"   - Select file: {CLEANED_CSV}")
        print("   - Match columns and click 'Next' to import all 9,994 rows.")
        return

    # If connector is available
    host = input("Enter MySQL Host [default: localhost]: ") or "localhost"
    port = input("Enter MySQL Port [default: 3306]: ") or "3306"
    user = input("Enter MySQL User [default: root]: ") or "root"
    password = getpass.getpass("Enter MySQL Password: ")

    try:
        from sqlalchemy import create_engine, text
        engine_str = f"mysql+{has_connector}://{user}:{password}@{host}:{port}/"
        engine = create_engine(engine_str)
        with engine.connect() as conn:
            conn.execute(text("CREATE DATABASE IF NOT EXISTS ecommerce_sales_db;"))
            conn.commit()
            print("[+] Database `ecommerce_sales_db` initialized successfully.")

        # Connect to target DB
        db_engine = create_engine(f"{engine_str}ecommerce_sales_db")
        print("[*] Loading cleaned CSV into pandas DataFrame...")
        df = pd.read_csv(CLEANED_CSV)

        print(f"[*] Ingesting {len(df)} rows into table `superstore_orders`...")
        df.to_sql("superstore_orders", con=db_engine, if_exists="replace", index=False)
        print(f"[+] Successfully loaded {len(df)} rows into MySQL table `superstore_orders`!")

    except Exception as e:
        print(f"\n[!] Connection error: {e}")
        print("Please check your MySQL service and credentials.")

if __name__ == "__main__":
    run_loader()
