create or alter procedure incremental_load_customer_scd3 --SCD3
as
begin

	DECLARE @SummaryOfChanges TABLE(change VARCHAR(20));
	DECLARE @error_message nvarchar(1000);
	begin try
		begin transaction
			merge dim_customer_scd3 as target
			using staging_customer as source
			on (target.customer_id=source.customer_id)
	
			when matched and hashbytes('sha1',upper(target.curr_customer_name + target.curr_city + target.curr_country))
						  != hashbytes('sha1',upper(source.customer_name + source.city + source.country))
			then update set prev_customer_name=curr_customer_name,prev_city=curr_city,prev_country=curr_country,
							curr_customer_name=source.customer_name,curr_city=source.city,curr_country=source.country,
							from_date=GETDATE()

			when not matched by target then
			insert(customer_id,prev_customer_name,curr_customer_name,prev_city,curr_city,prev_country,curr_country)
			values(source.customer_id,null,source.customer_name,null,source.city,null,source.country)

			output $action into @SummaryOfChanges;
			select change,count(*) as CountPerChange
			from @SummaryOfChanges group by change

			insert into log_table select 'Incremental load','dim_customer_scd3',(select count(*) from @SummaryOfChanges where change = 'INSERT'),
			(select count(*) from @SummaryOfChanges where change = 'UPDATE')
		commit transaction
	end try 

	begin catch
		rollback transaction
		set @error_message=ERROR_MESSAGE()
		insert into log_table select 'Error - Incremental load: '+@error_message,'dim_customer_scd3',0,0;
	end catch
end;
go
exec incremental_load_customer_scd3

select * from log_table;
select * from dim_customer_scd3 
select * from staging_customer
insert into staging_customer(customer_id,customer_name,city,country) values(1004,'New_customer4','city4','country4');
update staging_customer set customer_name='New_customer7' where customer_id=1

