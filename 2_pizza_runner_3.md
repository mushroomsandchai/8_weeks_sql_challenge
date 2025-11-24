### What are the standard ingredients for each pizza?
# C. Ingredient Optimisation
```sql
select
	n.pizza_name as pizza_name,
	string_agg(t.topping_name, ', ') as ingredients		
from
	pizza_runner.pizza_names n
join
	dim_pizza_recipes s on
	s.pizza_id = n.pizza_id
join
	pizza_runner.pizza_toppings t on
	t.topping_id = s.topping_id
group by
	n.pizza_name
```
|      pizza_name     |                               ingredients                             |
| ------------------- | --------------------------------------------------------------------- |
|      Meatlovers     | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
|      Vegetarian     |       Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce      |


### 2. What was the most commonly added extra?
```sql
with unnested as (
	select
		cast(unnest(string_to_array(extras, ', ')) as integer) as extras
	from
		pizza_runner.stg_customer_orders
),
counted as (
	select
		extras,
		count(*) as cnt
	from
		unnested
	group by
		extras
),
most_common as (
	select
		extras
	from
		counted
	where
		cnt = (select max(cnt) from counted)
)
select
	t.topping_name as crowd_fav
from
	most_common m
join
	pizza_runner.pizza_toppings t on
	m.extras = t.topping_id
```
|  crowd_fav |
| ---------- |
|    Bacon   |

### 3. What was the most common exclusion?
```sql
with unnested as (
	select
		cast(unnest(string_to_array(exclusions, ', ')) as integer) as exclusions
	from
		pizza_runner.stg_customer_orders
),
counted as (
	select
		exclusions,
		count(*) as cnt
	from
		unnested
	group by
		exclusions
),
most_common as (
	select
		exclusions
	from
		counted
	where
		cnt = (select max(cnt) from counted)
)
select
	t.topping_name as least_fav
from
	most_common m
join
	pizza_runner.pizza_toppings t on
	m.exclusions = t.topping_id
```
|  least_fav  |
| ----------- |
|    Cheese   |


### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    1. Meat Lovers
    2. Meat Lovers - Exclude Beef
    3. Meat Lovers - Extra Bacon
    4. Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

```sql
with unnested as (
	select
		row_number() over(order by order_id, pizza_id) as rn,
		order_id,
		pizza_id,
		cast(unnest(string_to_array(extras, ', ')) as integer) as extras,
		cast(unnest(string_to_array(exclusions, ', ')) as integer) as exclusions
	from
		pizza_runner.stg_customer_orders
),
named as (
	select
		u.order_id,
		u.pizza_id,
		u.rn,
		n.pizza_name as pizza_name,
		string_agg(t1.topping_name, ', ' order by t1.topping_name) as extras,
		string_agg(t2.topping_name, ', ' order by t2.topping_name) as exclusions
	from
		unnested u
	join
		pizza_runner.pizza_names n on
		n.pizza_id = u.pizza_id
	left join
		pizza_runner.pizza_toppings t1 on
		u.extras = t1.topping_id
	left join
		pizza_runner.pizza_toppings t2 on
		u.exclusions = t2.topping_id
	group by
		1, 2, 3, 4
)
select
	order_id,
	pizza_id,
	concat(pizza_name, 
			case when exclusions is not null then concat( ' - Exclude ', exclusions) end,
			case when extras is not null then concat(' - Extra ', extras) end) as pizza_desc
from
	named
union all
select
	c.order_id,
	c.pizza_id,
	n.pizza_name
from
	pizza_runner.stg_customer_orders c
join
	pizza_runner.pizza_names n on
	n.pizza_id = c.pizza_id
where
	c.order_id not in (select order_id from named)
order by
	1, 2
```

| order_id | pizza_id |	                      pizza_desc                                |
| -------- | -------- | --------------------------------------------------------------- |
|     1    |     1    |                       Meatlovers                                |
|     2    |     1    |                       Meatlovers                                |
|     3    |     1    |                       Meatlovers                                |
|     3    |     2    |                       Vegetarian                                |
|     4    |     1    |               Meatlovers - Exclude Cheese                       |
|     4    |     1    |               Meatlovers - Exclude Cheese                       |
|     4    |     2    |               Vegetarian - Exclude Cheese                       |
|     5    |     1    |                Meatlovers - Extra Bacon                         |
|     6    |     2    |                       Vegetarian                                |
|     7    |     2    |                Vegetarian - Extra Bacon                         |
|     8    |     1    |                       Meatlovers                                |
|     9    |     1    |      Meatlovers - Exclude Cheese - Extra Bacon, Chicken         |
|    10    |     1 	  |	Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |


### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

