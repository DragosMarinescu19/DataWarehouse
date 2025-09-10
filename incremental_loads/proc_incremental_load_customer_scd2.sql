create or alter procedure incremental_load_customer_scd2 --SCD2
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
	DECLARE @NewAndChangedCustomers TABLE(
		customer_id int,
		customer_name nvarchar(100),
		city nvarchar(50),
		country nvarchar(50),
		change_type nvarchar(10)
	);
	DECLARE @error_message nvarchar(1000);
	
	begin try
		begin transaction --fac inactive datele vechi
			
			merge dim_customer_scd2 as t
			using staging_customer as s
			on (t.customer_id=s.customer_id and t.is_active=1)
			
			when matched and hashbytes('sha1',upper(t.customer_name + t.city + t.country)) 
			!= hashbytes('sha1',upper(s.customer_name + s.city + s.country))
			then update set t.is_active=0,t.end_date=GETDATE()

			when not matched by target then
			insert (customer_id,customer_name,city,country) values(s.customer_id,s.customer_name,s.city,s.country)

			OUTPUT s.customer_id,s.customer_name,s.city,s.country,$action 
			into  @NewAndChangedCustomers(customer_id,customer_name,city,country,change_type);

			insert into dim_customer_scd2(customer_id,customer_name,city,country) select
			customer_id,customer_name,city,country from @NewAndChangedCustomers where change_type='UPDATE'


			declare @inserted_count int;
			declare @updated_count int;

			set @inserted_count =(select count(*) from @NewAndChangedCustomers where change_type='INSERT')
			set @updated_count =(select count(*) from @NewAndChangedCustomers where change_type='UPDATE')

			insert into log_table select 'Incremental load','dim_customer_scd2',@inserted_count,@updated_count
		commit transaction
	end try

	begin catch
		rollback transaction
		set @error_message=ERROR_MESSAGE()
		insert into log_table select 'Error - Incremental load : '+@error_message,'dim_customer_scd2',0,0;
	end catch

end;
go
exec incremental_load_customer_scd2

go
select * from log_table

select * from dim_customer_scd2 
select * from staging_customer  --asta trebuie rulat ca exemplu pt a demonstra
insert into staging_customer(customer_id,customer_name,city,country) values(1003,'New_customer3','city3','country3');
update staging_customer set customer_name='New_customer5' where customer_id=1 -- se pastreaza istoricul
