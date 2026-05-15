# commerce-analytics
# Olist E-Commerce Analytics

An end-to-end SQL analytics pipeline analysing 100,000+ real Brazilian e-commerce transactions to identify customer segments, revenue patterns, delivery performance, and category-level insights.

**Tools:** PostgreSQL · Python · Tableau  
**Dataset:** [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)  
**Dashboard:** [View Interactive Dashboard →](https://public.tableau.com/views/Olist_Ecommerce_dashboard/Dashboard1)

---

## Business Questions

1. **Who are our most and least valuable customers?** — RFM segmentation across 90,000+ unique customers
2. **Where are orders dropping out of the funnel?** — Order status breakdown and revenue leakage analysis
3. **Which product categories drive revenue, and which have quality problems?** — Multi-dimensional category performance analysis
4. **Do customers come back after their first purchase?** — Monthly cohort retention analysis across 20 cohorts

---

## Dashboard

![Olist E-Commerce Analytics Dashboard](Olist_dashboard.png)

---

## Key Findings

- **97% of orders reach delivered status** — revenue leakage is not a conversion problem but a delivery execution problem, with 8% of delivered orders arriving late
- **Last-mile delivery averages 9.3 days** — with seller dispatch taking 67 hours after approval, representing the primary operational bottleneck
- **No top-5 revenue category ranks in the top 20 for customer satisfaction** — revealing a systemic trade-off where the highest-earning categories have the worst delivery times and review scores
- **`office_furniture` is the most problematic category** — ranking last for both delivery speed (20.9 avg days) and review score (3.55), despite generating $635k in revenue
- **90%+ of customers are single-purchase buyers** — cohort retention never exceeds 0.7% in any month across all 20 cohorts, indicating customer acquisition is a stronger growth lever than loyalty programmes

---

## Project Structure

```
ecommerce-analytics/
│
├── README.md
│
├── schema.sql                  # PostgreSQL table definitions and indexes
├── load_data.py                # Python ingestion script (CSV → PostgreSQL)
│
├── sql/
│   ├── 01_rfm_segmentation.sql     # Customer segmentation using RFM framework
│   ├── 02_revenue_funnel.sql       # Order funnel and delivery performance
│   ├── 03_category_performance.sql # Revenue, satisfaction and speed by category
│   └── 04_cohort_analysis.sql      # Monthly cohort retention analysis
│
├── exports/                    # Query results exported for Tableau
│   ├── rfm_segments.csv
│   ├── funnel_breakdown.csv
│   ├── delivery_performance.csv
│   ├── category_performance.csv
│   └── cohort_retention.csv
│
└── images/
    └── dashboard.png
```

---

## Database Schema

Six related tables connected by foreign keys, mirroring a real e-commerce data model:

```
customers ──── orders ──── order_items ──── products ──── product_category_translations
                  │
                  ├──── order_payments
                  └──── order_reviews
                              └──── sellers
```

| Table | Rows | Description |
|---|---|---|
| customers | 99,441 | Customer demographics and location |
| orders | 99,441 | Order status and timestamps |
| order_items | 112,650 | Line items linking orders to products and sellers |
| order_payments | 103,886 | Payment method and value per order |
| order_reviews | 99,224 | Review scores and comments |
| products | 32,951 | Product dimensions and category |
| sellers | 3,095 | Seller location data |
| product_category_translations | 71 | Portuguese to English category names |

---

## SQL Techniques Demonstrated

| Query | Techniques |
|---|---|
| RFM Segmentation | CTEs, `NTILE()` window function, `CASE`, multi-table `JOIN` |
| Revenue Funnel | CTEs, `EXTRACT`, `EPOCH`, date arithmetic, `CASE` |
| Category Performance | 5-table `JOIN`, `HAVING`, `COALESCE`, `RANK()` window function |
| Cohort Retention | `DATE_TRUNC`, `MIN() OVER`, `AGE()`, self-join, retention calculation |

---

## Setup

### Prerequisites
- PostgreSQL 14+
- Python 3.9+
- `pip install pandas psycopg2-binary sqlalchemy`

### Steps

**1. Create the database**
```sql
CREATE DATABASE ecommerce;
\c ecommerce
\i schema.sql
```

**2. Download the dataset**  
Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and place the CSVs in a local folder.

**3. Configure and run the ingestion script**  
Update `DB_CONFIG` and `DATA_PATH` in `load_data.py`, then:
```bash
python load_data.py
```

**4. Run the SQL analyses**  
Open each `.sql` file in DBeaver, pgAdmin, or psql and execute against the `ecommerce` database.

**5. View the dashboard**  
Open the [interactive Tableau dashboard](https://public.tableau.com/views/Olist_Ecommerce_dashboard/Dashboard1) or connect Tableau to the exported CSVs in `/exports`.
