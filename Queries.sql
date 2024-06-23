--  For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver?

SELECT 
  geo_lookup.region,
  ROUND(avg(date_diff(orders.purchase_ts, customers.created_on, DAY)),2)
FROM core.orders 
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup 
  on customers.country_code = geo_lookup.country
WHERE EXTRACT(year FROM purchase_ts)= 2022 and purchase_platform = "website" OR purchase_platform = "mobile app"
GROUP BY 1


-- What was the refund rate and refund count for each product overall? 

SELECT CASE WHEN product_name = '27in"" 4k gaming monitor'  THEN '27in 4K gaming monitor' ELSE product_name END,
  ROUND(AVG(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END),2) refund_rate,
  ROUND(SUM(CASE WHEN refund_ts IS NOT NULL THEN 1 ELSE 0 END),2) refund_count
FROM core.orders
left join core.order_status
  on orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;

-- Within each region, what is the most popular product

WITH popular_product AS (
  SELECT 
    geo_lookup.region,
    orders.product_name,
    COUNT(orders.id) as total_orders
  FROM core.orders 
  left join core.customers
    on orders.customer_id = customers.id
  left join core.geo_lookup 
    on customers.country_code = geo_lookup.country
  GROUP BY 1,2
)

select *, 
	row_number() over (partition by region order by total_orders desc) as order_ranking
from popular_product
QUALIFY row_number() over (partition by region order by total_orders desc) = 1;


-- What were the order counts, sales, and AOV for Macbooks sold in North America for each quarter across all years? 

SELECT 
  date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
  COUNT(orders.id) as order_count, 
  ROUND(SUM(orders.usd_price),2) as total_sales, 
  ROUND(AVG(orders.usd_price),2) as average_order_value 

FROM core.orders 
left join core.customers
  on orders.customer_id = customers.id
left join core.geo_lookup 
  on customers.country_code = geo_lookup.country

WHERE lower(orders.product_name) like '%macbook%'
  AND geo_lookup.region = "NA"
GROUP BY 1
ORDER BY 1 DESC;

-- What is the average quarterly order count and total sales for Macbooks sold in North America? (i.e. “For North America Macbooks, average of X units sold per quarter and Y in dollar sales per quarter")


WITH quarterly_metrics AS(
  SELECT
    date_trunc(orders.purchase_ts, quarter) as purchase_quarter,
    COUNT(orders.id) as order_count, 
    ROUND(SUM(orders.usd_price),2) as total_sales, 
    ROUND(AVG(orders.usd_price),2) as average_order_value 
  FROM core.orders 
  left join core.customers
    on orders.customer_id = customers.id
  left join core.geo_lookup 
    on customers.country_code = geo_lookup.country
  WHERE lower(orders.product_name) like '%macbook%'
    AND geo_lookup.region = "NA"
  GROUP BY 1
  ORDER BY 1 DESC
)

select 
  ROUND(avg(order_count),2) as avg_quarter_orderes,
  ROUND(avg(total_sales),2) as avg_quarter_sales
from quarterly_metrics;
