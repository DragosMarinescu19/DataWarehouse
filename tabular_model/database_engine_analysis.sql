-- Vanzari totale pe categorie
SELECT p.category, SUM(f.sales_amount) AS TotalSales
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.category;
--create index IDX_dim_product_category on dim_product(category)

-- Vanzari totale pe an si luna
SELECT t.year, t.month, SUM(f.sales_amount) AS TotalSales
FROM fact_sales f
JOIN dim_time t ON f.time_id = t.time_id
GROUP BY t.year, t.month;

-- Top 10 clienti dupa vanzari
SELECT TOP 10 c.customer_name, SUM(f.sales_amount) AS TotalSales,SUM(f.quantity) AS TotalQuantity
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY TotalSales DESC;

SELECT 
    t.year,
    t.month,
    AVG(f.quantity) AS AvgQuantity
FROM fact_sales f
JOIN dim_time t ON f.time_id = t.time_id
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

SELECT 
    pr.promotion_name,
    SUM(f.sales_amount) AS TotalSales,
    SUM(f.quantity) AS TotalQuantity,
    AVG(f.quantity) AS AvgQuantity
FROM fact_sales f
JOIN dim_promotion pr ON f.promotion_id = pr.promotion_id
GROUP BY pr.promotion_name;

SELECT 
c.channel_name,
SUM(s.sales_amount),
AVG(s.sales_amount)
FROM fact_sales s
LEFT JOIN dim_channel c
ON s.channel_id=c.channel_id
GROUP BY c.channel_name
order by channel_name,SUM(s.sales_amount) DESC

select * from fact_sales where sales_id=4408703
update fact_sales set sales_amount=sales_amount+1000 where sales_id=4408703

drop index CCI_fact_sales on fact_sales
CREATE CLUSTERED COLUMNSTORE INDEX CCI_fact_sales ON fact_sales;
alter table fact_sales drop constraint [PK__fact_sal__995B8585828EDD88]
alter table fact_sales add constraint PK_fact_sales primary key nonclustered(sales_id)
