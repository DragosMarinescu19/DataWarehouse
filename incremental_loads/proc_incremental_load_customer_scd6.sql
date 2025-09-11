
create or alter procedure incremental_load_customer_scd6 --SCD6
as
begin
	begin try
		DECLARE @error_message nvarchar(1000);
		--tabela temporara pt a stoca randurile ce trb inserate
		DECLARE @ModifiedRows TABLE (
				change_type varchar(20),
				customer_id int,
				curr_customer_name nvarchar(100),
				hist_customer_name nvarchar(100),
				curr_city nvarchar(100),
				hist_city nvarchar(100),
				curr_country nvarchar(100),
				hist_country nvarchar(100)
			);

		begin transaction
			merge dim_customer_scd6 as target
			using staging_customer as source
			on (target.customer_id=source.customer_id and target.is_active=1)
			when matched and  hashbytes('sha1',upper(TARGET.curr_customer_name+TARGET.curr_city+TARGET.curr_country)) != 
						hashbytes('sha1',upper(SOURCE.customer_name+SOURCE.city+SOURCE.country))
			then 
			update set target.hist_customer_name=target.curr_customer_name,
					   target.hist_city=target.curr_city,
					   target.hist_country=target.curr_country,
					   target.curr_customer_name=source.customer_name,
					   target.curr_city=source.city,
					   target.curr_country=source.country,
					   target.end_date=GETDATE(),
					   target.is_active=0
					   
			when not matched by target then
			insert (customer_id,curr_customer_name,curr_city,curr_country) values
			(source.customer_id,source.customer_name,source.city,source.country)

			output  $action,
					source.customer_id,
					source.customer_name,
					case when $action='UPDATE' then inserted.hist_customer_name else null end,
					source.city,
					case when $action='UPDATE' then inserted.hist_city else null end,
					source.country,
					case when $action='UPDATE' then inserted.hist_country else null end
			into @ModifiedRows(change_type,customer_id, curr_customer_name, hist_customer_name,
				curr_city, hist_city, curr_country, hist_country);

			insert into dim_customer_scd6(customer_id,curr_customer_name,hist_customer_name,curr_city,hist_city,
			curr_country,hist_country)
			select m.customer_id,m.curr_customer_name,m.hist_customer_name,
			m.curr_city,m.hist_city,m.curr_country,m.hist_country from @ModifiedRows m where m.change_type='UPDATE'
			-- asa ne asiguram ca a fost update in $action

			insert into log_table select 'Incremental load','dim_customer_scd6',
			(select count(*) from @ModifiedRows where change_type='INSERT'),(select count(*) from @ModifiedRows where change_type='UPDATE')


		commit transaction
	end try
	begin catch
		rollback transaction
		set @error_message=ERROR_MESSAGE()
		insert into log_table select 'ERROR - Incremental load :'+@error_message,'dim_customer_scd6',0,0;
	end catch
end;
go
exec incremental_load_customer_scd6
select * from log_table

select * from dim_customer_scd6
select * from staging_customer  
insert into staging_customer(customer_id,customer_name,city,country) values(1003,'New_customer3','city3','country3');
update staging_customer set customer_name='New_customer8',city='New_city2' where customer_id=1 -- se pastreaza istoricul


