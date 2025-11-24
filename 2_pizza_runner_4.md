# D. Pricing and Ratings
### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
with eligible_orders as (
	select 
		order_id 
	from 
		pizza_runner.stg_runner_orders where cancellation is null or cancellation = 'Customer Cancellation'
)
select
	sum(
		case
			when pizza_id = 1 then 12
			else 10
		end
	) as total_revenue
from
	stg_customer_orders
where
	order_id in (select * from eligible_orders)
```
|  total_revenue  |
| --------------- |
|       150       |


### 2. What if there was an additional $1 charge for any pizza extras?

    Add cheese is $1 extra
```sql
with eligible_orders as (
	select 
		order_id 
	from 
		pizza_runner.stg_runner_orders where cancellation is null or cancellation = 'Customer Cancellation'
),
num_extras as (
	select
		row_num,
		order_id,
		pizza_id,
		count(*) as cnt
	from
		(
			select
				row_num,
				order_id,
				pizza_id,
				unnest(string_to_array(extras, ', ')) as extras
			from
				stg_customer_orders
		) d
	group by
		1, 2, 3
)
select
	sum(
		case
			when o.pizza_id = 1 then 12 + coalesce(e.cnt, 0)
			else 10 + coalesce(e.cnt, 0)
		end
	)
from
	stg_customer_orders o
left join
	num_extras e on
	e.order_id = o.order_id and
	e.pizza_id = o.pizza_id and
	o.row_num = e.row_num
where
	o.order_id in (select * from eligible_orders)
```
|  total_revenue  |
| --------------- |
|       156       |


### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql

```