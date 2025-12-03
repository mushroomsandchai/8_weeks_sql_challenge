# B. Bonus Questions
### 1. Join All The Things
```sql
SELECT
    s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
        WHEN s.order_date < m.join_date or m.join_date is null THEN 'N'
        ELSE 'Y'
    END as member
FROM
    sales s
JOIN
    menu me on
    me.product_id = s.product_id
LEFT JOIN
    members m on
    m.customer_id = s.customer_id
ORDER BY
    s.customer_id,
    s.order_date,
    me.product_name
```

| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | ------------ | ----- | ------ |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |


### 2. Rank All The Things
```sql
SELECT
    s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
            WHEN s.order_date < m.join_date or m.join_date is null THEN 'N'
            ELSE 'Y'
    END as member,
    CASE
        WHEN s.order_date >= m.JOIN_date THEN 
              RANK() OVER(
                            PARTITION BY s.customer_id 
                            ORDER BY 
                              CASE
                                  WHEN s.order_date >= m.join_date THEN s.order_date 
                              END
                          )
            ELSE null
    END as rank
FROM
    sales s
JOIN
    menu me on
    me.product_id = s.product_id
LEFT JOIN
    members m on
    m.customer_id = s.customer_id
ORDER BY
    s.customer_id,
    s.order_date,
    me.product_name
```

| customer_id | order_date | product_name | price | member | rank |
| ----------- | ---------- | ------------ | ----- | ------ | ---- |
| A           | 2021-01-01 | curry        | 15    | N      | null |
| A           | 2021-01-01 | sushi        | 10    | N      | null |
| A           | 2021-01-07 | curry        | 15    | Y      | 1    |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2    |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3    |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3    |
| B           | 2021-01-01 | curry        | 15    | N      | null |
| B           | 2021-01-02 | curry        | 15    | N      | null |
| B           | 2021-01-04 | sushi        | 10    | N      | null |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1    |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2    |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3    |
| C           | 2021-01-01 | ramen        | 12    | N      | null |
| C           | 2021-01-01 | ramen        | 12    | N      | null |
| C           | 2021-01-07 | ramen        | 12    | N      | null |