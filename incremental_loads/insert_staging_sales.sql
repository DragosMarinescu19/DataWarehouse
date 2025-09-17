
--Run this to mimmic big insert on fact table (staging_sales)
--Then run incremental_load_sales to see incremental loading
create or alter procedure insert_staging_sales
as
begin
	DECLARE @i int =(select max(sales_id) from staging_sales);
	INSERT INTO staging_sales (
            sales_id, customer_id, product_id, store_id, employee_id,
            supplier_id, currency_id, promotion_id, channel_id,
            quantity, sales_amount, cost_amount
        )
        SELECT TOP (1000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL))+@i AS sales_id,
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
    
END;
go
exec insert_staging_sales
