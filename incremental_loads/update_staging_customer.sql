
--Create procedure to mimmic slowly changing dimensions
--We run this and then incremental loading for scd2 to see the inserts and updates
CREATE OR ALTER PROCEDURE update_staging_customer
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CityCountry TABLE (
        CityID INT IDENTITY PRIMARY KEY,
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


    UPDATE sc
    SET 
        sc.customer_name = CONCAT('New_name_', NEWID()),
        sc.city = c.CityName,
        sc.country = c.CountryName
    FROM (
        SELECT TOP 100 customer_id
        FROM staging_customer
        ORDER BY NEWID()
    ) t
    JOIN staging_customer sc ON sc.customer_id = t.customer_id --join specifica exact ce randuri sa actualizeze
    CROSS APPLY ( --se aplica pentru fiecare din cele 100 de randuri
        SELECT TOP 1 CityName, CountryName
        FROM @CityCountry
        ORDER BY NEWID()
    ) c;


    DECLARE @max_id INT;
    SELECT @max_id = ISNULL(MAX(customer_id), 0) FROM staging_customer;

    ;WITH Numbers AS (
        SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM master..spt_values
    ),
    RandomCity AS (
        SELECT 
            n,
            ABS(CHECKSUM(NEWID())) % (SELECT COUNT(*) FROM @CityCountry) + 1 AS CityID
        FROM Numbers
    )
    INSERT INTO staging_customer (customer_id, customer_name, city, country)
    SELECT 
        r.n + @max_id AS customer_id,
        CONCAT('Customer_', NEWID()),
        c.CityName,
        c.CountryName
    FROM RandomCity r
    JOIN @CityCountry c ON r.CityID = c.CityID;

END;
GO

exec update_staging_customer

select * from dim_customer_scd2
select * from staging_customer

--DELETE FROM dim_customer_scd2;
--DBCC CHECKIDENT ('dim_customer_scd2', RESEED, 0);
