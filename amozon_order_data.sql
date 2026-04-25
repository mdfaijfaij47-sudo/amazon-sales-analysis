create database amazon_order_data;
select * from order_dataset;
select * from customer_table;
select * from sale_target;
-- ---CORRECT DATE FORMATE FROM ORDER_DATESET (cleaning part )
describe order_dataset;
select str_to_date(`order datetime`,"%d-%m-%Y %H:%i:%s") AS order_date
from order_dataset; 
ALTER TABLE order_dataset
ADD clean_datetime DATETIME;
SET SQL_SAFE_UPDATES = 0;

UPDATE order_dataset
SET clean_datetime = STR_TO_DATE(`order datetime`, '%d-%m-%Y %H:%i:%s');
commit;
select * from order_dataset;
alter table order_dataset 
drop column `Order Datetime`;
ALTER TABLE order_dataset
ADD order_day INT,
ADD order_month INT,
ADD order_time TIME;

SET SQL_SAFE_UPDATES = 0;

UPDATE order_dataset
SET 
  order_day = DAY(clean_datetime),
  order_month = MONTH(clean_datetime),
  order_time = TIME(clean_datetime);
  select * from order_dataset;

--   Replace missing Order Source by the “Other” mode
  select * from	 order_dataset;
  select `order source` from order_dataset
where  `order source` = '';


update order_dataset 
set `order source` = "other"
where `order source` = '';
commit;

SET SQL_SAFE_UPDATES = 0;


update order_dataset o 
join customer_table	c 
on o.`customer id` = c.`customer id`
set o.`customer country` = c.`customer country`
where o.`customer country` = '';
commit;
select * from customer_table
where age = '';
select *, round(avg(age) over (order by `customer id`ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING),0) as moving_avrage
from customer_table;
SET SQL_SAFE_UPDATES = 0;

UPDATE customer_table t
JOIN (
    SELECT 
        `customer id`,
        ROUND(
            AVG(age) OVER (
                ORDER BY `customer id`
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            ), 0
        ) AS moving_avg
    FROM customer_table
) m
ON t.`customer id` = m.`customer id`
SET t.age = m.moving_avg
WHERE t.age = '';
commit;

-- ---analysis

-- find total order 
select count(*) as total_order from order_dataset;

-- find total value
select sum(`order value`) as total_value from order_dataset;

-- Monthly Order Trend

select case when order_month = 1 then 'jan' 
			when order_month = 2 then 'feb'
            when order_month = 3 then 'mar'
            when order_month = 4 then 'apr'
            when order_month = 5 then 'may'
            when order_month = 6 then 'jun'
            when order_month = 7 then 'jul'
            when order_month = 8 then 'aug'
            when order_month = 9 then 'sep'
            when order_month = 10 then 'oct'
            when order_month = 11 then 'nov'
            when order_month = 12 then 'dec'
            end as month ,
     count(`Order ID`) as cout_of_order,
	round(avg(`order value`),2) as avg_order_value
from order_dataset
group by order_month
order by cout_of_order desc;

-- November has highest total orders as well as avg_order_value 
-- November is the strongest performing month, with both high customer volume and higher spending per order.



-- Orders in 2nd Half of Year vs order in 1st half of year 

-- 1st half of year
select count(*) as total_order,
     sum(`Order Value`) as total_value
   from order_dataset
   where order_month  between 1 and 6;
   
-- 2nd Half of Year
select count(*) as total_order,
     sum(`Order Value`) as total_value
   from order_dataset
   where order_month  between 7 and 12;
--    
--    Order volume is almost equal in both halves of the year
-- Revenue is also very similar, with a slight decrease in the second half


-- Indian Customers Orders count  and order values 
select `Customer ID`,
  count(*) as  total_ind_order,
  sum(`Order Value`) as total_ind_order_value
from order_dataset
where `Customer Country` = "india"
group by `customer id`
order by total_ind_order_value desc;

-- Customer ID 326 has the highest total order value (₹31,554) with 4 orders
-- Customer IDs 1109 and 327 have the highest number of orders (5 each), but lower total order value (₹18,809 and ₹22,637)


-- country wise order values and order count 

select `customer country`,
  count(*) as  total_order,
  sum(`Order Value`) as total_order_value
from order_dataset
group by  `customer country`
order by total_order_value desc;

-- The United States (USA) emerged as the top-performing country in terms of both total
-- revenue and order volume. It recorded the highest number of orders (888) and
-- generated a total revenue of 4,274,438, significantly outperforming other regions.

-- Whatsapp Orders Avg Value

select `Order Source`,
     count(*) as total_order,
    round(avg(`Order Value`),2) as avg_order_value
 from order_dataset
 where `Order Source` = "whatsapp"
 group by `Order Source`;
 
--  whatsapp generated a total_order 633 and avg_order_value 4760.82
 
--  count total order,avrage of order value and total order value for each order source

select `Order Source`,
     count(*) as total_order,
    round(avg(`Order Value`),2) as avg_order_value,
    sum(`Order value`) as total_order
 from order_dataset
 group by `Order Source`;
 
-- The Website channel generates the highest total number of orders, 
-- making it the primary driver of order volume.
-- The App channel delivers the highest average order value (AOV), 
-- indicating that app users tend to make higher-value purchases.

-- Orders after 15 June 2023 & Age > 30

select count(*) as total_order,
sum(o.`Order Value`) as total_value
from order_dataset as o join customer_table as c
on o.`customer id` = c.`customer id` 
where o.clean_datetime > "2023-06-15"
and c.age > 30 ;

-- Hourly Order Trend

select date_format(order_time, '%r') as hour,
       count(*) as total_order,
       sum(`Order Value`) as total_value
       from order_dataset
       group by order_time
       order by total_value desc;
       
--        12:34 AM appears to be a peak transaction time, where customers are highly active.
-- High order value at this time suggests late-night buyers are placing high-value or impulse purchases.
       
-- Day of Month Trend (orders)

select order_day,
      count(`order id`) as total_order
      from order_dataset
      group by order_day
      order by total_order desc;
      
--       Customer activity is not evenly distributed across the month.
-- Day 6 spike may indicate early-month behavior such as:
-- Salary inflow impact
-- Beginning-of-month purchasing cycle
-- Day 26 spike may indicate:
-- End-of-month urgency buying
-- Discounts, offers, or budget utilization before month end
      
--       Age Group Analysis

SELECT 
    CASE 
        WHEN age < 20 THEN '<20'
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 40 AND 50 THEN '40-50'
        ELSE '50+'
    END AS age_group,
    COUNT(o.`order id`) AS total_orders,
    SUM(o.`order value`) AS total_value
FROM customer_table c
JOIN order_dataset o 
ON c.`customer id` = o.`customer id`
 GROUP BY 
    CASE 
        WHEN age < 20 THEN '<20'
        WHEN age BETWEEN 20 AND 30 THEN '20-30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 40 AND 50 THEN '40-50'
        ELSE '50+'
    END;
    
--     The 50+ age group contributes the highest total order value as well as a strong number of total orders, 
--     making it one of the most valuable customer segments in the business.
      
      

-- Top Customers

SELECT 
    c.`customer id`,
    SUM(o.`order value`) AS total_spent,
    COUNT(o.`order id`) AS total_orders
FROM customer_table c
JOIN order_dataset o 
ON c.`customer id` = o.`customer id`
GROUP BY c.`customer id`
ORDER BY total_spent DESC
LIMIT 10;

-- Customer ID 214 stands out as the top-performing customer, 
-- contributing both the highest total number of orders and the highest total order value across all customers.



























