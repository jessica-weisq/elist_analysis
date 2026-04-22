-- 1. How many **refunds** were there for **each month in 2021**? What about each quarter and week?

With CTE as
  (Select date_trunc(refund_ts, week) as refund_quarter, 
  case when refund_ts is not null then 1 else 0 end as refund_status
  From core.order_status
  where Extract(year from refund_ts) = 2021)
Select refund_quarter, count(refund_status)
From CTE
Group by 1;

-- 2. For each region, what’s the total number of customers and the total number of orders? Sort alphabetically by region

Select region, Count(distinct customer_id) as customer_count, Count(distinct orders.id) as order_count
From core.orders
Join core.customers
On orders.customer_id = customers.id
Join core.geo_lookup
on customers.country_code = geo_lookup.country_code
Group by 1
order by 1;

-- 3. What’s the average time to deliver for each purchase platform? 

Select purchase_platform, AVG(date_diff(delivery_ts, orders.purchase_ts, day)) AS AVG_Delivery_Time
From core.orders
Join core.order_status
On orders.id = order_status.order_id
Group by 1;

--4. What were the top 2 regions for Macbook sales in 2020? 

Select region, SUM(usd_price)
From core.orders
Join core.customers
on orders.customer_id = customers.id
Join core.geo_lookup
on customers.country_code = geo_lookup.country_code
Where Lower(product_name) like '%macbook%' and extract(year from purchase_ts) = 2020
Group by 1
Order by 2 Desc
limit 2
