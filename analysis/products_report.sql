create or alter view gold.report_products as
with base_query as(
	select 
		f.order_number,
		f.customer_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	from gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key=p.product_key
	where order_date is not null
), product_aggregation as (
	select 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		count(distinct order_number) as total_orders,
		sum(sales_amount) as total_sales,
		sum(quantity) as total_quantity,
		count(distinct customer_key) as total_customers,
		DATEDIFF(month,min(order_date),max(order_date)) as lifespan,
		DATEDIFF(month,max(order_date),GETDATE()) as recency,
		ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) as avg_selling_price
	from base_query
	group by product_key,
			product_name,
			category,
			subcategory,cost
)
select 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	total_orders,
	avg_selling_price,
	total_sales,
	sum(total_sales) over(partition by category) as sales_category,
	sum(total_sales) over(partition by subcategory) as sales_subcategory,
	total_quantity,
	total_customers,
	lifespan,
	recency,
	CASE WHEN total_orders=0 THEN 0
	     ELSE total_sales/total_orders 
	END as avg_order_value,

	CASE WHEN lifespan=0 THEN 0
		 ELSE total_sales/lifespan
	END as avg_monthly_revenue,

	CASE WHEN total_sales<80000 THEN 'Low-Performers'
			 WHEN total_sales between 80000 and 120000 THEN 'Mid-Range'
			 ELSE 'High-Performers'
		END as product_segments
from product_aggregation

go

select * from gold.report_products
