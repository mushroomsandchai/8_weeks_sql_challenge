# A. Pizza Metrics
### 1. How many pizzas were ordered?
```sql
SELECT
	COUNT(pizza_id) as num_orders
FROM
	customer_orders
```
| num_orders |
| ---------- |
| 14         |


### 2. How many unique customer orders were made?
```sql
SELECT
	COUNT(DISTINCT order_id) as unique_orders
FROM
	customer_orders
```
| unique_orders |
| ------------- |
| 10            |


### 3. How many successful orders were delivered by each runner?
```sql
SELECT
	runner_id,
    COUNT(order_id) as num_delivered
FROM
	stg_runner_orders
WHERE
    cancellation is NULL
GROUP BY
	runner_id
ORDER BY
	num_delivered DESC
```
| runner_id | num_delivered |
| --------- | ------------- |
| 1         | 4             |
| 2         | 3             |
| 3         | 1             |


### 4. How many of each type of pizza was delivered?
```sql
SELECT
	pizza_id,
    count(pizza_id) as num_delivered
FROM
	customer_orders
WHERE
	order_id in (SELECT order_id FROM stg_runner_orders WHERE cancellation is null)
GROUP BY
	pizza_id
ORDER BY
	num_delivered DESC
```
| pizza_id | num_delivered |
| -------- | ------------- |
| 1        | 9             |
| 2        | 3             |


### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT
	co.customer_id,
    COALESCE(SUM(
      	CASE
    		WHEN pn.pizza_name = 'Meatlovers' then 1
      	END
    ), 0) as meatlovers,
    COALESCE(SUM(
      	CASE
    		WHEN pn.pizza_name = 'Vegetarian' then 1
      	END
    ), 0) as vegetarian     
FROM
	customer_orders co
JOIN
	pizza_names pn ON
    pn.pizza_id = co.pizza_id
GROUP BY
	co.customer_id
ORDER BY
	co.customer_id
```
| customer_id | meatlovers | vegetarian |
| ----------- | ---------- | ---------- |
| 101         | 2          | 1          |
| 102         | 2          | 1          |
| 103         | 3          | 1          |
| 104         | 3          | 0          |
| 105         | 0          | 1          |


### 6. What was the maximum number of pizzas delivered in a single order?
```sql
WITH pizza_count_by_order AS (
    SELECT
        order_id,
        COUNT(pizza_id) as cnt
    FROM
        customer_orders
    WHERE
        order_id in (SELECT order_id FROM stg_runner_orders WHERE cancellation is null)
    GROUP BY
        order_id
)
SELECT
	MAX(cnt) as maximum_number_of_pizza_by_order
FROM
	pizza_count_by_order
```
| maximum_number_of_pizza_by_order |
| -------------------------------- |
| 3                                |


### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
	customer_id,
	COALESCE(
        COUNT(
                CASE
                    WHEN exclusions IS NOT null OR
                    extras IS NOT null THEN 1
                END
			), 0) as changed,
	COALESCE(
		COUNT(
                CASE
                    WHEN exclusions IS null AND
                    extras IS null THEN 1
                END
            ), 0) as unchanged
FROM
	stg_customer_orders
WHERE
	order_id in (SELECT order_id FROM stg_runner_orders WHERE cancellation IS null)
GROUP BY
	customer_id
```
| customer_id | changed | unchanged |
| ----------- | ------- | --------- |
|     101     |    0    |     0     |
|     102     |    0    |     0     |
|     103     |    3    |     0     |
|     104     |    2    |     0     |
|     105     |    1    |     0     |



### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT
	COUNT(pizza_id) as both_exclusions_and_extras
FROM
	stg_customer_orders
WHERE
	order_id in (SELECT order_id FROM stg_runner_orders WHERE cancellation IS null) AND
    exclusions is not null AND
    extras is not null
```
| both_exclusions_and_extras |
| -------------------------- |
| 4                          |


### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
    EXTRACT(HOUR FROM order_time) as hour,
    COUNT(pizza_id) as num_per_hour,
	ROUND(
			COUNT(pizza_id) * 100.0 / 
			SUM(COUNT(pizza_id)) OVER()
			, 2) as volume_of_pizza
FROM
    stg_customer_orders
GROUP BY
    EXTRACT(HOUR FROM order_time)
ORDER BY
	volume_of_pizza DESC,
	hour
```
| hour | num_per_hour | volume_of_pizza |
| ---- | ------------ | --------------- |
| 13   | 3            | 21.43           |
| 18   | 3            | 21.43           |
| 21   | 3            | 21.43           |
| 23   | 3            | 21.43           |
| 11   | 1            | 7.14            |
| 19   | 1            | 7.14            |


### 10. What was the volume of orders for each day of the week?
```sql
SELECT
    TO_CHAR(order_time, 'DAY') as day,
    COUNT(pizza_id) as num_per_day,
	ROUND(
			COUNT(pizza_id) * 100.0 / 
			SUM(COUNT(pizza_id)) OVER()
			, 2) as volume_of_pizza
FROM
    stg_customer_orders
GROUP BY
    TO_CHAR(order_time, 'DAY')
ORDER BY
	volume_of_pizza DESC,
	day
```
| day       | num_per_day | volume_of_pizza |
| --------- | ----------- | --------------- |
| SATURDAY  | 5           | 35.71           |
| WEDNESDAY | 5           | 35.71           |
| THURSDAY  | 3           | 21.43           |
| FRIDAY    | 1           | 7.14            |