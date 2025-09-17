
--Create procedure to mimmic slowly changing dimensions
--We run this and then incremental loading for scd2 to see the inserts and updates
CREATE OR ALTER PROCEDURE update_staging_customer
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE T
    SET 
        T.customer_name = CONCAT('New_name_', NEWID()),
        T.city = CONCAT('New_city_', NEWID()),
        T.country = CONCAT('New_country_', NEWID())
    FROM (
        SELECT TOP 100 *
        FROM staging_customer
        ORDER BY NEWID()
    ) AS T;

    DECLARE @max_id INT;
    SELECT @max_id = ISNULL(MAX(customer_id), 0) FROM staging_customer;

    INSERT INTO staging_customer (customer_id, customer_name, city, country)
    SELECT top 10
        ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) + @max_id AS customer_id,
        CONCAT('Customer_', NEWID()),
        CONCAT('City_', NEWID()),
        CONCAT('Country_', NEWID())
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b

END;
GO
exec update_staging_customer

select * from dim_customer_scd2
select * from staging_customer

--DELETE FROM dim_customer_scd2;
--DBCC CHECKIDENT ('dim_customer_scd2', RESEED, 0);
