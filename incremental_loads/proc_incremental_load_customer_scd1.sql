create or alter procedure incremental_load_customer_scd1 --SCD1
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
	DECLARE @error_message nvarchar(1000);
	
	begin try
		begin transaction
			merge dim_customer as TARGET
			using staging_customer as SOURCE
			ON(TARGET.customer_id= SOURCE.customer_id)
			--When records are matched, update the records IF THERE IS ANY CHANGE 
			--We use SCD_1(pentru a mentine istoricul ,adica SCD_2 sau altele, facem insert aici in loc de update)
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
		commit transaction
	end try

	begin catch
		if @@TRANCOUNT>0 rollback
		set @error_message=ERROR_MESSAGE()
		insert into log_table select 'Error - Incremental load : '+@error_message,'dim_customer',0,0;
	end catch

end;
go
exec incremental_load_customer_scd1

go
select * from log_table

select * from dim_customer where customer_id=1
select * from staging_customer  --asta trebuie rulat ca exemplu pt a demonstra
insert into staging_customer(customer_id,customer_name,city,country) values(1002,'New_customer2','city2','country2');
update staging_customer set customer_name='New_customer3' where customer_id=1
