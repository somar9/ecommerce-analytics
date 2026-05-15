--
-- Query 2: Revnue funnel and onder status breakdown
-- Business question: where are orders dropping out, and what
-- is teh cost of the failed or incomplete deliveries to the business?	 
--
with order_summary as (
	select 
		o.order_id,
		o.order_status,
		o.order_purchase_timestamp,
		o.order_approved_at,
		o.order_delivered_carrier_date,
		o.order_delivered_customer_date,
		o.order_estimated_delivery_date,
		SUM(p.payment_value) as order_value,
		
		
		-- Time between stages in hours
		extract (EPOCH from (
			o.order_approved_at - o.order_purchase_timestamp
		)) / 3600 											as hours_to_approval,
		
		extract (EPOCH from (
			o.order_delivered_carrier_date - o.order_approved_at
		)) / 3600											as hours_to_dispatch,
		
		extract (EPOCH from (
			o.order_delivered_customer_date - o.order_delivered_carrier_date
		)) / 3600											as hours_to_delivery,
		
		case
			when o.order_delivered_customer_date > o.order_estimated_delivery_date
			then 1 else 0
		end													as is_late
		
		
		from orders o
		join order_payments p on o.order_id = p.order_id
		group by o.order_id, o.order_status,
				 o.order_purchase_timestamp, o.order_approved_at,
             o.order_delivered_carrier_date, o.order_delivered_customer_date,
             o.order_estimated_delivery_date
),

funnel as (
	select
		order_status,
		count(*)	as num_orders,
		round(sum(order_value)::numeric, 2)	as total_revenue,
		round(avg(order_value):: numeric, 2)	as avg_order_value,
		round(
			COUNT(*) * 100.0 / sum(count(*)) over ()
		, 2) 	as pct_of_all_orders
	from order_summary
	group by order_status
),

delivery_performance as (
	select 
		SUM(is_late)	as late_deliveries,
		COUNT(*)	as total_delivered,
		ROUND(AVG(hours_to_approval)::numeric, 1)	as avg_hours_to_approval, 
		ROUND(AVG(hours_to_dispatch)::numeric, 1)	as avg_hours_to_dispatch, 
		ROUND(AVG(hours_to_delivery)::numeric, 1)	as avg_hours_to_delivery, 
		ROUND(
			SUM(is_late) * 100 / COUNT(*)
		, 2) 	as pct_late
	from order_summary
	where order_status = 'delivered'
)
	
-- run one at a time to see both results
	
-- funnel breakdown
--select * from funnel order by num_orders desc;

-- Delivery performance
SELECT * FROM delivery_performance;

