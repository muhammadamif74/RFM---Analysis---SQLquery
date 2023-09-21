
-- Muhammad Amif 20/09/2023 -- 
-- Inspecting the Data -- 
SELECT *
FROM sales_data

-- Checking Unique Values -- 

Select Distinct STATUS
FROM sales_data
Select Distinct YEAR_ID
FROM sales_data
Select Distinct PRODUCTLINE	
FROM sales_data
Select Distinct COUNTRY
FROM sales_data
Select Distinct TERRITORY
FROM sales_data
Select Distinct DEALSIZE
FROM sales_data

SELECT Distinct MONTH_ID 
FROM sales_data
where year_id = 2003

-- ANALYSIS 
 -- Grouping sales by productline

SELECT PRODUCTLINE,
	ROUND(SUM(SALES),2) as Revenue
FROM sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

 -- Grouping sales by dealsize

SELECT DEALSIZE,
	ROUND(SUM(SALES),2) as Revenue
FROM sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC

 -- Grouping sales by year_ID

SELECT YEAR_ID,
	ROUND(SUM(SALES),2) as Revenue
FROM sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC

---What was the best month for sales in a specific year? 
Select  MONTH_ID, 
ROUND(SUM(sales),2) as Revenue,
COUNT(ORDERNUMBER) Frequency
FROM sales_data
WHERE YEAR_ID = 2004 -- I choose 2004 for the year
GROUP BY  MONTH_ID
ORDER BY 2 DESC


--December seems to be the month, what product do they sell in December
SELECT MONTH_ID, 
PRODUCTLINE, 
ROUND(SUM(sales),2) as Revenue,
COUNT(ORDERNUMBER)
FROM sales_data
WHERE YEAR_ID = 2004 and MONTH_ID = 12 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


 -- Create a RFM Analysis -- 

DROP TABLE IF EXISTS #rfm
;WITH rfm as 
(
	SELECT 
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM sales_data) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data)) Recency
	FROM sales_data
	GROUP BY CUSTOMERNAME
),
rfm_calc as
(

	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM rfm r
)
SELECT 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	CAST(rfm_recency as VARCHAR) + CAST(rfm_frequency as VARCHAR) + CAST(rfm_monetary  as VARCHAR)rfm_cell_string
	INTO #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'Lost_customers'  --lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'Slipping away, Cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'New customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'Potential churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'Active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'Loyal'
	END rfm_segment

FROM #rfm


--What products are most often sold together? 
--SELECT * FROM sales_data where ORDERNUMBER =  10411

SELECT DISTINCT OrderNumber, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM sales_data a
	WHERE ORDERNUMBER in 
		(

			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, count(*) rn
				FROM sales_data
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			)m
			WHERE rn = 3
		)
		and a.ORDERNUMBER = b.ORDERNUMBER
		FOR XML PATH (''))

		, 1, 1, '') ProductCodes

FROM sales_data b
ORDER BY 2 DESC

---EXTRAs----
--What city has the highest number of sales in a specific country
SELECT city, SUM(sales) Revenue
FROM sales_data
WHERE country = 'USA' -- I choose USA
GROUP BY city
ORDER BY 2 DESC

---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc

-- END --