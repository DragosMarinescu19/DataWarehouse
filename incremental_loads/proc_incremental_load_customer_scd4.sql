--we can assume that the history table is dim_customer_scd2 and the main table is dim_customer
create or alter procedure incremental_load_customer_scd4 --SCD4
as
begin
  DECLARE @Modify TABLE (customer_id int,
	customer_name nvarchar(100),
	city nvarchar(50),
	country nvarchar(50),
	change_type nvarchar(20)
  );
  begin try
	begin transaction
		merge dim_customer as TARGET
		using staging_customer as SOURCE
		ON(TARGET.customer_id= SOURCE.customer_id)
		--When records are matched, update the records IF THERE IS ANY CHANGE 
		--We use SCD_1
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
			--WE HAVE UPDATED THE MAIN TABLE dim_customer

			output SOURCE.customer_id,SOURCE.customer_name,SOURCE.city,SOURCE.country,$action into @Modify(customer_id,customer_name,city,country,change_type);

			--WE NEED TO MAINTAIN THE HISTORY IN THE HISTORY TABLE
			insert into dim_customer_scd2(customer_id,customer_name,city,country) 
			select customer_id,customer_name,city,country from @Modify where change_type='UPDATE'

			DECLARE @inserted_rows int;
			DECLARE @updated_rows int;

			set @inserted_rows =(select count(*) from @Modify where change_type='INSERT');
			set @updated_rows =(select count(*) from @Modify where change_type='UPDATE');

			insert into log_table select 'Incremental load','dim_customer_scd4',@inserted_rows,@updated_rows
		commit transaction
	end try
	begin catch
			rollback transaction
			DECLARE @error_message nvarchar(1000);
			set @error_message=ERROR_MESSAGE();
			insert into log_table select 'ERROR - Incremental load :'+@error_message,'dim_customer_scd4',0,0;
	end catch

end;
go
exec incremental_load_customer_scd4;

select * from log_table

select * from dim_customer
select * from dim_customer_scd2
select * from staging_customer  --asta trebuie rulat ca exemplu pt a demonstra
insert into staging_customer(customer_id,customer_name,city,country) values(1003,'New_customer3','city3','country3');
update staging_customer set customer_name='New_customer5' where customer_id=1 -- se pastreaza istoricul
