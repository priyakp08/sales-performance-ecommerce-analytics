# Raw Dataset Documentation & Sourcing Guide

## 1. Dataset Origin & Authenticity
This project uses the official **Sample Superstore** benchmark retail dataset, originally provided by Tableau / Salesforce for business intelligence and e-commerce analytics demonstrations.

- **Primary Source**: [Tableau Community Sample Data](https://community.tableau.com/s/sample-data)
- **Kaggle Mirror**: [Kaggle: Sample Superstore Dataset](https://www.kaggle.com/datasets/bravehart101/sample-superstore-dataset)
- **Direct GitHub Raw Mirror**: `https://raw.githubusercontent.com/leonism/sample-superstore/master/data/superstore.csv`

## 2. Granularity & Structure
- **Entity**: Retail E-Commerce Order Line Items
- **Total Transactions**: 9,994 line items
- **Unique Orders**: 5,009 distinct orders
- **Time Horizon**: 4 consecutive years (2015 – 2018 or 2016 – 2019 depending on release version)
- **Geography**: 531 cities across 49 US States

## 3. Important Real-World Data Anomaly
In the raw repository dump, three distinct Excel tabs (`Orders`, `People`, `Returns`) were concatenated vertically.
- Rows 1 – 9,994: The actual transaction lines.
- Rows 9,995 – 9,998: Regional sales managers (`People` tab).
- Rows 10,000+: Returned orders log (`Returns` tab).

Running the provided automation script:
```bash
python scripts/download_or_generate.py
```
automatically isolates these sheets, cleans the Burlington, VT missing postal codes, formats all dates into standard ISO `YYYY-MM-DD`, and generates the database-ready files in `data/processed/`.
