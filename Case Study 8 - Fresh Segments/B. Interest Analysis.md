# B. Interest Analysis
### 1. Which interests have been present in all month_year dates in our dataset?
```sql
select interest_id, count(distinct month_year) as total_months
from cleaned
group by 1
having 
	count(distinct month_year) = 
    (select count(distinct month_year) from cleaned)
order by 1
```
A total of 480 interests appear in all month_year dates.

### 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
aggregated as (
  	select
  		total_months,
  		count(*) as num_interests
  	from total_months
  	group by 1
),
cum_sum as (
    select
        total_months,
        num_interests,
        sum(num_interests) over(order by total_months desc) as cum_sum
    from aggregated
),
cum_perc as (
    select 
        total_months,
        sum((num_interests * 100.0) / (select sum(num_interests) from cum_sum)) over(order by total_months desc) as cum_perc
    from cum_sum
)
select total_months from cum_perc
where cum_perc > 90
order by cum_perc
limit 1
```
| total_months |
| ------------ |
| 6            |

### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
aggregated as (
  	select
  		total_months,
  		count(*) as num_interests
  	from total_months
  	group by 1
)
select sum(num_interests) as interests_removed 
from aggregated 
where total_months >= 6;
```
| interests_removed |
| ----------------- |
| 1092              |

### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
```sql

```

### 5. After removing these interests - how many unique interests are there for each month?
```sql
with total_months as (
  	select
  		interest_id,
  		count(distinct month_year) as total_months
  	from cleaned
  	group by 1
)
select
    c.month_year,
    count(distinct t.interest_id)
from total_months t
join cleaned c on c.interest_id = t.interest_id
where t.total_months >= 6
group by 1
```
| month_year | count |
| ---------- | ----- |
| 2018-07-01 | 709   |
| 2018-08-01 | 752   |
| 2018-09-01 | 774   |
| 2018-10-01 | 853   |
| 2018-11-01 | 925   |
| 2018-12-01 | 986   |
| 2019-01-01 | 966   |
| 2019-02-01 | 1072  |
| 2019-03-01 | 1078  |
| 2019-04-01 | 1035  |
| 2019-05-01 | 827   |
| 2019-06-01 | 804   |
| 2019-07-01 | 836   |
| 2019-08-01 | 1062  |


###### Note: Skipping 4 for now.