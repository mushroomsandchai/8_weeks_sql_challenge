# Index Analysis

The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

### 1. What is the top 10 interests by the average composition for each month?
```sql
with avg_composition as (
  	select
  		*,
  		round((composition / index_value)::numeric, 2) as avg_composition
 	from cleaned
),
ranked as (
  	select
  		interest_id,
  		month_year,
  		avg_composition,
  		rank() over(partition by month_year order by avg_composition desc) as rank
  	from avg_composition
)
select
	r.month_year,
    r.rank,
    r.interest_id,
    map.interest_name,
    r.avg_composition
from ranked r
join fresh_segments.interest_map map on
r.interest_id = map.id
where r.rank <= 10
order by 1, r.rank;
```
| month_year | rank | interest_id | interest_name                                        | avg_composition |
| ---------- | ---- | ----------- | ---------------------------------------------------- | --------------- |
| 2018-07-01 | 1    | 6324        | Las Vegas Trip Planners                              | 7.36            |
| 2018-07-01 | 2    | 6284        | Gym Equipment Owners                                 | 6.94            |
| 2018-07-01 | 3    | 4898        | Cosmetics and Beauty Shoppers                        | 6.78            |
| 2018-07-01 | 4    | 77          | Luxury Retail Shoppers                               | 6.61            |
| 2018-07-01 | 5    | 39          | Furniture Shoppers                                   | 6.51            |
| 2018-07-01 | 6    | 18619       | Asian Food Enthusiasts                               | 6.10            |
| 2018-07-01 | 7    | 6208        | Recently Retired Individuals                         | 5.72            |
| 2018-07-01 | 8    | 21060       | Family Adventures Travelers                          | 4.85            |
| 2018-07-01 | 9    | 21057       | Work Comes First Travelers                           | 4.80            |
| 2018-07-01 | 10   | 82          | HDTV Researchers                                     | 4.71            |

### 2. For all of these top 10 interests - which interest appears the most often?
```sql
top as (
  	select
        month_year,
        interest_id,
        rank
    from ranked
    where rank <= 10
  	order by 1, rank
)
select
	t.interest_id,
    map.interest_name,
    count(*) as count
from top t
join fresh_segments.interest_map map on
map.id = t.interest_id
group by 1, 2
order by 3 desc
```
| interest_id | interest_name                                        | count |
| ----------- | ---------------------------------------------------- | ----- |
| 7541        | Alabama Trip Planners                                | 10    |
| 5969        | Luxury Bedding Shoppers                              | 10    |
| 6065        | Solar Energy Researchers                             | 10    |
| 10981       | New Years Eve Party Ticket Purchasers                | 9     |
| 21245       | Readers of Honduran Content                          | 9     |
| 18783       | Nursing and Physicians Assistant Journal Researchers | 9     |
| 34          | Teen Girl Clothing Shoppers                          | 8     |
| 21057       | Work Comes First Travelers                           | 8     |
| 10977       | Christmas Celebration Researchers                    | 7     |
| 18619       | Asian Food Enthusiasts                               | 5     |

### 3. What is the average of the average composition for the top 10 interests for each month?
```sql
with avg_composition as (
  	select
  		*,
  		round((composition / index_value)::numeric, 2) as avg_composition
 	from cleaned
),
ranked as (
  	select
  		interest_id,
  		month_year,
  		avg_composition,
  		rank() over(partition by month_year order by avg_composition desc) as rank
  	from avg_composition
)
select
	c.month_year,
    round(avg(r.avg_composition), 2) as top_10_avg_composition
from ranked r
join cleaned c on
	c.interest_id = r.interest_id and
    c.month_year = r.month_year
where r.rank <= 10
group by 1;
```
| month_year | top_10_avg_composition |
| ---------- | ---------------------- |
| 2018-07-01 | 6.04                   |
| 2018-08-01 | 5.95                   |
| 2018-09-01 | 6.90                   |
| 2018-10-01 | 7.07                   |
| 2018-11-01 | 6.62                   |
| 2018-12-01 | 6.65                   |
| 2019-01-01 | 6.32                   |
| 2019-02-01 | 6.58                   |
| 2019-03-01 | 6.12                   |
| 2019-04-01 | 5.75                   |
| 2019-05-01 | 3.54                   |
| 2019-06-01 | 2.43                   |
| 2019-07-01 | 2.77                   |
| 2019-08-01 | 2.63                   |

### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
```sql
with avg_composition as (
  	select
  		*,
  		round((composition / index_value)::numeric, 2) as avg_composition
 	from cleaned
),
ranked as (
  	select
  		ac.interest_id,
  		map.interest_name,
  		ac.month_year,
  		rank() over(partition by ac.month_year order by ac.avg_composition desc) as rank
  	from avg_composition ac
  	join fresh_segments.interest_map map on
  		ac.interest_id = map.id
),
maxed as (
    select 
        month_year, 
        max(avg_composition) as max_index_composition
    from avg_composition
    group by 1
),
lagged as (
    select
        m.month_year,
        m.max_index_composition,
    	r.interest_name,
        round(avg(m.max_index_composition) over(order by m.month_year rows between 2 preceding and current row), 2) as "3_month_moving_avg",
        lag(m.max_index_composition) over(order by m.month_year) as "1_month_ago",
        lag(m.max_index_composition, 2) over(order by m.month_year) as "2_months_ago"
    from maxed m
    join ranked r on
        r.month_year = m.month_year
    where 
        r.rank = 1
)
select 
	month_year,
    max_index_composition,
    interest_name,
    "3_month_moving_avg",
    concat(lag(interest_name) over(order by month_year), ': ', "1_month_ago") as "1_month_ago",
    concat(lag(interest_name, 2) over(order by month_year), ': ', "2_months_ago") as "2_months_ago"
from lagged
offset 2
```
| month_year | max_index_composition | interest_name                 | 3_month_moving_avg | 1_month_ago                       | 2_months_ago                      |
| ---------- | --------------------- | ----------------------------- | ------------------ | --------------------------------- | --------------------------------- |
| 2018-09-01 | 8.26                  | Work Comes First Travelers    | 7.61               | Las Vegas Trip Planners: 7.21     | Las Vegas Trip Planners: 7.36     |
| 2018-10-01 | 9.14                  | Work Comes First Travelers    | 8.20               | Work Comes First Travelers: 8.26  | Las Vegas Trip Planners: 7.21     |
| 2018-11-01 | 8.28                  | Work Comes First Travelers    | 8.56               | Work Comes First Travelers: 9.14  | Work Comes First Travelers: 8.26  |
| 2018-12-01 | 8.31                  | Work Comes First Travelers    | 8.58               | Work Comes First Travelers: 8.28  | Work Comes First Travelers: 9.14  |
| 2019-01-01 | 7.66                  | Work Comes First Travelers    | 8.08               | Work Comes First Travelers: 8.31  | Work Comes First Travelers: 8.28  |
| 2019-02-01 | 7.66                  | Work Comes First Travelers    | 7.88               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 8.31  |
| 2019-03-01 | 6.54                  | Alabama Trip Planners         | 7.29               | Work Comes First Travelers: 7.66  | Work Comes First Travelers: 7.66  |
| 2019-04-01 | 6.28                  | Solar Energy Researchers      | 6.83               | Alabama Trip Planners: 6.54       | Work Comes First Travelers: 7.66  |
| 2019-05-01 | 4.41                  | Readers of Honduran Content   | 5.74               | Solar Energy Researchers: 6.28    | Alabama Trip Planners: 6.54       |
| 2019-06-01 | 2.77                  | Las Vegas Trip Planners       | 4.49               | Readers of Honduran Content: 4.41 | Solar Energy Researchers: 6.28    |
| 2019-07-01 | 2.82                  | Las Vegas Trip Planners       | 3.33               | Las Vegas Trip Planners: 2.77     | Readers of Honduran Content: 4.41 |
| 2019-08-01 | 2.73                  | Cosmetics and Beauty Shoppers | 2.77               | Las Vegas Trip Planners: 2.82     | Las Vegas Trip Planners: 2.77     |


### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

###### Note: Skipping 5 for now