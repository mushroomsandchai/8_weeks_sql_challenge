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
	pickup_time,
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
	runner_orders