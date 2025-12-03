# C. Product Analysis
### 1. What are the top 3 products by total revenue before discount?
```sql
select product_name 
from product_agg 
order by total_revenue desc 
limit 3
```
| product_name                 |
| ---------------------------- |
| Blue Polo Shirt - Mens       |
| Grey Fashion Jacket - Womens |
| White Tee Shirt - Mens       |

### 2. What is the total quantity, revenue and discount for each segment?
```sql
select
    pd.segment_name,
    sum(s.qty) as total_quantity,
    sum(s.qty * s.price) as total_revenue,
    round(sum((s.qty * s.price) * s.discount / 100.0), 2) as total_discount,
    round(sum(s.qty * s.price) * 100.0 / (select sum(qty * price) from balanced_tree.sales), 2) as percentage_split
from balanced_tree.sales s
left join balanced_tree.product_details pd on
pd.product_id = s.prod_id
group by 1
```
| segment_name | total_quantity | total_revenue | total_discount | percentage_split |
| ------------ | -------------- | ------------- | -------------- | ---------------- |
| Shirt        | 11265          | 406143        | 49594.27       | 31.50            |
| Jeans        | 11349          | 208350        | 25343.97       | 16.16            |
| Jacket       | 11385          | 366983        | 44277.46       | 28.46            |
| Socks        | 11217          | 307977        | 37013.44       | 23.88            |


### 3. What is the top selling product for each segment?
```sql
with segment_agg as (
    select
        pd.segment_name,
        pd.product_name,
        sum(s.qty) as total_quantity,
        rank() over(partition by pd.segment_name order by sum(s.qty) desc) as rank
    from balanced_tree.sales s
    left join balanced_tree.product_details pd on
    pd.product_id = s.prod_id
    group by 1, 2
)
select
	segment_name,
    product_name
from segment_agg
where rank = 1
```
| segment_name | product_name                  |
| ------------ | ----------------------------- |
| Jacket       | Grey Fashion Jacket - Womens  |
| Jeans        | Navy Oversized Jeans - Womens |
| Shirt        | Blue Polo Shirt - Mens        |
| Socks        | Navy Solid Socks - Mens       |


### 4. What is the total quantity, revenue and discount for each category?
### 8. What is the percentage split of total revenue by category?

```sql
select
    pd.category_name,
    sum(s.qty) as total_quantity,
    sum(s.qty * s.price) as total_revenue,
    round(sum((s.qty * s.price) * s.discount / 100.0), 2) as total_discount,
    round(sum(s.qty * s.price) * 100.0 / (select sum(qty * price) from balanced_tree.sales), 2) as percentage_split
from balanced_tree.sales s
left join balanced_tree.product_details pd on
pd.product_id = s.prod_id
group by 1
```
| category_name | total_quantity | total_revenue | total_discount | percentage_split |
| ------------- | -------------- | ------------- | -------------- | ---------------- |
| Mens          | 22482          | 714120        | 86607.71       | 55.38            |
| Womens        | 22734          | 575333        | 69621.43       | 44.62            |

### 5. What is the top selling product for each category?
```sql
with category_agg as (
    select
        pd.category_name,
        pd.product_name,
        sum(s.qty) as total_quantity,
        rank() over(partition by pd.category_name order by sum(s.qty) desc) as rank
    from balanced_tree.sales s
    left join balanced_tree.product_details pd on
    pd.product_id = s.prod_id
    group by 1, 2
)
select
	category_name,
    product_name
from category_agg
where rank = 1
```
| category_name | product_name                 |
| ------------- | ---------------------------- |
| Mens          | Blue Polo Shirt - Mens       |
| Womens        | Grey Fashion Jacket - Womens |

### 6. What is the percentage split of revenue by product for each segment?
```sql
-- ### 6. What is the percentage split of revenue by product for each segment?
with prod_seg_agg as (
    select
        pd.product_name,
        pd.segment_name,
        sum(s.qty * s.price) as total_revenue
    from balanced_tree.sales s
    left join balanced_tree.product_details pd on
    pd.product_id = s.prod_id
    group by 1, 2
),
segment_total as (
  	select
  		segment_name,
  		sum(total_revenue) as total_revenue
  	from prod_seg_agg
  	group by 1
)
select
	psa.product_name,
    psa.segment_name,
    round((psa.total_revenue * 100.0) / st.total_revenue, 2) as percentage_split
from prod_seg_agg psa
join segment_total st on st.segment_name = psa.segment_name
```
| product_name                     | segment_name | percentage_split |
| -------------------------------- | ------------ | ---------------- |
| Indigo Rain Jacket - Womens      | Jacket       | 19.45            |
| Navy Solid Socks - Mens          | Socks        | 44.33            |
| Khaki Suit Jacket - Womens       | Jacket       | 23.51            |
| Navy Oversized Jeans - Womens    | Jeans        | 24.06            |
| Grey Fashion Jacket - Womens     | Jacket       | 57.03            |
| White Striped Socks - Mens       | Socks        | 20.18            |
| Teal Button Up Shirt - Mens      | Shirt        | 8.98             |
| Black Straight Jeans - Womens    | Jeans        | 58.15            |
| White Tee Shirt - Mens           | Shirt        | 37.43            |
| Blue Polo Shirt - Mens           | Shirt        | 53.60            |
| Pink Fluro Polkadot Socks - Mens | Socks        | 35.50            |
| Cream Relaxed Jeans - Womens     | Jeans        | 17.79            |

### 7. What is the percentage split of revenue by segment for each category?
```sql
with segment_agg as (
    select
        pd.category_name,
        pd.segment_name,
        sum(s.qty * s.price) as total_revenue
    from balanced_tree.sales s
    join balanced_tree.product_details pd 
        on pd.product_id = s.prod_id
    group by 1, 2
),
category_totals as (
    select 
  		category_name, 
  		sum(total_revenue) as cat_total
    from segment_agg
    group by 1
)
select
    sa.segment_name,
    sa.category_name,
    round(sa.total_revenue * 100.0 / ct.cat_total, 2) as percentage_split_within
from segment_agg sa
join category_totals ct
    on sa.category_name = ct.category_name
```
| segment_name | category_name | pct_split_within_category |
| ------------ | ------------- | ------------------------- |
| Jeans        | Womens        | 36.21                     |
| Jacket       | Womens        | 63.79                     |
| Socks        | Mens          | 43.13                     |
| Shirt        | Mens          | 56.87                     |


### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```sql
select
	pd.product_name,
    round(count(*)::numeric / (select count(distinct txn_id) from balanced_tree.sales), 4) as penetration
from balanced_tree.sales s
join balanced_tree.product_details pd on
pd.product_id = s.prod_id
group by 1
order by 2 desc
```
| product_name                     | penetration |
| -------------------------------- | ----------- |
| Navy Solid Socks - Mens          | 0.5124      |
| Grey Fashion Jacket - Womens     | 0.5100      |
| Navy Oversized Jeans - Womens    | 0.5096      |
| White Tee Shirt - Mens           | 0.5072      |
| Blue Polo Shirt - Mens           | 0.5072      |
| Pink Fluro Polkadot Socks - Mens | 0.5032      |
| Indigo Rain Jacket - Womens      | 0.5000      |
| Khaki Suit Jacket - Womens       | 0.4988      |
| Black Straight Jeans - Womens    | 0.4984      |
| White Striped Socks - Mens       | 0.4972      |
| Cream Relaxed Jeans - Womens     | 0.4972      |
| Teal Button Up Shirt - Mens      | 0.4968      |


### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
select
    pd1.product_name,
    pd2.product_name,
    pd3.product_name,
    count(*) as count
from balanced_tree.sales s1
join balanced_tree.sales s2 on s2.prod_id < s1.prod_id and s1.txn_id = s2.txn_id
join balanced_tree.sales s3 on s3.prod_id < s2.prod_id and s3.txn_id = s1.txn_id
join balanced_tree.product_details pd1 on s1.prod_id = pd1.product_id
join balanced_tree.product_details pd2 on s2.prod_id = pd2.product_id
join balanced_tree.product_details pd3 on s3.prod_id = pd3.product_id
group by 1, 2, 3
order by 4 desc
limit 10
```
| product_name                  | product_name                  | product_name                     | occurrences |
| ----------------------------- | ----------------------------- | -------------------------------- | ----------- |
| Teal Button Up Shirt - Mens   | Grey Fashion Jacket - Womens  | White Tee Shirt - Mens           | 352         |
| Navy Solid Socks - Mens       | Black Straight Jeans - Womens | Indigo Rain Jacket - Womens      | 349         |
| Black Straight Jeans - Womens | Grey Fashion Jacket - Womens  | Pink Fluro Polkadot Socks - Mens | 347         |
| Teal Button Up Shirt - Mens   | Grey Fashion Jacket - Womens  | Blue Polo Shirt - Mens           | 347         |
| Teal Button Up Shirt - Mens   | Navy Oversized Jeans - Womens | White Tee Shirt - Mens           | 347         |
| White Striped Socks - Mens    | Grey Fashion Jacket - Womens  | Blue Polo Shirt - Mens           | 347         |
| Navy Solid Socks - Mens       | Black Straight Jeans - Womens | Grey Fashion Jacket - Womens     | 345         |
| Black Straight Jeans - Womens | Grey Fashion Jacket - Womens  | Blue Polo Shirt - Mens           | 344         |
| Black Straight Jeans - Womens | Grey Fashion Jacket - Womens  | White Tee Shirt - Mens           | 344         |
| Grey Fashion Jacket - Womens  | Indigo Rain Jacket - Womens   | Blue Polo Shirt - Mens           | 342         |
