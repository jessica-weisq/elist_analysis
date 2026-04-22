-- 1. How many **refunds** were there for **each month in 2021**? What about each quarter and week?

with CTE as
  (select date_trunc(refund_ts, week) as refund_quarter, 
  case when refund_ts is not null then 1 else 0 end as refund_status
  from core.order_status
  where Extract(year from refund_ts) = 2021)
select refund_quarter, count(refund_status)
from CTE
group by 1;

-- 2. For each region, what’s the total number of customers and the total number of orders? Sort alphabetically by region

select region, count(distinct customer_id) as customer_count, count(distinct orders.id) as order_count
from core.orders
join core.customers
on orders.customer_id = customers.id
join core.geo_lookup
on customers.country_code = geo_lookup.country_code
group by 1
order by 1;

-- 3. What’s the average time to deliver for each purchase platform? 

select purchase_platform, AVG(date_diff(delivery_ts, orders.purchase_ts, day)) AS AVG_Delivery_Time
from core.orders
join core.order_status
on orders.id = order_status.order_id
group by 1;

--4. What were the top 2 regions for Macbook sales in 2020? 

select region, ROUND(SUM(usd_price),2)
from core.orders
join core.customers
on orders.customer_id = customers.id
join core.geo_lookup
on customers.country_code = geo_lookup.country_code
where Lower(product_name) like '%macbook%' and extract(year from purchase_ts) = 2020
group by 1
order by 2 desc
limit 2
