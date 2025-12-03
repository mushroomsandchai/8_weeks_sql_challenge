# B. Digital Analysis
Using the available datasets - answer the following questions using a single query for each one:

### 1. How many users are there?
```sql
select count(distinct user_id) as num_users
from clique_bait.users;
```
| num_users |
| --------- |
| 500       |

### 2. How many cookies does each user have on average?
```sql
select 
	round(sum(cookie_count) / count(*), 2) as avg_cookies_per_user 
from 
	(select 
     	user_id, 
     	count(cookie_id) as cookie_count
     from clique_bait.users 
     group by user_id
    ) sub;
```
| avg_cookies_per_user |
| -------------------- |
| 3.56                 |

### 3. What is the unique number of visits by all users per month?
```sql
select 
	to_char(event_time, 'Mon'),
	count(distinct visit_id) as visit_count 
from clique_bait.events
group by 1
order by 2 desc;
```
| to_char | visit_count |
| ------- | ----------- |
| Feb     | 1488        |
| Mar     | 916         |
| Jan     | 876         |
| Apr     | 248         |
| May     | 36          |

### 4. What is the number of events for each event type?
```sql
select 
	ei.event_name, 
    count(*) num_events 
from clique_bait.events e
join clique_bait.event_identifier ei on ei.event_type = e.event_type
group by 1
order by 2 desc;
```
| event_name    | num_events |
| ------------- | ---------- |
| Page View     | 20928      |
| Add to Cart   | 8451       |
| Purchase      | 1777       |
| Ad Impression | 876        |
| Ad Click      | 702        |

### 5. What is the percentage of visits which have a purchase event?
```sql
select
	round(100.0 * 
          count(
      			case ei.event_name when 'Purchase' then 1 end) / 
          		count(distinct visit_id),
          2) as purchase_event_percentage
from clique_bait.events e
join clique_bait.event_identifier ei on e.event_type = ei.event_type;
```

| purchase_event_percentage |
| ------------------------- |
| 49.86                     |


### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql
select
    round((count(case
          	when ph.page_name = 'Checkout' and ei.event_name = 'Page View' then 1
          end) - 
    count(case
          	when ei.event_name = 'Purchase' then 1
          end)) * 100.0 /
    count(case
          	when ph.page_name = 'Checkout' and ei.event_name = 'Page View' then 1
          end), 2) as page_view_no_purchase_percentage
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier ei on e.event_type = ei.event_type
```
| page_view_no_purchase_percentage |
| -------------------------------- |
| 15.50                            |

### 7. What are the top 3 pages by number of views?
```sql
select 
	ph.page_name, 
    count(case when ei.event_name = 'Page View' then 1 end) as view_count
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier ei on e.event_type = ei.event_type
group by 1
order by 2 desc
limit 3;
```
| page_name    | view_count |
| ------------ | ---------- |
| All Products | 3174       |
| Checkout     | 2103       |
| Home Page    | 1782       |

### 8. What is the number of views and cart adds for each product category?
```sql
select 
	coalesce(ph.product_category, 'unknown') as product_category, 
    count(case when ei.event_name = 'Page View' then 1 end) as view_count, 
    count(case when ei.event_name = 'Add to Cart' then 1 end) as cart_add_count
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier ei on e.event_type = ei.event_type
group by 1
order by 2 desc;
```
| product_category | view_count | cart_add_count |
| ---------------- | ---------- | -------------- |
| unknown          | 7059       | 0              |
| Shellfish        | 6204       | 3792           |
| Fish             | 4633       | 2789           |
| Luxury           | 3032       | 1870           |

### 9. What are the top 3 products by purchases?
```sql
with purchased_visits as (
  	select
    	distinct visit_id
    from clique_bait.events e
    join clique_bait.event_identifier ei on ei.event_type = e.event_type
    where ei.event_name = 'Purchase'
)
select 
	ph.page_name as product_id, 
    count(case when ei.event_name = 'Add to Cart' and
          			e.visit_id in (select * from purchased_visits)
          	   then 1
          end) as purchase_count
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier ei on e.event_type = ei.event_type
group by 1
order by 2 desc
limit 3;
```
| product_id | purchase_count |
| ---------- | -------------- |
| Lobster    | 754            |
| Oyster     | 726            |
| Crab       | 719            |