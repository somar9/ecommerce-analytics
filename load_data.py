import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# ============================================================
# Configuration
# ============================================================

DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "dbname":   "ecommerce",
    "user":     "postgres",
    "password": "Password"   # replace with your postgres password
}

DATA_PATH = "/Users/omarsamad/Documents/ecommerce_project/Olist_dataset/"

# ============================================================
# Helpers
# ============================================================

def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def load_table(conn, table_name, df):
    """Insert a dataframe into a PostgreSQL table using batch inserts."""
    cols = list(df.columns)
    col_str = ", ".join(cols)

    def clean(v):
        if v is pd.NaT:
            return None
        if isinstance(v, float) and pd.isna(v):
            return None
        return v

    values = [tuple(clean(v) for v in row) for row in df.itertuples(index=False, name=None)]
    query = f"INSERT INTO {table_name} ({col_str}) VALUES %s ON CONFLICT DO NOTHING"

    with conn.cursor() as cur:
        execute_values(cur, query, values)
    conn.commit()
    print(f"  Loaded {len(values):,} rows into {table_name}")

def main():
    conn = get_connection()
    print("Connected to PostgreSQL\n")

    # 1. customers
    print("Loading customers...")
    customers = pd.read_csv(DATA_PATH + "olist_customers_dataset.csv")
    customers = customers.rename(columns={
        "customer_zip_code_prefix": "zip_code_prefix",
        "customer_city":            "city",
        "customer_state":           "state"
    })[["customer_id", "customer_unique_id", "zip_code_prefix", "city", "state"]]
    customers = customers.dropna(subset=["customer_id"])
    load_table(conn, "customers", customers)

    # 2. sellers
    print("Loading sellers...")
    sellers = pd.read_csv(DATA_PATH + "olist_sellers_dataset.csv")
    sellers = sellers.rename(columns={
        "seller_zip_code_prefix": "zip_code_prefix",
        "seller_city":            "city",
        "seller_state":           "state"
    })[["seller_id", "zip_code_prefix", "city", "state"]]
    sellers = sellers.dropna(subset=["seller_id"])
    load_table(conn, "sellers", sellers)

    # 3. product_category_translations
    print("Loading product_category_translations...")
    translations = pd.read_csv(DATA_PATH + "product_category_name_translation.csv")
    translations = translations.rename(columns={
        "product_category_name":         "category_name_portuguese",
        "product_category_name_english": "category_name_english"
    })
    translations = translations.dropna(subset=["category_name_portuguese"])
    load_table(conn, "product_category_translations", translations)

    # 4. products
    print("Loading products...")
    from sqlalchemy import create_engine

    products = pd.read_csv(DATA_PATH + "olist_products_dataset.csv")
    products = products.rename(columns={
        "product_category_name":        "category_name",
        "product_name_lenght":          "name_length",
        "product_description_lenght":   "description_length",
        "product_photos_qty":           "photos_qty",
        "product_weight_g":             "weight_g",
        "product_length_cm":            "length_cm",
        "product_height_cm":            "height_cm",
        "product_width_cm":             "width_cm"
    })[["product_id", "category_name", "name_length", "description_length",
        "photos_qty", "weight_g", "length_cm", "height_cm", "width_cm"]]

    valid_categories = set(translations["category_name_portuguese"])
    products["category_name"] = products["category_name"].where(
        products["category_name"].isin(valid_categories), other=None
    )
    products = products.dropna(subset=["product_id"])

    password = DB_CONFIG["password"]
    engine = create_engine(f"postgresql://postgres:{password}@localhost:5432/ecommerce")
    from sqlalchemy import text
    with engine.connect() as con:
        con.execute(text("DELETE FROM products"))
        con.commit()
    products.to_sql("products", engine, if_exists="append", index=False, method="multi")
    print(f"  Loaded {len(products):,} rows into products")

    # 5. orders
    print("Loading orders...")
    orders = pd.read_csv(DATA_PATH + "olist_orders_dataset.csv", parse_dates=[
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date"
    ])
    orders = orders[["order_id", "customer_id", "order_status",
                     "order_purchase_timestamp", "order_approved_at",
                     "order_delivered_carrier_date", "order_delivered_customer_date",
                     "order_estimated_delivery_date"]]
    orders = orders.dropna(subset=["order_id", "customer_id"])
    orders = orders.where(pd.notnull(orders), None)
    load_table(conn, "orders", orders)

    # 6. order_items
    print("Loading order_items...")
    items = pd.read_csv(DATA_PATH + "olist_order_items_dataset.csv",
                        parse_dates=["shipping_limit_date"])
    items = items[["order_id", "order_item_id", "product_id", "seller_id",
                   "shipping_limit_date", "price", "freight_value"]]
    items = items.dropna(subset=["order_id"])
    items = items.where(pd.notnull(items), None)
    load_table(conn, "order_items", items)

    # 7. order_payments
    print("Loading order_payments...")
    payments = pd.read_csv(DATA_PATH + "olist_order_payments_dataset.csv")
    payments = payments[["order_id", "payment_sequential", "payment_type",
                         "payment_installments", "payment_value"]]
    payments = payments.dropna(subset=["order_id"])
    payments = payments.where(pd.notnull(payments), None)
    load_table(conn, "order_payments", payments)

    # 8. order_reviews
    print("Loading order_reviews...")
    reviews = pd.read_csv(DATA_PATH + "olist_order_reviews_dataset.csv",
                          parse_dates=["review_creation_date", "review_answer_timestamp"])
    reviews = reviews.rename(columns={
        "review_comment_title":   "comment_title",
        "review_comment_message": "comment_message",
        "review_creation_date":   "creation_date",
        "review_answer_timestamp":"answer_timestamp"
    })[["review_id", "order_id", "review_score", "comment_title",
        "comment_message", "creation_date", "answer_timestamp"]]
    reviews = reviews.dropna(subset=["order_id"])
    reviews = reviews.where(pd.notnull(reviews), None)
    load_table(conn, "order_reviews", reviews)

    print("\nAll tables loaded successfully.")
    conn.close()


if __name__ == "__main__":
    main()
