# B. Data Analysis Questions
### 1. How many customers has Foodie-Fi ever had?
```sql
select
	count(distinct customer_id) as total_customers
from
	subscriptions;
```


| count |
| ----- |
| 1000  |


### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
select
	to_char(start_date, 'Month') as month,
    count(*) as total_sign_ups
from
	subscriptions
where
	plan_id = (select plan_id from plans where plan_name = 'trial')
group by
	1
order by
	total_sign_ups desc;
```
| month     | total_sign_ups |
| --------- | -------------- |
| March     | 94             |
| July      | 89             |
| August    | 88             |
| May       | 88             |
| January   | 88             |
| September | 87             |
| December  | 84             |
| April     | 81             |
| June      | 79             |
| October   | 79             |
| November  | 75             |
| February  | 68             |


### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
```sql
select
	p.plan_name,
    count(*) as total_events
from
	subscriptions s
join
	plans p on
    p.plan_id = s.plan_id
where
	extract(year from s.start_date) > 2020
group by
	1
order by
	total_events desc;
```

| plan_name     | total_events |
| ------------- | ------------ |
| churn         | 71           |
| pro annual    | 63           |
| pro monthly   | 60           |
| basic monthly | 8            |


### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
with last_activity as (
  select
      customer_id,
      max(start_date) as last_activity
  from
      subscriptions
  group by
  	customer_id
)
select
	count(*) as cancelled_count,
    round((100.0 * count(*)) / (select count(distinct customer_id) from subscriptions) * 1.0, 1) as percentage
from
	last_activity l
join
	subscriptions s on
    s.customer_id = l.customer_id and
    s.start_date = l.last_activity
where
	s.plan_id = (select plan_id from plans where plan_name = 'churn');
```
| cancelled_count | percentage |
| --------------- | ---------- |
| 307             | 30.7       |


### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
with initial_plan as (
  select
  	customer_id,
  	start_date,
  	plan_id as start_plan,
  	lead(start_date) over(partition by customer_id order by start_date) as next_date,
  	lead(plan_id) over(partition by customer_id order by start_date) as next_plan
  from
      subscriptions
)
select
	count(*) as customer_count,
    round((100.0 * count(*)) / (select count(distinct customer_id) from subscriptions) * 1.0, 1) as percentage
from
	initial_plan
where
	next_date - start_date = 7 and
    start_plan = (select plan_id from plans where plan_name = 'trial')
    and next_plan = (select plan_id from plans where plan_name = 'churn')
```
| customer_count | percentage |
| -------------- | ---------- |
| 92             | 9.2        |

### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
with initial_plan as (
  select
  	customer_id,
  	start_date,
  	plan_id as start_plan,
  	lead(plan_id) over(partition by customer_id order by start_date) as next_plan
  from
      subscriptions
),
breakdown as (  
  select
      sum(case
            when next_plan = 1 then 1
            else 0
          end) as basic,
      sum(case
            when next_plan = 2 then 1
            else 0
          end) as pro_monthly,
      sum(case
            when next_plan = 3 then 1
            else 0
          end) as pro_yearly,
      sum(case
            when next_plan = 4 then 1
            else 0
          end) as churn
  from
      initial_plan
  where
      start_plan = (select plan_id from plans where plan_name = 'trial')
)
select
	'basic' as plan,
    basic as count,
    round((basic * 100.0) / (select count(distinct customer_id) from subscriptions) * 1.0, 1)as percentage
from
	breakdown
union
select
	'pro_monthly' as plan,
    pro_monthly as count,
    round((pro_monthly * 100.0) / (select count(distinct customer_id) from subscriptions) * 1.0, 1)as percentage
from
	breakdown
union
select
	'pro_yearly' as plan,
    pro_yearly as count,
    round((pro_yearly * 100.0) / (select count(distinct customer_id) from subscriptions) * 1.0, 1)as percentage
from
	breakdown
union
select
	'churn' as plan,
    churn as count,
    round((churn * 100.0) / (select count(distinct customer_id) from subscriptions) * 1.0, 1)as percentage
from
	breakdown
order by
	count desc;
```
| plan        | count | percentage |
| ----------- | ----- | ---------- |
| basic       | 546   | 54.6       |
| pro_monthly | 325   | 32.5       |
| churn       | 92    | 9.2        |
| pro_yearly  | 37    | 3.7        |


### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
with last_plan as (
  select
      customer_id,
      plan_id
  from (
      select
          customer_id,
          plan_id,
          start_date,
          row_number() over (partition by customer_id order by start_date desc) as rn
      from subscriptions
      where start_date <= '2020-12-31'
  ) x
  where rn = 1
),
plan_counts as (
  select
      plan_id,
      count(*) as cnt
  from last_plan
  group by plan_id
)
select
    case plan_id
      when 0 then 'trial'
      when 1 then 'basic'
      when 2 then 'pro_monthly'
      when 3 then 'pro_yearly'
      when 4 then 'churn'
    end as plan,
    cnt as count,
    round(cnt * 100.0 / (select count(distinct customer_id) from subscriptions where start_date <= '2020-12-31') * 1.0, 1) as percentage
from plan_counts
order by count desc;
```

| plan        | count | percentage |
| ----------- | ----- | ---------- |
| pro_monthly | 326   | 32.6       |
| churn       | 236   | 23.6       |
| basic       | 224   | 22.4       |
| pro_yearly  | 195   | 19.5       |
| trial       | 19    | 1.9        |


### 8. How many customers have upgraded to an annual plan in 2020?
```sql
select
	count(distinct customer_id)
from
	subscriptions
where
	extract(year from start_date) = 2020 and
    plan_id = (select plan_id from plans where plan_name = 'pro annual')
```
| count |
| ----- |
| 195   |


### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi? 
```sql
with joined as (
  select
      customer_id,
      min(start_date) as join
  from
      subscriptions
  group by
  	customer_id
),
annual_join as (
  select
  	customer_id,
  	min(start_date) as annual_join
  from
  	subscriptions
  where
  	plan_id = (select plan_id from plans where plan_name = 'pro annual')
  group by
  	customer_id
)
select
	round(avg(aj.annual_join - j.join)) as average_days
from
	joined j
join
	annual_join aj on
    aj.customer_id = j.customer_id
```

| average_days |
| ------------ |
| 105          |


### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
with joining as (
  select
      customer_id,
      min(start_date) as joining_date
  from
      subscriptions
  group by
      customer_id
),
pro_joining as (
  select
  	customer_id,
  	min(start_date) as pro_join
  from
  	subscriptions
  where
  	plan_id = 3 and
  	extract(year from start_date) = 2020
  group by
  	customer_id
),
difference as (
  select
      j.customer_id,
	case
    	when (p.pro_join - j.joining_date) >= 0 and (p.pro_join - j.joining_date) <= 30 then '0 - 30'
    	when (p.pro_join - j.joining_date) >= 31 and (p.pro_join - j.joining_date) <= 60 then '31 - 60'
    	when (p.pro_join - j.joining_date) >= 61 and (p.pro_join - j.joining_date) <= 90 then '61 - 90'
    	when (p.pro_join - j.joining_date) >= 91 and (p.pro_join - j.joining_date) <= 120 then '91 - 120'
    	when (p.pro_join - j.joining_date) >= 121 and (p.pro_join - j.joining_date) <= 150 then '121 - 150'
    	when (p.pro_join - j.joining_date) >= 151 and (p.pro_join - j.joining_date) <= 180 then '151 - 180'
    	when (p.pro_join - j.joining_date) >= 181 and (p.pro_join - j.joining_date) <= 210 then '181 - 210'
    	when (p.pro_join - j.joining_date) >= 211 and (p.pro_join - j.joining_date) <= 240 then '211 - 240'
    	when (p.pro_join - j.joining_date) >= 241 and (p.pro_join - j.joining_date) <= 270 then '241 - 270'
    	when (p.pro_join - j.joining_date) >= 271 and (p.pro_join - j.joining_date) <= 300 then '271 - 300'
    	when (p.pro_join - j.joining_date) >= 301 and (p.pro_join - j.joining_date) <= 330 then '301 - 330'
    	when (p.pro_join - j.joining_date) >= 331 and (p.pro_join - j.joining_date) <= 365 then '331 - 365'
     end as interval
  from
      joining j
  join
      pro_joining p on
      p.customer_id = j.customer_id
)
select
     interval,
     count(*) as cnt
from
	difference
group by
	interval
order by
	cnt desc
```
| interval  | cnt |
| --------- | --- |
| 0 - 30    | 48  |
| 61 - 90   | 30  |
| 121 - 150 | 28  |
| 91 - 120  | 24  |
| 31 - 60   | 22  |
| 151 - 180 | 22  |
| 181 - 210 | 17  |
| 241 - 270 | 3   |
| 211 - 240 | 1   |


### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
with filtered as (
  select
  	*
  from
  	subscriptions
  where
  	extract(year from start_date) = 2020 and
  	(plan_id = 1 or plan_id = 2)
)
select
	count(distinct f1.customer_id) as num
from
	filtered f1
join
	filtered f2 on
    f1.customer_id = f2.customer_id and
    f1.plan_id > f2.plan_id and
    f1.start_date < f2.start_date
```
| num |
| --- |
| 0   |