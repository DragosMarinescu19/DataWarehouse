# DataWarehouse
**Data Warehouse and Analytics Project**
Building a modern data warehouse with SQL Server, inlcuding ETL processes, data modelling and analytics.

## 📖 Project Overview

This project involves:

1. **Data Architecture**: Designing a Modern Data Warehouse Using Medallion Architecture **Bronze**, **Silver**, and **Gold** layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

#### Objective
Develop SQL-based analytics to deliver detailed insights into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

## 🏗️ Data Architecture

The data architecture for this project follows Medallion Architecture **Bronze**, **Silver**, and **Gold** layers:

1. **Bronze Layer**: Stores raw data as-is from the source systems. Data is ingested from CSV Files into SQL Server Database.
2. **Silver Layer**: This layer includes data cleansing, standardization, and normalization processes to prepare data for analysis.
3. **Gold Layer**: Houses business-ready data modeled into a star schema required for reporting and analytics.

## 📊 **OLAP Tabular Model**

To address the performance limitations of OLTP systems on large datasets, a **Tabular Model** was built in Visual Studio and deployed to SQL Server Analysis Services (SSAS). This layer provides a high-performance analytical engine for business users.

**Key features of the Tabular Model:**

* **Model**: A star schema with one central **Fact table** (over 50M rows) and **9 Dimension tables**.
* **Measures**: DAX measures were created to calculate key metrics, such as `Total Sales`, `Avg Quantity`, and other KPIs.
* **Partitioning**: Partitions were implemented on the `fact_sales` table to optimize data processing and query performance.
* **Security**: A `read-only` role was created to manage data access and governance.
* **Deployment**: The model was configured for efficient processing, and its data was integrated with **Excel** for interactive analysis.

## 🚀 **Key Learnings**

This project provides a practical comparison between OLTP and OLAP systems, highlighting key insights:

* **OLTP databases** (like SQL Server Database Engine) are excellent for transactional workloads, but analytical queries can be slow on very large tables.
* **OLAP systems** (such as SSAS Tabular) are purpose-built for analytics, offering unparalleled speed for complex aggregations and queries.
* Implementing **partitioning**, **role-based security**, and **efficient processing strategies** is crucial for building real-world, scalable BI solutions.
