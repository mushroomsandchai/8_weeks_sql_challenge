# C. Product Funnel Analysis
### Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?

```sql
with purchased_visits as (
  	select
    	distinct visit_id
    from clique_bait.events e
    join clique_bait.event_identifier ei on ei.event_type = e.event_type
    where ei.event_name = 'Purchase'
)
select
	ph.page_name as product_name,
	-- ph.product_category as product_category,
    count(case
          	when ei.event_name = 'Page View' then 1
         end) as views,
    count(case
          	when ei.event_name = 'Add to Cart' then 1
         end) as add_to_cart,
    count(case
          	when ei.event_name = 'Add to Cart' and
                 e.visit_id not in (select * from purchased_visits) then 1
          end) as abandon,
    count(case
          	when ei.event_name = 'Add to Cart' then 1
          end) - 
    count(case
          	when ei.event_name = 'Add to Cart' and 
          		 e.visit_id not in (select * from purchased_visits) then 1
          end) as purchased
from clique_bait.events e
join clique_bait.page_hierarchy ph on ph.page_id = e.page_id
join clique_bait.event_identifier ei on ei.event_type = e.event_type
where ph.product_id is not null
group by 1
```
| product_name   | views | add_to_cart | abandon | purchased |
| -------------- | ----- | ----------- | ------- | --------- |
| Abalone        | 1525  | 932         | 233     | 699       |
| Oyster         | 1568  | 943         | 217     | 726       |
| Salmon         | 1559  | 938         | 227     | 711       |
| Crab           | 1564  | 949         | 230     | 719       |
| Tuna           | 1515  | 931         | 234     | 697       |
| Lobster        | 1547  | 968         | 214     | 754       |
| Kingfish       | 1559  | 920         | 213     | 707       |
| Russian Caviar | 1563  | 946         | 249     | 697       |
| Black Truffle  | 1469  | 924         | 217     | 707       |


### Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
| product_category | views | add_to_cart | abandon | purchased |
| ---------------- | ----- | ----------- | ------- | --------- |
| Luxury           | 3032  | 1870        | 466     | 1404      |
| Shellfish        | 6204  | 3792        | 894     | 2898      |
| Fish             | 4633  | 2789        | 674     | 2115      |

## Use your 2 new output tables - answer the following questions:

### 1. Which product had the most views, cart adds and purchases?
```sql
select
	(select product_name from aggregated order by views desc limit 1) as most_views,
    (select product_name from aggregated order by add_to_cart desc limit 1)as most_card_adds,
    (select product_name from aggregated order by purchased desc limit 1)as most_purchases
```
| most_views | most_card_adds | most_purchases |
| ---------- | -------------- | -------------- |
| Oyster     | Lobster        | Lobster        |


### 2. Which product was most likely to be abandoned?
```sql
select product_name 
from aggregated
order by ((abandon * 100.0) / add_to_cart) desc
limit 1
```
| product_name   |
| -------------- |
| Russian Caviar |


### 3. Which product had the highest view to purchase percentage?
```sql
select product_name 
from aggregated
order by ((purchased * 100.0) / views) desc
limit 1
```
| product_name |
| ------------ |
| Lobster      |


### 4. What is the average conversion rate from view to cart add?
```sql
select 
    round((sum(add_to_cart) * 100) / sum(views), 2) as avg_conversion_rate 
from aggregated
```
| avg_conversion_rate |
| ------------------- |
| 60.93               |


### 5. What is the average conversion rate from cart add to purchase?
```sql
select
	round(100.0 * sum(purchased) / sum(add_to_cart), 2) as avg_conversion_rate
from aggregated
```
| avg_conversion_rate |
| ------------------- |
| 75.93               |