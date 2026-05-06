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

-- 3. What’s the average time to deliver for each purchase platform? https://github.com/jessica-weisq/elist_analysis/blob/main/sql_queries.sql

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

--5. What were the order counts, sales, and AOV for MacBooks sold in North America for each quarter across all years? 

select product_name, date_trunc(purchase_ts, quarter), count(*) as order_counts, SUM(usd_price) as sales,AVG(usd_price) as AOV
from core.orders
LEFT JOIN `core.customers`
On orders.customer_id = `core.customers`.id
LEFT JOIN `core.geo_lookup`
On `core.customers`.country_code = `core.geo_lookup`.country_code
Where lower(product_name) like '%macbook air laptop%' 
  AND region = 'NA'
Group by 1, 2
Order by 2 ASC


--6. For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the average highest time to deliver? 

--use orders, order_status, customer, geo_lookup table
--select region, AVG(order_ts - delivery_ts)
--filter by purchase_ts = 2022 and purchase_platform = website
--or purchase_platform = moble
--order by 1 Desc
--Limit 1


select region,
  Extract(year from `core.orders`.purchase_ts) as Purchase_year, 
  AVG(Date_diff(delivery_ts, `core.orders`.purchase_ts, day)) as time_to_deliver
from `core.orders`
join `core.order_status`
on `core.orders`.id = `core.order_status`.order_id
join `core.customers`
on `core.orders`.customer_id = `core.customers`.id
join `core.geo_lookup`
on `core.customers`.country_code = `core.geo_lookup`.country_code
where Extract(year from `core.orders`.purchase_ts) = 2022 and purchase_platform = 'website'
or purchase_platform = 'moble'
Group by 1,2
order by 1 Desc
Limit 1

--7. What was the refund rate and refund count for each product overall? 

Select
  case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as renamed_product_name,
  sum(case when refund_ts is not null then 1 else 0 end) as Refund_count,
  avg(case when refund_ts is not null then 1 else 0 end) as Refund_rate
from core.orders
join core.order_status
on orders.id = order_status.order_id
Group by 1


-- 8. Within each region, what is the most popular product? 
  With product_count_CTE AS 
  (select case when product_name = '27in"" 4k gaming monitor' then '27in 4K gaming monitor' else product_name end as product_clean,
    region, 
    COUNT(distinct `core.orders`.id) as Order_count
  from `core.orders`
  join `core.order_status`
  on `core.orders`.id = `core.order_status`.order_id
  join `core.customers`
  on `core.orders`.customer_id = `core.customers`.id
  join `core.geo_lookup`
  on `core.customers`.country_code = `core.geo_lookup`.country_code
  Group by 1,2
  Order by 3)

  Select *, row_number()over(partition by region order by Order_count Desc) As ranking
  From product_count_CTE
  Qualify row_number()over(partition by region order by Order_count Desc) = 1


-- 9.How does the time to make a purchase differ between loyalty customers vs. non-loyalty customers? 
select customers.loyalty_program, 
  round(avg(date_diff(orders.purchase_ts, customers.created_on, day)),1) as days_to_purchase,
  round(avg(date_diff(orders.purchase_ts, customers.created_on, month)),1) as months_to_purchase
from core.customers
left join core.orders
  on customers.id = orders.customer_id
group by 1
