-- In a real-world, large-scale data warehouse project, using views in the Gold layer
-- for defining fact and dimension tables is not an efficient practice. Views do not
-- physically store data; they are virtual tables that execute the underlying query
-- every time they are accessed. This can lead to severe performance issues, especially
-- with large datasets, as it forces repeated joins and calculations.

-- For this project, views are used here for simplicity and ease of analysis,
-- creating a clear star schema model with a fact and two dimensions.
-- The goal is to demonstrate the logical structure of the model, not to optimize
-- for production performance.

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
CREATE VIEW gold.dim_customers AS 
select 
	ROW_NUMBER() over (order by cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cast_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE WHEN ci.cst_gndr!='n/a' THEN ci.cst_gndr --CRM s the master for gender info
		ELSE ISNULL(ca.gen,'n/a')
	END as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
from [silver].[crm_cust_info] ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cast_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cast_key=la.cid

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
  
create view gold.dim_products as
SELECT
		ROW_NUMBER() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
	    pn.[prd_id] as product_id
	   ,pn.[prd_key] as product_number
	   ,pn.[prd_nm] as product_name
      ,pn.[cat_id] as category_id,
	    pc.cat as category,
	    pc.subcat as subcategory,
	    pc.maintenance 
      ,pn.[prd_cost] as cost
      ,pn.[prd_line] as product_line
      ,pn.[prd_start_dt] as start_date
FROM [silver].[crm_prd_info] pn
LEFT JOIN [silver].[erp_px_cat_g1v2] pc
ON pn.cat_id=pc.id
WHERE prd_end_dt is null  --Filter out all historical data


-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================
create view gold.fact_sales as
SELECT sd.[sls_ord_num] as order_number,
	    pr.product_key,
	    cu.customer_key
      ,sd.[sls_order_dt] as order_date
      ,sd.[sls_ship_dt] as shipping_date
      ,sd.[sls_due_dt] as due_date
      ,sd.[sls_sales] as sales_amount
      ,sd.[sls_quantity] as quantity
      ,sd.[sls_price] as price
FROM [silver].[crm_sales_details] sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key=pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id=cu.customer_id --We took the surrogate keys from the dimensions and put them in the fact



--Foreign key integrity (Dimensions) SHOULDN'T RETURN ANY ROWS
select * from gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key=f.customer_key
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
where c.customer_key is null
