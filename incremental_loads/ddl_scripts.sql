-- Dimensiuni
create table dim_customer_scd3
(
	customer_id int primary key,
	prev_customer_name nvarchar(100) null,
	curr_customer_name nvarchar(100) not null,
	prev_city nvarchar(100) null,
	curr_city nvarchar(100) not null,
	prev_country nvarchar(100) null,
	curr_country nvarchar(100) not null,
	from_date datetime not null default GETDATE()
)
insert into dim_customer_scd3(customer_id,prev_customer_name,curr_customer_name,prev_city,curr_city,prev_country,curr_country)
select customer_id,null, customer_name,null, city,null, country from staging_customer
--SCD3

create table dim_customer_scd2 (
	customer_key int identity primary key ,
	customer_id int not null,
	customer_name nvarchar(100),
	city nvarchar(50),
	country nvarchar(50),
	[start_date] date not null default getdate(),
	[end_date] date null default null,
	is_active bit default 1
)
go
insert into dim_customer_scd2(customer_id,customer_name,city,country) select * from dim_customer
select * from dim_customer_scd2
--SCD2

CREATE TABLE staging_customer (
    customer_id INT PRIMARY KEY,
    customer_name NVARCHAR(100),
    city NVARCHAR(50),
    country NVARCHAR(50)
);
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
truncate table staging_sales;
delete from fact_sales;

delete from staging_customer;
delete from dim_supplier;
delete from dim_store
delete from dim_product
delete from dim_promotion
delete from dim_employee
delete from dim_customer
delete from dim_currency
delete from dim_channel

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
CREATE TABLE staging_sales (
    sales_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    store_id INT,
    employee_id INT,
    supplier_id INT,
    currency_id INT,
    promotion_id INT,
    channel_id INT,
    quantity INT,
    sales_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),
	last_modified DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (customer_id) REFERENCES staging_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
    FOREIGN KEY (employee_id) REFERENCES dim_employee(employee_id),
    FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id),
    FOREIGN KEY (currency_id) REFERENCES dim_currency(currency_id),
    FOREIGN KEY (promotion_id) REFERENCES dim_promotion(promotion_id),
    FOREIGN KEY (channel_id) REFERENCES dim_channel(channel_id)
);


-- Tabel de fapt
CREATE TABLE fact_sales (
    sales_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
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
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
    FOREIGN KEY (employee_id) REFERENCES dim_employee(employee_id),
    FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id),
    FOREIGN KEY (currency_id) REFERENCES dim_currency(currency_id),
    FOREIGN KEY (promotion_id) REFERENCES dim_promotion(promotion_id),
    FOREIGN KEY (channel_id) REFERENCES dim_channel(channel_id)
);
