# A. Data Exploration and Cleansing
### 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT make_date(_year::int, _month::int, 1) as month_year, count(*)
from fresh_segments.interest_metrics
group by 1
order by 1 nulls first;
```
| month_year | count |
| ---------- | ----- |
| null       | 1194  |
| 2018-07-01 | 729   |
| 2018-08-01 | 767   |
| 2018-09-01 | 780   |
| 2018-10-01 | 857   |
| 2018-11-01 | 928   |
| 2018-12-01 | 995   |
| 2019-01-01 | 973   |
| 2019-02-01 | 1121  |
| 2019-03-01 | 1136  |
| 2019-04-01 | 1099  |
| 2019-05-01 | 857   |
| 2019-06-01 | 824   |
| 2019-07-01 | 864   |
| 2019-08-01 | 1149  |


### 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
### 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
We would drop the null values since they can't be used meaningfully. 
```sql
drop table if exists fresh_segments.interest_metrics_cleaned;
create table fresh_segments.interest_metrics_cleaned(
    "_month" int,
    "_year" int,
    "month_year" date,
  	"interest_id" int,
  	"composition" float,
  	"index_value" float,
  	"ranking" integer,
  	"percentile_ranking" float
);

insert into fresh_segments.interest_metrics_cleaned 
select
    _month::int,
    _year::int,
	make_date(_year::int, _month::int, 1),
    interest_id::int,
    composition,
    index_value,
    ranking,
    percentile_ranking
from fresh_segments.interest_metrics
where 
	_month is not null and 
    _year is not null and
    interest_id is not null;;
```

### 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
```sql
select
	count(distinct met.interest_id) as exists_in_metrics_not_in_map
    -- count(distinct map.id) as exists_in_map_not_in_metrics
from fresh_segments.interest_metrics_cleaned met
left join fresh_segments.interest_map map on
-- from fresh_segments.interest_map map
-- left join fresh_segments.interest_metrics_cleaned met on
map.id = met.interest_id
where map.id is null
-- where met.interest_id is null
```
| exists_in_metrics_not_in_map |
| ---------------------------- |
| 0                         |

| exists_in_map_not_in_metrics |
| ---------------------------- |
| 7                            |


### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
```sql
select
	id,
    count(*) as count
from (
  		select
            map.id as id
        from fresh_segments.interest_map map
        left join fresh_segments.interest_metrics_cleaned met on
  		map.id = met.interest_id
  		where met.interest_id is null
		) t
group by 1
order by 2 desc;
```
| id    | count |
| ----- | ----- |
| 40186 | 1     |
| 47789 | 1     |
| 19598 | 1     |
| 35964 | 1     |
| 42010 | 1     |
| 42400 | 1     |
| 40185 | 1     |

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
Inner join interest_metrics onto map table using interest_id to id.
```sql
select
    met._month,
    met._year,
	met.month_year,
    met.interest_id,
    met.composition,
    met.index_value,
    met.ranking,
    met.percentile_ranking,
    map.interest_name,
    map.interest_summary,
    map.created_at,
    map.last_modified
from fresh_segments.interest_map map
left join fresh_segments.interest_metrics_cleaned met on
map.id = met.interest_id
where met.interest_id = 21246
```
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name                    | interest_summary                                      | created_at          | last_modified       |
| ------ | ----- | ---------- | ----------- | ----------- | ----------- | ------- | ------------------ | -------------------------------- | ----------------------------------------------------- | ------------------- | ------------------- |
| 7      | 2018  | 2018-07-01 | 21246       | 2.26        | 0.65        | 722     | 0.96               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 8      | 2018  | 2018-08-01 | 21246       | 2.13        | 0.59        | 765     | 0.26               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 9      | 2018  | 2018-09-01 | 21246       | 2.06        | 0.61        | 774     | 0.77               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 10     | 2018  | 2018-10-01 | 21246       | 1.74        | 0.58        | 855     | 0.23               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 11     | 2018  | 2018-11-01 | 21246       | 2.25        | 0.78        | 908     | 2.16               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 12     | 2018  | 2018-12-01 | 21246       | 1.97        | 0.7         | 983     | 1.21               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 1      | 2019  | 2019-01-01 | 21246       | 2.05        | 0.76        | 954     | 1.95               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 2      | 2019  | 2019-02-01 | 21246       | 1.84        | 0.68        | 1109    | 1.07               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 3      | 2019  | 2019-03-01 | 21246       | 1.75        | 0.67        | 1123    | 1.14               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 4      | 2019  | 2019-04-01 | 21246       | 1.58        | 0.63        | 1092    | 0.64               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
|        |       |            | 21246       | 1.61        | 0.68        | 1191    | 0.25               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |

### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
There are a total of 188 records where the month_year value is before the created_at value. These are still valid as long as month and year from metrics match the month and year of map since we made the month_year to begin from the start of the month.
```sql
select
	count(*) as count_map_later_metric_first
from fresh_segments.interest_map map
left join fresh_segments.interest_metrics_cleaned met on
map.id = met.interest_id
where met.month_year < map.created_at::date
and ( met._month < extract(month from map.created_at) or
    met._year < extract(year from map.created_at))
order by 1, 2
```

| count_map_later_metric_first |
| ---------------------------- |
| 0                            |