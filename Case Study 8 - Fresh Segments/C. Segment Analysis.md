# C. Segment Analysis
### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
joined as (
  	select
  		c.interest_id,
  		c.composition,
  		c.month_year
  	from cleaned c
  	join total_months t on
  	t.interest_id = c.interest_id
  	where t.total_months >= 6
),
distincted as (
    select
        distinct on(interest_id)
        interest_id,
        month_year,
        composition
    from joined
    order by interest_id, composition desc
)
(select * from distincted order by 3 desc limit 10)
union
(select * from distincted order by 3 asc limit 10)
order by composition desc;
```
| interest_id | month_year | composition |
| ----------- | ---------- | ----------- |
| 21057       | 2018-12-01 | 21.2        |
| 6284        | 2018-07-01 | 18.82       |
| 39          | 2018-07-01 | 17.44       |
| 77          | 2018-07-01 | 17.19       |
| 12133       | 2018-10-01 | 15.15       |
| 5969        | 2018-12-01 | 15.05       |
| 171         | 2018-07-01 | 14.91       |
| 4898        | 2018-07-01 | 14.23       |
| 6286        | 2018-07-01 | 14.1        |
| 4           | 2018-07-01 | 13.97       |
| 58          | 2018-07-01 | 2.18        |
| 34085       | 2019-08-01 | 2.14        |
| 22408       | 2018-07-01 | 2.12        |
| 42011       | 2019-01-01 | 2.09        |
| 37421       | 2019-08-01 | 2.09        |
| 19591       | 2018-10-01 | 2.08        |
| 19635       | 2018-07-01 | 2.05        |
| 19599       | 2019-03-01 | 1.97        |
| 37412       | 2018-10-01 | 1.94        |
| 33958       | 2018-08-01 | 1.88        |

### 2. Which 5 interests had the lowest average ranking value?
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
joined as (
  	select
  		c.interest_id,
  		c.composition,
  		c.month_year,
  		c.ranking
  	from cleaned c
  	join total_months t on
  	t.interest_id = c.interest_id
  	where t.total_months >= 6
)
select
	interest_id,
    round(avg(ranking), 2) as avg_rank
from joined
group by 1
order by avg_rank
limit 5;
```
| interest_id | avg_rank |
| ----------- | -------- |
| 41548       | 1.00     |
| 42203       | 4.11     |
| 115         | 5.93     |
| 171         | 9.36     |
| 4           | 11.86    |

### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
joined as (
  	select
  		c.interest_id,
  		c.composition,
  		c.month_year,
  		c.percentile_ranking
  	from cleaned c
  	join total_months t on
  	t.interest_id = c.interest_id
  	where t.total_months >= 6
)
select
	interest_id,
    round(stddev(percentile_ranking)::numeric, 2) as stddev
from joined
group by 1
order by stddev desc
limit 5
```
| interest_id | stddev |
| ----------- | ------ |
| 23          | 30.18  |
| 20764       | 28.97  |
| 38992       | 28.32  |
| 43546       | 26.24  |
| 10839       | 25.61  |

### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
```sql
with total_months as (
    select interest_id, count(distinct month_year) as total_months
    from cleaned
    group by 1
),
joined as (
  	select
  		c.interest_id,
  		c.composition,
  		c.month_year,
  		c.percentile_ranking
  	from cleaned c
  	join total_months t on
  	t.interest_id = c.interest_id
  	where t.total_months >= 6
),
filtered as (
    select
        interest_id,
        round(stddev(percentile_ranking)::numeric, 2) as stddev
    from joined
    group by 1
    order by stddev desc
    limit 5
),
min_max as (
    select
        f.interest_id,
        min(c.percentile_ranking) as min_perc_ranking,
        max(c.percentile_ranking) as max_perc_ranking
    from cleaned c
    join filtered f on
    f.interest_id = c.interest_id
    join total_months t on
    t.interest_id = c.interest_id
    where t.total_months >= 6
    group by 1
)
select
	mm.interest_id,
    mm.min_perc_ranking,
    mi.month_year,
    mm.max_perc_ranking,
    mx.month_year
from min_max mm
join cleaned mi on 
	mi.interest_id = mm.interest_id and
    mm.min_perc_ranking = mi.percentile_ranking
join cleaned mx on 
	mx.interest_id = mm.interest_id and
    mm.max_perc_ranking = mx.percentile_ranking
```

| interest_id | min_perc_ranking | month_year | max_perc_ranking | month_year |
| ----------- | ---------------- | ---------- | ---------------- | ---------- |
| 23          | 7.92             | 2019-08-01 | 86.69            | 2018-07-01 |
| 20764       | 11.23            | 2019-08-01 | 86.15            | 2018-07-01 |
| 10839       | 4.84             | 2019-03-01 | 75.03            | 2018-07-01 |
| 38992       | 2.2              | 2019-07-01 | 82.44            | 2018-11-01 |
| 43546       | 5.7              | 2019-06-01 | 73.15            | 2019-03-01 |


### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?


###### Note: Skipping 5 for now