-- CUSTOMER RETAIL ANALYSIS --

-- Creating table --
CREATE TABLE online_retail (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATE,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country VARCHAR(100)
);

-- Checking for duplicates --
SELECT COUNT(*) FROM online_retail -- total rows 540455

SELECT invoiceno, stockcode, COUNT(*)
	FROM online_retail 
	GROUP BY invoiceno, stockcode
	HAVING COUNT(*)>1;
 
-- Removing duplicates--
WITH Duplicates AS(
SELECT * ,
	ROW_NUMBER() OVER (PARTITION BY invoiceNo, stockcode) AS Dups
FROM online_retail)

SELECT * FROM duplicates 
WHERE dups = 2;

-- Creating a new table with deduplicate values --

CREATE TABLE transactions AS (
	WITH Duplicates AS(
	SELECT * ,
	ROW_NUMBER() OVER (PARTITION BY invoiceNo, stockcode) AS Dups
	FROM online_retail)
	
	SELECT * FROM duplicates 
	WHERE dups = 1
);

-- New table created with unique records --

-- Records with Cancelled Invoices --

SELECT * FROM transactions
WHERE invoiceno LIKE '%C%'

-- Removing records with Cancelled Invoices --
	
DELETE FROM transactions 
WHERE invoiceno LIKE '%C%';

SELECT * FROM transactions

-- Records with missing customerid --

SELECT * FROM transactions
WHERE customerid IS NULL

-- Creating a table with valid Customers --

CREATE TABLE retail AS
SELECT *
FROM transactions
WHERE CustomerID IS NOT NULL;

-- New table retail --

SELECT * FROM retail;

-- Customer Metrics --

-- Unique Customers --
 SELECT COUNT(DISTINCT customerid) AS unique_customers
FROM retail;

-- Average spend per customer --

WITH cus_total_spend AS (
SELECT customerid,
		SUM(unitprice * quantity) AS total_spend
FROM retail
GROUP BY customerid)

SELECT ROUND(AVG(total_spend),0) AS average_value
FROM cus_total_spend;

-- Averge order value per customer --

WITH spend AS(
SELECT 
	customerid, invoiceno, SUM(unitprice * quantity) AS spend_per_order
FROM retail
GROUP BY customerid, invoiceno
ORDER BY customerid )

SELECT customerid, ROUND(AVG(spend_per_order),0) AS avg_spend_per_customer
FROM spend
GROUP BY customerid
ORDER BY customerid
;

-- TOP 10 customers --
SELECT customerid,
		SUM(unitprice * quantity) AS total_spend
FROM retail
GROUP BY customerid
ORDER BY 2 DESC
LIMIT 10
;

-- Product Insights --

--TOP 10 products by qty sold --
SELECT stockcode, SUM(quantity) AS total_qty
FROM retail
GROUP BY stockcode
ORDER BY total_qty DESC
LIMIT 10;

-- TOP Product by revenue --

SELECT stockcode, SUM(quantity * unitprice) AS total_rev
FROM retail
GROUP BY stockcode
ORDER BY total_rev DESC
LIMIT 1;

-- Revenue Trends --
-- Monthly Reveune Trends --

SELECT EXTRACT(year from invoicedate) AS yr,
	EXTRACT(month from invoicedate) AS mon,
	SUM(unitprice * quantity)AS total_revenue
FROM retail
GROUP BY EXTRACT(month from invoicedate), EXTRACT(year from invoicedate)
ORDER BY 1;

-- Average Basket Size --
WITH avg_basket_size AS (
SELECT invoiceno, SUM(quantity) AS qty_sold
FROM retail
GROUP BY invoiceno
)

SELECT AVG(qty_sold) AS average
FROM avg_basket_Size

-- Repeaters VS one-time customers --
WITH one_time_cus AS (	
SELECT customerid, COUNT(DISTINCT invoiceno) AS total_invoice
	FROM retail
	GROUP BY customerid)
SELECT COUNT(*) AS total_one_time_customer FROM one_time_cus
WHERE total_invoice =1


-- customers with highest no of invoices --
SELECT 
	customerid, COUNT(DISTINCT invoiceno) AS total_invoices
FROM retail
GROUP BY customerid
ORDER BY COUNT(DISTINCT invoiceno) DESC
LIMIT 1;


-- TOP 3 customers each month --

WITH customer_ranking AS (
SELECT EXTRACT(year from invoicedate) AS yr,
	EXTRACT(month from invoicedate) AS mon,
	customerid, 
	SUM(quantity * unitprice) AS total_spend,
	RANK() OVER (PARTITION BY EXTRACT(year from invoicedate), EXTRACT(month from invoicedate) ORDER BY SUM(quantity * unitprice) DESC) AS ranking
FROM retail
GROUP BY
		EXTRACT(year from invoicedate),
		EXTRACT(month from invoicedate), customerid
)

SELECT *
FROM customer_ranking
WHERE 
ranking < 4
	ORDER BY 1 ,2 , 5 ;

-- Customer Segmentation on bases of Total Spend --
SELECT *, CASE
			WHEN total_spend < 50000 THEN 'Silver'
			WHEN total_spend BETWEEN  50000 AND 150000 THEN 'Gold'
			ELSE 'Diamond'
	END AS customer_tier
	FROM(
	
SELECT customerid, SUM(quantity * unitprice) AS total_spend 
FROM retail
GROUP BY customerid) t