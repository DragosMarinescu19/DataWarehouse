create or alter procedure incremental_load_customer
as
begin
set nocount on;
	if not exists (select * from sys.objects where object_id=OBJECT_ID('dbo.log_table'))
	create table log_table(
		id int identity primary key,
		process varchar(100) not null,
		[table] varchar not null,
		records_inserted int not null,
		records_updated int not null
	)

	DECLARE @SummaryOfChanges TABLE(change VARCHAR(20));

	merge dim_customer as TARGET
	using staging_customer as SOURCE
	ON(TARGET.customer_id= SOURCE.customer_id)
	--When records are matched, update the records IF THERE IS ANY CHANGE 
	--We use SCD_1(pentru a mentine istoricul ,adica SCD_2 saui altele, facem insert aici in loc de update)
	when matched
	and hashbytes('sha1',upper(TARGET.customer_name+TARGET.city+TARGET.country)) != 
		hashbytes('sha1',upper(SOURCE.customer_name+SOURCE.city+SOURCE.country))
	then
	update set TARGET.customer_name=SOURCE.customer_name,
			   TARGET.city=SOURCE.city,
			   TARGET.country=SOURCE.country
	--When no records are mathed, insert the new records from source to target
	when not matched by target
	then insert (customer_id,customer_name,city,country) values (SOURCE.customer_id,SOURCE.customer_name,SOURCE.city,SOURCE.country)

	output $action into @SummaryOfChanges;
	select change,count(*) as CountPerChange
	from @SummaryOfChanges group by change;

	insert into log_table select 'Incremental load','dim_customer',(select count(*) from @SummaryOfChanges where change = 'INSERT'),
	(select count(*) from @SummaryOfChanges where change = 'UPDATE')
end;
go
exec incremental_load_customer

go
select * from log_table

select * from dim_customer where customer_id=1
select * from staging_customer where customer_id=1
