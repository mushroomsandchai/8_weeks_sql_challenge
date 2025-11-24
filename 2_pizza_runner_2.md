# B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts ```2021-01-01```)
```sql
SELECT
	TO_CHAR(registration_date, 'W') as week,
	COUNT(runner_id) as number_of_signups
FROM
	runners
GROUP BY
	1
ORDER BY
	2 DESC
```
| week | number_of_signups |
| ---- | ----------------- |
| 1    | 2                 |
| 2    | 1                 |
| 3    | 1                 |


### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT
	r.runner_id,
	ROUND(AVG(
				EXTRACT (EPOCH from (r.pickup_time - c.order_time))
			) 
		/ 60.0, 2) as average_pickup_time_min
FROM
	stg_runner_orders r
JOIN
	stg_customer_orders c ON
	c.order_id = r.order_id
WHERE
	r.pickup_time IS NOT null
GROUP BY
	1
ORDER BY
	2
```
| runner_id | average_pickup_time_min |
| --------- | ----------------------- |
|     3     |         10.47           |
|     1     |         15.68           |
|     2     |         23.72           |


### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH pizza_count as (
	SELECT
		c.order_id,
		COUNT(c.pizza_id) as cnt,
		MAX(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time))) / 60.0 as duration
	FROM
		stg_customer_orders c
	JOIN
		stg_runner_orders r ON
		r.order_id = c.order_id
	GROUP BY
		c.order_id
),
avg_time as(
	SELECT
		cnt,
		AVG(duration) as duration
	FROM
		pizza_count
	GROUP BY
		cnt
)
SELECT
	cnt,
	ROUND(duration, 2) as avg_duration
FROM
	avg_time
ORDER BY
	duration DESC,
	cnt DESC
```
| num_pizzas | avg_duration_in_min |
| ---------- | ------------------- |
|      3     |        29.28        |
|      2     |        18.38        |
|      1     |        12.36        |

```sql
SELECT
	CAST(REGR_R2(avg_duration, cnt) AS NUMERIC(10, 4)) as r2_value
FROM
	avg_duration
```
|  r2_value  |
| ---------- |
|   0.9730   |

Indicating a strong relation.

```sql
SELECT
	CAST(REGR_SLOPE(avg_duration, cnt) AS NUMERIC(10, 4)) as slope
FROM
	avg_duration
```
|    slope   |
| ---------- |
|   8.4600   |

Indicating that for every extra pizza in an order the HQ took 8.46 min longer to prepare the order.

### 4. What was the average distance travelled for each customer?
```sql
SELECT
	c.customer_id,
	ROUND(CAST(AVG(r.distance) AS NUMERIC(10, 2)), 2) as average_distance
FROM
	stg_customer_orders c
JOIN
	stg_runner_orders r ON
	r.order_id = c.order_id
GROUP BY
	c.customer_id
ORDER BY
	2, 1
```
| customer_id | average_distance |
| ----------- | ---------------- |
|     104     |      10.00       |
|     102     |      16.73       |
|     101     |      20.00       |
|     103     |      23.40       |
|     105     |      25.00       |


### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT
	MAX(duration) - MIN(duration) as difference
FROM
	stg_runner_orders
```
| difference |
| ---------- |
|     30     |


### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT
	runner_id,
	(distance * 1000.0) / (duration * 60.0) as average_speed
FROM
	stg_runner_orders
WHERE
	cancellation IS NULL
```

| runner_id | average_speed |
| --------- | ------------- |
|     1     |     12.35     |
|     1     |     11.17     |
|     1     |     10.42     |
|     2     |     9.75      |
|     3     |     11.11     |
|     2     |     16.67     |
|     2     |     26.00     |
|     1     |     16.67     |

```sql
SELECT 
	CAST(REGR_R2(average_speed, runner_id) AS NUMERIC(10, 4)) as r2 
FROM 
	avg_speed
```
|     r2     |
| ---------- |
|   0.0136   |


Indicating a weak relation.


### 7. What is the successful delivery percentage for each runner?
```sql
SELECT
	runner_id,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END) * 100 / COUNT(*) as successful
FROM
	pizza_runner.stg_runner_orders
GROUP BY
	runner_id
ORDER BY
	successful DESC
```
| runner_id | successful |
| --------- | ---------- |
|     1     |    100     |
|     2     |     75     |
|     3     |     50     |