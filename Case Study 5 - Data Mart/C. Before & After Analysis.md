# C. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
```sql
with periods as (
  	select 
  		sum(case
           		when date < '2020-06-15' and
           			 date >= '2020-06-15':: date - 28
           			 then sales
           	end) as before,
  		sum(case
           		when date >= '2020-06-15' and
           			 date < '2020-06-15':: date + 28
           			 then sales
           	end) as after
  	from sales
)
select
	after - before as actual_growth,
    round(((after - before)::numeric / before) * 100.0, 2) as growth_percentage
from periods
```
| actual_growth | growth_percentage |
| ------------- | ----------------- |
| -26884188     | -1.15             |


### 2. What about the entire 12 weeks before and after?
```sql
with periods as (
  	select 
  		sum(case
           		when date < '2020-06-15' and
           			 date >= '2020-06-15':: date - interval '12 weeks'
           			 then sales
           	end) as before,
  		sum(case
           		when date >= '2020-06-15' and
           			 date < '2020-06-15'::date + interval '12 weeks'
           			 then sales
           	end) as after
  	from sales
)
select
	after - before as actual_growth,
    round(((after - before)::numeric / before) * 100.0, 2) as growth_percentage
from periods
```
| actual_growth | growth_percentage |
| ------------- | ----------------- |
| -152325394    | -2.14             |


### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
```sql
with periods as (
  	select 
  		year,
  		sum(case
           		when date < make_date(year, 6, 15) and
           			 date >= make_date(year, 6, 15) - interval '12 weeks'
           			 then sales
           	end) as before,
  		sum(case
           		when date >= make_date(year, 6, 15) and
           			 date < make_date(year, 6, 15) + interval '12 weeks'
           			 then sales
           	end) as after
  	from sales
  	group by year
)
select
	year,
	after - before as actual_growth,
    round(((after - before)::numeric / before) * 100.0, 2) as growth_percentage
from periods
order by 1
```

#### For 12 weeks
| year | actual_growth | growth_percentage |
| ---- | ------------- | ----------------- |
| 2018 | 104256193     | 1.63              |
| 2019 | -20740294     | -0.30             |
| 2020 | -152325394    | -2.14             |

#### For 4 weeks
| year | actual_growth | growth_percentage |
| ---- | ------------- | ----------------- |
| 2018 | 4102105       | 0.19              |
| 2019 | 2336594       | 0.10              |
| 2020 | -26884188     | -1.15             |