create or alter procedure incremental_load_sales
as
begin
set nocount on;
	
	DECLARE @LastWatermark DATETIME;

	set @LastWatermark =isnull((select LastProcessedDate from WatermarkLog Where TableName='fact_sales'),'2020-01-01');
	DECLARE @SummaryOfChanges TABLE(change VARCHAR(20));
	--some defualt date from the past if null

	--Puteam alege sa facem direct insert pentru valorile noi dar am luat in calcul si optiunea in care s-au modificat unele date
	--in staging_sales
	with delta as(
		select * from staging_sales where last_modified>@LastWatermark	
)
--Trebuie sa avem grija cand facem update pe staging_sales sa modificam si last_modified !!!
	merge fact_sales as T
	using delta as S  --luam doar datele noi sau modificate
	on T.sales_id=S.sales_id
	
	when matched then
	update set
		T.customer_id   = S.customer_id,
        T.product_id    = S.product_id,
        T.store_id      = S.store_id,
        T.employee_id   = S.employee_id,
        T.supplier_id   = S.supplier_id,
        T.currency_id   = S.currency_id,
        T.promotion_id  = S.promotion_id,
        T.channel_id    = S.channel_id,
        T.quantity      = S.quantity,
        T.sales_amount  = S.sales_amount,
        T.cost_amount   = S.cost_amount

	when not matched by target then
	INSERT (sales_id, customer_id, product_id, store_id, employee_id,
            supplier_id, currency_id, promotion_id, channel_id,
            quantity, sales_amount, cost_amount)
			 VALUES (S.sales_id, S.customer_id, S.product_id,  S.store_id, 
            S.employee_id, S.supplier_id, S.currency_id, S.promotion_id, 
            S.channel_id, S.quantity, S.sales_amount, S.cost_amount)

	output $action into @SummaryOfChanges;
	select change,count(*) as CountPerChange
	from @SummaryOfChanges group by change;

	insert into log_table select 'Incremental load','fact_sales',(select count(*) from @SummaryOfChanges where change = 'INSERT'),
	(select count(*) from @SummaryOfChanges where change = 'UPDATE')

	if exists(select * from WatermarkLog where TableName='fact_sales')
		 update WatermarkLog set LastProcessedDate=GETDATE() where TableName='fact_sales'
	else insert into WatermarkLog(TableName,LastProcessedDate) values('fact_sales',GETDATE())


		
end;
go
exec incremental_load_sales
go
select top 5 * from staging_sales --Daca fac update pe staging_sales sa fac si la last_modified=GETDATE()
select top 5 * from fact_sales
select * from log_table


	
