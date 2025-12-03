# A. Customer Nodes Exploration
### 1. How many unique nodes are there on the Data Bank system?
```sql
select 
    count(distinct(region_id, node_id)) as cnt 
from 
    customer_nodes;
```
| count |
| ----- |
| 25    |

### 2. What is the number of nodes per region?
```sql
select 
	r.region_name,
	count(distinct node_id) as cnt 
from 
	customer_nodes c
join
	regions r on
    r.region_id = c.region_id
group by
	r.region_name
order by
	cnt desc,
    r.region_name;
```
| region_name | cnt |
| ----------- | --- |
| Africa      | 5   |
| America     | 5   |
| Asia        | 5   |
| Australia   | 5   |
| Europe      | 5   |

### 3. How many customers are allocated to each region?
```sql
select 
	r.region_name,
	count(distinct customer_id) as cnt 
from 
	customer_nodes c
join
	regions r on
    r.region_id = c.region_id
group by
	r.region_name
order by
	cnt desc,
    r.region_name;
```
| region_name | cnt |
| ----------- | --- |
| Australia   | 110 |
| America     | 105 |
| Africa      | 102 |
| Asia        | 95  |
| Europe      | 88  |

### 4. How many days on average are customers reallocated to a different node?
```sql
select 
	avg(extract(epoch from end_date::timestamp -  start_date::timestamp) / (60.0 * 60.0 * 24.0)) as average_days_per_switch
from 
	customer_nodes
where
	start_date::timestamp < NOW() and
    end_date::timestamp < NOW()
```
| average_days_per_switch |
| ----------------------- |
| 14.634                  |

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
with calculated as (
  select 
      	r.region_name,
  		c.end_date-  c.start_date as difference
  from 
      customer_nodes c
  join
      regions r on
      r.region_id = c.region_id
  where
      start_date::timestamp < NOW() and
      end_date::timestamp < NOW()
)
select
	region_name,
    percentile_cont(0.5) within group(order by difference) as _50th,
    percentile_cont(0.8) within group(order by difference) as _80th,
    percentile_cont(0.95) within group(order by difference) as _95th
from
	calculated
group by
	region_name;
```
| region_name | _50th | _80th | _95th |
| ----------- | ----- | ----- | ----- |
| Africa      | 15    | 24    | 28    |
| America     | 15    | 23    | 28    |
| Asia        | 15    | 23    | 28    |
| Australia   | 15    | 23    | 28    |
| Europe      | 15    | 24    | 28    |