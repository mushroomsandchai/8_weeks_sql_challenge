# E. Bonus Challenge
Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

```sql
with recursive cte as (
  	select 
  		id, 
  		parent_id, 
  		level_text::text, 
  		level_name,
  		id as category_id,
  		level_text as category_name,
  		'' as segment_name
  	from balanced_tree.product_hierarchy
  	where parent_id is null
  	union
  	select 
  		ph.id, 
  		ph.parent_id, 
  		concat(ph.level_text, ' - ', c.level_text), 
        ph.level_name,
  		c.category_id,
  		c.category_name,
  		ph.level_text::text
    from balanced_tree.product_hierarchy ph
    join cte c on ph.parent_id = c.id
  	where ph.level_name = 'Segment'
),
cte2 as (
  	select
  		id as style_id, 
  		parent_id as segment_id, 
  		level_text as name, 
  		level_name,
  		category_id,
  		category_name,
  		segment_name,
  		'' as style_name
  	from cte
  	where level_name = 'Segment'
  	union
  	select
  		ph.id, 
  		ph.parent_id,
  		concat(ph.level_text, ' ', c.name),
  		c.level_name,
  		c.category_id,
  		c.category_name,
  		c.segment_name,
  		ph.level_text::text
 	from cte2 c
  	join balanced_tree.product_hierarchy ph on
  	ph.parent_id = c.style_id
  	where ph.level_name = 'Style'
)
select  
	pp.product_id as product_id,
    pp.price as price,
    c.name as product_name,
    c.category_id as category_id,
    c.segment_id as segment_id,
    c.style_id as style_id,
    c.category_name as category_name,
    c.segment_name as segment_name,
    c.style_name as style_name
from cte2 c
join balanced_tree.product_prices pp on
pp.id = c.style_id
order by style_id
```

| product_id | price | product_name                     | category_id | segment_id | style_id | category_name | segment_name | style_name          |
| ---------- | ----- | -------------------------------- | ----------- | ---------- | -------- | ------------- | ------------ | ------------------- |
| c4a632     | 13    | Navy Oversized Jeans - Womens    | 1           | 3          | 7        | Womens        | Jeans        | Navy Oversized      |
| e83aa3     | 32    | Black Straight Jeans - Womens    | 1           | 3          | 8        | Womens        | Jeans        | Black Straight      |
| e31d39     | 10    | Cream Relaxed Jeans - Womens     | 1           | 3          | 9        | Womens        | Jeans        | Cream Relaxed       |
| d5e9a6     | 23    | Khaki Suit Jacket - Womens       | 1           | 4          | 10       | Womens        | Jacket       | Khaki Suit          |
| 72f5d4     | 19    | Indigo Rain Jacket - Womens      | 1           | 4          | 11       | Womens        | Jacket       | Indigo Rain         |
| 9ec847     | 54    | Grey Fashion Jacket - Womens     | 1           | 4          | 12       | Womens        | Jacket       | Grey Fashion        |
| 5d267b     | 40    | White Tee Shirt - Mens           | 2           | 5          | 13       | Mens          | Shirt        | White Tee           |
| c8d436     | 10    | Teal Button Up Shirt - Mens      | 2           | 5          | 14       | Mens          | Shirt        | Teal Button Up      |
| 2a2353     | 57    | Blue Polo Shirt - Mens           | 2           | 5          | 15       | Mens          | Shirt        | Blue Polo           |
| f084eb     | 36    | Navy Solid Socks - Mens          | 2           | 6          | 16       | Mens          | Socks        | Navy Solid          |
| b9a74d     | 17    | White Striped Socks - Mens       | 2           | 6          | 17       | Mens          | Socks        | White Striped       |
| 2feb6b     | 29    | Pink Fluro Polkadot Socks - Mens | 2           | 6          | 18       | Mens          | Socks        | Pink Fluro Polkadot |
