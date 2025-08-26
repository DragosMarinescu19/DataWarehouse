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


