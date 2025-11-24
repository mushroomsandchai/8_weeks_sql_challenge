DROP TABLE IF EXISTS stg_customer_orders;

CREATE TABLE stg_customer_orders (
    order_id INTEGER,
    customer_id INTEGER,
    pizza_id INTEGER,
    exclusions VARCHAR(4),
    extras VARCHAR(4),
    order_time TIMESTAMP
);

INSERT INTO stg_customer_orders (
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras,
    order_time
)
SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE 
        WHEN exclusions = '' THEN NULL
        WHEN exclusions = 'null' THEN NULL
        ELSE exclusions
    END AS exclusions,
    CASE
        WHEN extras = '' THEN NULL
        WHEN extras = 'null' THEN NULL
        ELSE extras
    END AS extras,
    order_time
FROM customer_orders;



DROP TABLE IF EXISTS stg_runner_orders;

CREATE TABLE stg_runner_orders(
	"order_id" INTEGER,
	"runner_id" INTEGER,
	"pickup_time" VARCHAR(19),
	"distance" FLOAT,
	"duration" FLOAT,
	"cancellation" VARCHAR(23)
);

INSERT INTO stg_runner_orders
	("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
SELECT
	order_id,
	runner_id,
	CASE
		WHEN pickup_time NOT ILIKE 'null' THEN TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24-MI-SS')
		ELSE NULL
	END as pickup_time,
	CASE
		WHEN distance = 'null' THEN NULL
		ELSE CAST(REGEXP_REPLACE(distance, '[a-zA-Z\s]+', '') AS FLOAT)
	END as distance,
	CASE
		WHEN duration = 'null' THEN NULL
		ELSE CAST(REGEXP_REPLACE(duration, '[a-zA-Z\s]+', '') AS FLOAT)
	END as duration,
	CASE 
		WHEN cancellation = '' THEN NULL
		WHEN cancellation = 'null' THEN NULL
		ELSE cancellation
	END as cancellation
FROM
	runner_orders;


DROP TABLE IF EXISTS dim_pizza_recipes;

CREATE TABLE dim_pizza_recipes (
	pizza_id INTEGER,
	topping_id INTEGER
);

INSERT INTO dim_pizza_recipes(pizza_id, topping_id)
SELECT
	pizza_id,
	CAST(UNNEST(STRING_TO_ARRAY(toppings, ', ')) as INTEGER)
from
	pizza_runner.pizza_recipes;


DROP TABLE IF EXISTS fact_pizza_recipes;

CREATE TABLE fact_pizza_recipes (
	pizza_id INTEGER,
	pizza_name VARCHAR(20),
	toppings VARCHAR(100)
);

INSERT INTO fact_pizza_recipes(pizza_id, pizza_name, toppings)
select
	n.pizza_id,
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
	n.pizza_name,
	n.pizza_id;