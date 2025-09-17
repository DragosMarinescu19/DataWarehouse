use DataWarehouse2
go
CREATE OR ALTER PROCEDURE load_demo
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------
    -- DIM PRODUCT
    -------------------------------------
    INSERT INTO dim_product (product_id, product_name, category, brand)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS product_id,
        CONCAT('Product_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('Category_', ABS(CHECKSUM(NEWID())) % 50),
        CONCAT('Brand_', ABS(CHECKSUM(NEWID())) % 500)
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    

    -------------------------------------
    -- DIM STORE
    -------------------------------------
    INSERT INTO dim_store (store_id, store_name, city, country)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS store_id,
        CONCAT('Store_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('City_', ABS(CHECKSUM(NEWID())) % 1000),
        CONCAT('Country_', ABS(CHECKSUM(NEWID())) % 100)
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    -------------------------------------
    -- DIM EMPLOYEE
    -------------------------------------
    INSERT INTO dim_employee (employee_id, employee_name, position, hire_date)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS employee_id,
        CONCAT('Employee_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('Position_', ABS(CHECKSUM(NEWID())) % 20),
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 5000, GETDATE())
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    -------------------------------------
    -- DIM SUPPLIER
    -------------------------------------
    INSERT INTO dim_supplier (supplier_id, supplier_name, country)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS supplier_id,
        CONCAT('Supplier_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('Country_', ABS(CHECKSUM(NEWID())) % 100)
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    -------------------------------------
    -- DIM CURRENCY
    -------------------------------------
    INSERT INTO dim_currency (currency_id, currency_code, currency_name)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS currency_id,
        CONCAT('C', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CONCAT('Currency_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    -------------------------------------
    -- DIM PROMOTION
    -------------------------------------
    INSERT INTO dim_promotion (promotion_id, promotion_name, discount_percent)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS promotion_id,
        CONCAT('Promo_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL))),
        CAST(ABS(CHECKSUM(NEWID())) % 50 AS DECIMAL(5,2))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

    -------------------------------------
    -- DIM CHANNEL
    -------------------------------------
    INSERT INTO dim_channel (channel_id, channel_name)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS channel_id,
        CONCAT('Channel_', ROW_NUMBER() OVER (ORDER BY (SELECT NULL)))
    FROM sys.all_objects a CROSS JOIN sys.all_objects b;

	-------------------------------------
    -- STAGE CUSTOMER(DIMENSION)
    -------------------------------------
    DECLARE @CityCountry TABLE (
        CityName NVARCHAR(100),
        CountryName NVARCHAR(100)
    );

    INSERT INTO @CityCountry (CityName, CountryName) VALUES
    ('Bucharest', 'Romania'),
    ('Cluj-Napoca', 'Romania'),
    ('Timisoara', 'Romania'),
    ('Budapest', 'Hungary'),
    ('Debrecen', 'Hungary'),
    ('Vienna', 'Austria'),
    ('Salzburg', 'Austria'),
    ('Paris', 'France'),
    ('Lyon', 'France'),
    ('Berlin', 'Germany'),
    ('Munich', 'Germany'),
    ('Madrid', 'Spain'),
    ('Barcelona', 'Spain');
    INSERT INTO staging_customer (customer_id, customer_name, city, country)
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS customer_id,
        CONCAT('Customer_', NEWID()) AS customer_name,
        T1.CityName AS city,
        T1.CountryName AS country
    FROM 
        (SELECT TOP 1000 * FROM @CityCountry ORDER BY NEWID()) AS T1 
        CROSS JOIN 
        sys.all_objects AS a 
        CROSS JOIN 
        sys.all_objects AS b;


    -------------------------------------
    -- STAGING SALES (FACT)
    -------------------------------------
    DECLARE @i INT = 0;
    WHILE @i < 50
    BEGIN
        INSERT INTO staging_sales (
            sales_id, customer_id, product_id, store_id, employee_id,
            supplier_id, currency_id, promotion_id, channel_id,
            quantity, sales_amount, cost_amount
        )
        SELECT TOP (1000)
            (@i * 100000) + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS sales_id,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,	
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 1000 + 1,
            ABS(CHECKSUM(NEWID())) % 100 + 1,
            CAST(ABS(CHECKSUM(NEWID())) % 1000 AS DECIMAL(18,2)),
            CAST(ABS(CHECKSUM(NEWID())) % 800 AS DECIMAL(18,2))
        FROM sys.all_objects a CROSS JOIN sys.all_objects b;

        SET @i += 1;
    END

END;
GO
exec load_demo
