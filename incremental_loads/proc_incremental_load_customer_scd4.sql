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
      output SOURCE.customer_id,SOURCE.customer_name,SOURCE.city,SOURCE.country into @Modify(customer_id,customer_name,city,country);
    
      --WE NEED TO MAINTAIN THE HISTORY IN THE HISTORY TABLE
      insert into dim_customer_scd2(customer_id,customer_name,city,country) select customer_id,customer_name,city,country from @Modify

      DECLARE @inserted_rows int;
      DECLARE @updated_rows int;

      
      

    commit transaction
  end try
  begin catch
          rollback transaction

end;
go
exec incremental_load_customer_scd4;
