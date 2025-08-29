-- Dimensiuni
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name NVARCHAR(100),
    city NVARCHAR(50),
    country NVARCHAR(50)
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(100),
    category NVARCHAR(50),
    brand NVARCHAR(50)
);

CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    full_date DATE,
    year INT,
    quarter INT,
    month INT,
    day INT
);

CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    store_name NVARCHAR(100),
    city NVARCHAR(50),
    country NVARCHAR(50)
);

CREATE TABLE dim_employee (
    employee_id INT PRIMARY KEY,
    employee_name NVARCHAR(100),
    position NVARCHAR(50),
    hire_date DATE
);

CREATE TABLE dim_supplier (
    supplier_id INT PRIMARY KEY,
    supplier_name NVARCHAR(100),
    country NVARCHAR(50)
);

CREATE TABLE dim_currency (
    currency_id INT PRIMARY KEY,
    currency_code NVARCHAR(10),
    currency_name NVARCHAR(50)
);

CREATE TABLE dim_promotion (
    promotion_id INT PRIMARY KEY,
    promotion_name NVARCHAR(100),
    discount_percent DECIMAL(5,2)
);

CREATE TABLE dim_channel (
    channel_id INT PRIMARY KEY,
    channel_name NVARCHAR(50)
);

-- Tabel de fapt
CREATE TABLE fact_sales (
    sales_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    time_id INT,
    store_id INT,
    employee_id INT,
    supplier_id INT,
    currency_id INT,
    promotion_id INT,
    channel_id INT,
    quantity INT,
    sales_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),

    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
    FOREIGN KEY (employee_id) REFERENCES dim_employee(employee_id),
    FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id),
    FOREIGN KEY (currency_id) REFERENCES dim_currency(currency_id),
    FOREIGN KEY (promotion_id) REFERENCES dim_promotion(promotion_id),
    FOREIGN KEY (channel_id) REFERENCES dim_channel(channel_id)
);
