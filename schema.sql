-- ============================================================
-- Olist E-Commerce Database Schema
-- ============================================================

-- Drop tables if rebuilding from scratch (order matters for FK constraints)
DROP TABLE IF EXISTS order_reviews   CASCADE;
DROP TABLE IF EXISTS order_payments  CASCADE;
DROP TABLE IF EXISTS order_items     CASCADE;
DROP TABLE IF EXISTS orders          CASCADE;
DROP TABLE IF EXISTS customers       CASCADE;
DROP TABLE IF EXISTS products        CASCADE;
DROP TABLE IF EXISTS sellers         CASCADE;
DROP TABLE IF EXISTS product_category_translations CASCADE;

-- ------------------------------------------------------------
-- 1. customers
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id             VARCHAR(50) PRIMARY KEY,
    customer_unique_id      VARCHAR(50) NOT NULL,
    zip_code_prefix         VARCHAR(10),
    city                    VARCHAR(100),
    state                   CHAR(2)
);

-- ------------------------------------------------------------
-- 2. sellers
-- ------------------------------------------------------------
CREATE TABLE sellers (
    seller_id               VARCHAR(50) PRIMARY KEY,
    zip_code_prefix         VARCHAR(10),
    city                    VARCHAR(100),
    state                   CHAR(2)
);

-- ------------------------------------------------------------
-- 3. product_category_translations
-- ------------------------------------------------------------
CREATE TABLE product_category_translations (
    category_name_portuguese VARCHAR(100) PRIMARY KEY,
    category_name_english    VARCHAR(100)
);

-- ------------------------------------------------------------
-- 4. products
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id              VARCHAR(50) PRIMARY KEY,
    category_name           VARCHAR(100),
    name_length             INT,
    description_length      INT,
    photos_qty              INT,
    weight_g                NUMERIC(10,2),
    length_cm               NUMERIC(10,2),
    height_cm               NUMERIC(10,2),
    width_cm                NUMERIC(10,2),
    FOREIGN KEY (category_name) REFERENCES product_category_translations(category_name_portuguese)
);

-- ------------------------------------------------------------
-- 5. orders
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id                        VARCHAR(50) PRIMARY KEY,
    customer_id                     VARCHAR(50) NOT NULL,
    order_status                    VARCHAR(20),
    order_purchase_timestamp        TIMESTAMP,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ------------------------------------------------------------
-- 6. order_items
-- ------------------------------------------------------------
CREATE TABLE order_items (
    order_id                VARCHAR(50) NOT NULL,
    order_item_id           INT         NOT NULL,
    product_id              VARCHAR(50),
    seller_id               VARCHAR(50),
    shipping_limit_date     TIMESTAMP,
    price                   NUMERIC(10,2),
    freight_value           NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id)
);

-- ------------------------------------------------------------
-- 7. order_payments
-- ------------------------------------------------------------
CREATE TABLE order_payments (
    order_id                VARCHAR(50) NOT NULL,
    payment_sequential      INT         NOT NULL,
    payment_type            VARCHAR(30),
    payment_installments    INT,
    payment_value           NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ------------------------------------------------------------
-- 8. order_reviews
-- ------------------------------------------------------------
CREATE TABLE order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50) NOT NULL,
    review_score            SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    comment_title           TEXT,
    comment_message         TEXT,
    creation_date           TIMESTAMP,
    answer_timestamp        TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ------------------------------------------------------------
-- Indexes — speeds up the joins used in every analysis query
-- ------------------------------------------------------------
CREATE INDEX idx_orders_customer      ON orders(customer_id);
CREATE INDEX idx_orders_status        ON orders(order_status);
CREATE INDEX idx_orders_purchase_ts   ON orders(order_purchase_timestamp);
CREATE INDEX idx_items_order          ON order_items(order_id);
CREATE INDEX idx_items_product        ON order_items(product_id);
CREATE INDEX idx_items_seller         ON order_items(seller_id);
CREATE INDEX idx_payments_order       ON order_payments(order_id);
CREATE INDEX idx_reviews_order        ON order_reviews(order_id);
CREATE INDEX idx_products_category    ON products(category_name);
