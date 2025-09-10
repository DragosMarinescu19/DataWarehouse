create or alter procedure incremental_load_sales
as
begin
set nocount on;
	
	DECLARE @LastWatermark DATETIME;
	DECLARE @error_message nvarchar(1000);
	
	set @LastWatermark =isnull((select LastProcessedDate from WatermarkLog Where TableName='fact_sales'),'2020-01-01');
	DECLARE @rows_inserted int;
	--some defualt date from the past if null

	--Puteam alege sa facem direct insert pentru valorile noi in staging_sales fara update

	begin try	
		begin transaction
			insert into fact_sales select sales_id, customer_id, product_id, store_id, employee_id,
					supplier_id, currency_id, promotion_id, channel_id, quantity, sales_amount, cost_amount 
						from staging_sales where last_modified>@LastWatermark

			set @rows_inserted=@@ROWCOUNT;

			insert into log_table select 'Incremental load','fact_sales',@rows_inserted,0;

			if exists(select * from WatermarkLog where TableName='fact_sales')
				 update WatermarkLog set LastProcessedDate=GETDATE() where TableName='fact_sales'
			else insert into WatermarkLog(TableName,LastProcessedDate) values('fact_sales',GETDATE())
		commit transaction

	end try

	begin catch
		rollback
		set @error_message=ERROR_MESSAGE()
		insert into log_table select 'Error - incremental load : '+@error_message,'fact_sales',0,0;
	end catch
		
end;
go
exec incremental_load_sales
go
select top 5 * from staging_sales 
select top 5 * from fact_sales
select * from log_table
insert into staging_sales(sales_id, customer_id, product_id, store_id, employee_id,
            supplier_id, currency_id, promotion_id, channel_id, quantity, sales_amount, cost_amount)
			select(select max(sales_id) +1 from fact_sales),13,100,345,890,1000,1,1,234,456,678,90;

select max(sales_id) from staging_sales
select max(sales_id) from fact_sales
	
