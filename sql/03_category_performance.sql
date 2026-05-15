--
-- Query 3: Product Category Performance
-- Business Question: what categories drive the most revenue,
-- and which have quality or delivery problems?
--

with category_metrics as (
	select
		COALESCE(t.category_name_english, 'uncategorisied') as category,
		count (distinct o.order_id) as num_orders,
		round(sum(p.payment_value)::numeric, 2) as total_revenue,
		round(avg(p.payment_value)::numeric, 2) as avg_order_value,
		round(avg(r.review_score)::numeric, 2) as avg_review_score,
		round(avg(
			extract (EPOCH from (
				o.order_delivered_customer_date - o.order_purchase_timestamp
			)) / 86400
		)::numeric, 1) as avg_delivery_days,
		COUNT(distinct oi.seller_id) as num_sellers
	from orders o
	join order_items oi on o.order_id = oi.order_id
	join order_payments p on o.order_id = p.order_id	
	join order_reviews r on o.order_id = r.order_id	
	join products pr on oi.product_id = pr.product_id
	left join product_category_translations t
		on pr.category_name = t.category_name_portuguese
	where o.order_status = 'delivered'
	group by t.category_name_english, pr.category_name
	having count(distinct o.order_id) > 100
),

category_ranked as (
	select *,
		rank() over (order by total_revenue desc) as revenue_rank,
		rank() over (order by avg_review_score desc) as quality_rank,
		rank() over (order by avg_delivery_days asc) as speed_rank,
		case
			when avg_review_score >= 4.0
			and avg_delivery_days <= 10 then 'High Quality'
			when avg_review_score < 3.5
			and avg_delivery_days > 15 then 'Problematic'
			when total_revenue > 500000 then 'High Revenue'
			else 'Average'
		end as category_label
	from category_metrics
)

select
	category,
	num_orders,
	total_revenue,
	avg_order_value,
	avg_review_score,
	avg_delivery_days,
	num_sellers,
	revenue_rank,
	quality_rank,
	speed_rank,
	category_label
from category_ranked
order by total_revenue desc;

	
	