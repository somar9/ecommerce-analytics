--
-- Query 4: Monthly Cohort Retention Analysis
-- Business Question: Do customeres make recurrent
-- purchases..
--

with customer_orders as (
	-- One row per customer per month they ordered
	select
	c.customer_unique_id,
	DATE_TRUNC('month', o.order_purchase_timestamp) as order_month
from customers c
join orders o on c.customer_id = o.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id,
		 DATE_TRUNC('month', o.order_purchase_timestamp)
),

first_purchase as (
	-- the month each customer first bought
	select
		customer_unique_id,
		MIN(order_month) as cohort_month
	from customer_orders
	group by customer_unique_id
),

cohort_data as (
	-- Join every order back to the customer's cohort month
	-- and calculate how many months after the first purchase it was
	select
		f.cohort_month,
		co.order_month,
		EXTRACT(year from AGE(co.order_month, f.cohort_month)) * 12 + 
		EXTRACT(month from AGE(co.order_month, f.cohort_month)) as months_since_first,
		COUNT(distinct co.customer_unique_id) as num_customers
	from first_purchase f
	join customer_orders co on f.customer_unique_id = co.customer_unique_id
	group by f.cohort_month, co.order_month
),

cohort_sizes as (
	--Size of each cohort in each first purchase month
	select
		cohort_month,
		num_customers as cohort_size
	from cohort_data
	where months_since_first = 0
)

select 
	TO_CHAR(cd.cohort_month, 'YYYY-MM') as cohort,
	cs.cohort_size,
	cd.months_since_first as month_number,
	cd.num_customers as active_customers,
	ROUND(
		cd.num_customers * 100.0 / cs.cohort_size
	, 1) as retention_pct
from cohort_data cd
join cohort_sizes cs on cd.cohort_month = cs.cohort_month
where cd.cohort_month >= '2017-01-01'
	and cd.cohort_month < '2018-09-01'
	and cd.months_since_first between 0 and 12
order by cd.cohort_month, cd.months_since_first;

