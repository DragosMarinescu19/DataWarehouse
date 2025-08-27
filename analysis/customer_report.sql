
create view gold.report_customers as
with base_query as(
	select
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name,' ',c.last_name) as customer_name,
		DATEDIFF(year,c.birthdate,GETDATE()) as age
	from gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON c.customer_key=f.customer_key
	where order_date is not null
)
,customer_aggregation as(
	select 
		customer_key,
		customer_number,
		customer_name,
		age,
		count(distinct order_number) as total_orders,
		sum(sales_amount) as total_sales,
		sum(quantity) as total_quantity,
		count(distinct product_key) as total_products,
		MAX(order_date) as last_order,
		DATEDIFF(month,min(order_date),max(order_date)) as lifespan
	from base_query
	group by customer_key,
			customer_number,
			customer_name,
			age
)
select 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE WHEN age<20 THEN '<20'
		 WHEN age between 20 and 29 THEN '20-29'
		 WHEN age between 30 and 39 THEN '30-39'
		 WHEN age between 40 and 49 THEN '40-49'
		 ELSE '50 and above'
	END as age_group,
	CASE WHEN lifespan >=12 and total_sales>5000 THEN 'VIP'
		 WHEN lifespan >=12 and total_sales<5000 THEN 'Regular'
		 ELSE 'New'
	END as customer_behavior,
	last_order,
	DATEDIFF(month,last_order,GETDATE()) as months_since_last_order,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	--Compute avg order value(AVO)
	CASE WHEN total_orders=0 THEN 0
	     ELSE total_sales/total_orders 
	END as avg_order_value,
	--Compute avg monthly spend 
	CASE WHEN lifespan=0 then 0
		 ELSE total_sales/lifespan 
	END as avg_monthly_spend
from customer_aggregation

