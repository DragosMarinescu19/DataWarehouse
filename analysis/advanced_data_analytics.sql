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



