
# C. Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?
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
		row_num,
		order_id,
		pizza_id,
		cast(unnest(string_to_array(extras, ', ')) as integer) as extras,
		cast(unnest(string_to_array(exclusions, ', ')) as integer) as exclusions
	from
		stg_customer_orders
),
named as (
	select
		u.order_id,
		u.pizza_id,
		u.row_num,
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
	stg_customer_orders c
join
	pizza_runner.pizza_names n on
	n.pizza_id = c.pizza_id
where
	c.row_num not in (select row_num from named)
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
|    10    |     1    |                       Meatlovers                                |


### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

```sql
with unnested as (
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		n.toppings,
		unnest(string_to_array(o.exclusions, ', ')) as exclusions
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
),
excluded as (
	select
		row_num,
		order_id,
		pizza_id,
		case
			when exclusions is not null then trim(replace(replace(toppings, exclusions, ''), ', ,', ','), ', ')
			else toppings
		end as toppings,
		exclusions
	from
		unnested
),
exclusion_count as (
	select
		row_num,
		order_id,
		pizza_id,
		count(*) as cnt
	from
		unnested
	group by
		1, 2, 3
),
unioned as (
	select
		u.row_num,
		u.order_id,
		u.pizza_id,
		unnest(string_to_array(u.toppings, ', ')) as toppings
	from
		excluded u
	group by
		1, 2, 3, 4
	having
		count(toppings) = (select cnt from exclusion_count where order_id = u.order_id and pizza_id = u.pizza_id and row_num = u.row_num)
	union all
	select
		row_num,
		order_id,
		pizza_id,
		unnest(string_to_array(extras, ', ')) as toppings
	from
		stg_customer_orders
	where
		order_id in (select distinct order_id from excluded) and
		pizza_id in (select distinct pizza_id from excluded)
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(n.toppings, ', ')) as toppings
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
	where
		o.extras is null and o.exclusions is null
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(n.toppings, ', ')) as toppings
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
	where
		o.exclusions is null and o.extras is not null
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(o.extras, ', ')) as toppings
	from
		stg_customer_orders o
	where
		o.exclusions is null and o.extras is not null
),
aggregated as (
select
	row_num,
	order_id,
	pizza_id,
	string_agg(toppings, ', ' order by toppings) as toppings
from
	unioned
group by
	1, 2, 3
),
everything as (
	select
		u.row_num,
		u.order_id,
		u.pizza_id,
		pt.topping_name,
		count(*) as cnt,
		case
			when count(*) > 1 then concat(cast(count(*) as text), 'x', pt.topping_name)
			else pt.topping_name
		end as to_write
	from
		unioned u
	join
		pizza_runner.pizza_toppings pt on
		cast(pt.topping_id as text) = u.toppings
	group by
		1, 2, 3, 4
	order by
		cnt desc
)
select
	e.order_id,
	e.pizza_id,
	concat(n.pizza_name, ': ', string_agg(e.to_write, ', ' order by e.topping_name)) as pizza_desc
from 
	everything e
join
	pizza_runner.pizza_names n on
	n.pizza_id = e.pizza_id
group by
	e.row_num,
	e.order_id,
	e.pizza_id,
	n.pizza_name
```
| order_id | pizza_id |	                                     pizza_desc                                    |
| -------- | -------- | ----------------------------------------------------------------------------------- |
|     1    |     1    |  Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami  |
|     2    |     1    |  Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami  |
|     3    |     1    |  Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami  |
|     3    |     2    |      Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce         |
|     4    |     1    |     Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami       |
|     4    |     1    |     Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami       |
|     4    |     2    |          Vegetarian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce             |
|     5    |     1    | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
|     6    |     2    |       Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce        |
|     7    |     2    |    Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce    |
|     8    |     1    |  Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami  |
|     9    |     1    |    Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami    |
|    10    |     1 	  |  Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami  |
|    10    |     1 	  |	         Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami            |



### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
with unnested as (
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		n.toppings,
		unnest(string_to_array(o.exclusions, ', ')) as exclusions
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
),
excluded as (
	select
		row_num,
		order_id,
		pizza_id,
		case
			when exclusions is not null then trim(replace(replace(toppings, exclusions, ''), ', ,', ','), ', ')
			else toppings
		end as toppings,
		exclusions
	from
		unnested
),
exclusion_count as (
	select
		row_num,
		order_id,
		pizza_id,
		count(*) as cnt
	from
		unnested
	group by
		1, 2, 3
),
unioned as (
	select
		u.row_num,
		u.order_id,
		u.pizza_id,
		unnest(string_to_array(u.toppings, ', ')) as toppings
	from
		excluded u
	group by
		1, 2, 3, 4
	having
		count(toppings) = (select cnt from exclusion_count where order_id = u.order_id and pizza_id = u.pizza_id and row_num = u.row_num)
	union all
	select
		row_num,
		order_id,
		pizza_id,
		unnest(string_to_array(extras, ', ')) as toppings
	from
		stg_customer_orders
	where
		order_id in (select distinct order_id from excluded) and
		pizza_id in (select distinct pizza_id from excluded)
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(n.toppings, ', ')) as toppings
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
	where
		o.extras is null and o.exclusions is null
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(n.toppings, ', ')) as toppings
	from
		stg_customer_orders o
	join
		pizza_runner.pizza_recipes n on
		n.pizza_id = o.pizza_id
	where
		o.exclusions is null and o.extras is not null
	union all
	select
		o.row_num,
		o.order_id,
		o.pizza_id,
		unnest(string_to_array(o.extras, ', ')) as toppings
	from
		stg_customer_orders o
	where
		o.exclusions is null and o.extras is not null
),
aggregated as (
select
	row_num,
	order_id,
	pizza_id,
	string_agg(toppings, ', ' order by toppings) as toppings
from
	unioned
group by
	1, 2, 3
)
select
	pt.topping_name as topping_name,
	count(*) as num_times
from
	unioned u
join
	pizza_runner.pizza_toppings pt on
	cast(pt.topping_id as text) = u.toppings
group by
	pt.topping_name
order by
	num_times desc,
	topping_name
```
| topping_name | num_times |
| ------------ | --------- |
|     Bacon	   |     14    |
|   Mushrooms  |	 13    |
|    Cheese    |     11    |
|    Chicken   |     11    |
|     Beef     |     10    |
|   Pepperoni  |     10    |
|     Salami   |     10    |
|   BBQ Sauce  |     9     |
|    Onions	   |     4     |
|    Peppers   |     4     |
|   Tomatoes   |     4     |
| Tomato Sauce |     4     |