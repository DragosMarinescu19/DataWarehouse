select 
FORMAT(order_date,'yyyy-MMM') as order_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by FORMAT(order_date,'yyyy-MMM')
order by FORMAT(order_date,'yyyy-MMM')


--How many customers were added each year
select
DATETRUNC(year,create_date) as create_date,
COUNT(customer_key) as total_customer
from gold.dim_customers
group by DATETRUNC(year,create_date)
order by DATETRUNC(year,create_date)


--Cumulative analysis
--Aggregate the data progressively over the time

--Calculate the total sales for each month 
--and the running total of sales over time
--DATETRUNC truncheaza datele la inceputul lunii sau anului respectiv
--Ex: daca e dupa luna : 28.02.2020 -> 01.02.2020
--Ne intereseaza comenzile din anumite luni indiferent de zi

select
order_date,
total_sales,
sum(total_sales) over(order by order_date) as running_total_sales,
avg(avg_price) over (order by order_date) as moving_average_price
from
(
select 
DATETRUNC(year,order_date) as order_date,
SUM(sales_amount) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group by DATETRUNC(year,order_date)
)t


--Analyze the yearly performance of products by comparing
--their sales to both the avg sales performance of the product 
--and the previous year's sales
with yearly_product_sales as(
select 
YEAR(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as curr_sales
from gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
where order_date is not null
group by YEAR(f.order_date),p.product_name
)
select 
order_year,
product_name,
curr_sales,
avg(curr_sales) over(partition by product_name) as avg_sales,
curr_sales-avg(curr_sales) over(partition by product_name) as diff_avg,
CASE WHEN curr_sales-avg(curr_sales) over(partition by product_name)>0 THEN 'Above Avg'
	 WHEN curr_sales-avg(curr_sales) over(partition by product_name)=0 THEN 'Average'
	 ELSE 'Below Avg'
END,
LAG(curr_sales) over(partition by product_name order by order_year) as py_sales,
curr_sales-LAG(curr_sales) over(partition by product_name order by order_year) as diff_py,
CASE WHEN curr_sales-LAG(curr_sales) over(partition by product_name order by order_year)>0 THEN 'Increase'
	 WHEN curr_sales-LAG(curr_sales) over(partition by product_name order by order_year)<0 THEN 'Decrease'
	 ELSE 'No Change'
END as py_change5
from yearly_product_sales
order by product_name,order_year


--Group customers into three segments based on their spending behavior
-- VIP
--Regular
--New
--And find the total nr of customers by each group

with cte as(
select 
c.customer_key,
sum(f.sales_amount) as total_spendings,
DATEDIFF(month,min(f.order_date),max(f.order_date)) as lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
group by c.customer_key
)
select 
customer_behavior,
count(customer_key) as total_customers
from(
	select 
	customer_key,
	CASE WHEN lifespan >=12 and total_spendings>5000 THEN 'VIP'
		 WHEN lifespan >=12 and total_spendings<5000 THEN 'Regular'
		 ELSE 'New'
	END as customer_behavior
	from cte
	)t 
group by customer_behavior
order by total_customers desc


--Segment products into cost ranges and count 
--how many products fall into each sement
with products_segments as(
select 
product_key,
product_name,
cost,
CASE WHEN cost<100 THEN '<100'
	 WHEN cost between 100 and 500 THEN '100-500'
	 WHEN cost between 500 and 1000 then '500-1000'
	 ELSE '>1000'
END cost_range
from gold.dim_products
)
select 
cost_range,
count(product_key) as total_products
from products_segments
group by cost_range
order by total_products desc



--Which categories contribute the most to our overall sales
with category_sales as(
select 
p.category as category,
sum(f.sales_amount) as total_sales
from gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
group by p.category
)
select category,
total_sales,
SUM(total_sales) over() as overall_sales,
CONCAT(ROUND((CAST(total_sales as FLOAT) / SUM(total_sales) over())* 100,2),'%') as percentage_of_total
from category_sales
order by total_sales desc

