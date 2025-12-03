# B. Customer Transactions
### 1. What is the unique count and total amount for each transaction type?
```sql
select
	txn_type,
    count(*) as cnt,
    sum(txn_amount) as total
from
	customer_transactions
group by
	txn_type;
```
| txn_type   | cnt  | total   |
| ---------- | ---- | ------- |
| purchase   | 1617 | 806537  |
| deposit    | 2671 | 1359168 |
| withdrawal | 1580 | 793003  |

### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
with deposits as (
  select
      customer_id,
      count(txn_type) as cnt,
      sum(txn_amount) as total
  from
      customer_transactions
  where
      txn_type = 'deposit'
  group by
      customer_id
)
select
	round(avg(cnt), 2) as average_deposits_count,
    round(avg(total), 2) as average_deposit
from
	deposits;
```

| average_deposits_count | average_deposit |
| ---------------------- | --------------- |
| 5.34                   | 2718.34         |


### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
with mth as (
  select
  	to_char(txn_date, 'Month') as mth,
  	customer_id,
  	count(case txn_type when 'deposit' then 1 end) as total_deposits,
  	count(case txn_type when 'withdrawal' then 1 end) as total_withdrawals,
  	count(case txn_type when 'purchase' then 1 end) as total_purchases
  from
      customer_transactions
  group by
  	to_char(txn_date, 'Month'), customer_id
)
select
	mth,
    count(*)
from
	mth
where
	total_deposits > 1 and
    (total_withdrawals = 1 or total_purchases = 1)
group by
	mth;
```
| mth       | count |
| --------- | ----- |
| April     | 50    |
| February  | 108   |
| January   | 115   |
| March     | 113   |


### 4. What is the closing balance for each customer at the end of the month?
```sql
with mthly as 
(
  select
      make_date(extract(year from txn_date)::int, extract(month from txn_date)::int, 1) as mth,
      customer_id,
      sum(case txn_type when 'deposit' then txn_amount else 0 end) - 
      sum(case txn_type when 'withdrawal' then txn_amount when 'purchase' then txn_amount else 0 end) as balance 
  from
      customer_transactions
  group by
      1, 2
)
select
	to_char(mth, 'YYYY-MM'),
    customer_id,
    sum(balance) over(partition by customer_id order by mth) as closing_balance
from
	mthly
```

| to_char | customer_id | closing_balance |
| ------- | ----------- | --------------- |
| 2020-01 | 1           | 312             |
| 2020-03 | 1           | -640            |
| 2020-01 | 2           | 549             |
| 2020-03 | 2           | 610             |
| 2020-01 | 3           | 144             |
| 2020-02 | 3           | -821            |
| 2020-03 | 3           | -1222           |
| 2020-04 | 3           | -729            |
| 2020-01 | 4           | 848             |
| 2020-03 | 4           | 655             |
| 2020-01 | 5           | 954             |
| 2020-03 | 5           | -1923           |
| 2020-04 | 5           | -2413           |
| 2020-01 | 6           | 733             |
| 2020-02 | 6           | -52             |
| 2020-03 | 6           | 340             |
| 2020-01 | 7           | 964             |
| 2020-02 | 7           | 3173            |
| 2020-03 | 7           | 2533            |
| 2020-04 | 7           | 2623            |
| 2020-01 | 8           | 587             |
| 2020-02 | 8           | 407             |
| 2020-03 | 8           | -57             |
| 2020-04 | 8           | -1029           |
| 2020-01 | 9           | 849             |
| 2020-02 | 9           | 654             |
| 2020-03 | 9           | 1584            |
| 2020-04 | 9           | 862             |
| 2020-01 | 10          | -1622           |
| 2020-02 | 10          | -1342           |
| 2020-03 | 10          | -2753           |
| 2020-04 | 10          | -5090           |


### 5. What is the percentage of customers who increase their closing balance by more than 5%?
```sql
with mthly as 
(
  select
      make_date(extract(year from txn_date)::int, extract(month from txn_date)::int, 1) as mth,
      customer_id,
      sum(case txn_type when 'deposit' then txn_amount else 0 end) - 
      sum(case txn_type when 'withdrawal' then txn_amount when 'purchase' then txn_amount else 0 end) as balance 
  from
      customer_transactions
  group by
      1, 2
),
mthly_closing_balance as (
  select
      extract(month from mth) as mth,
      customer_id,
      sum(balance) over(partition by customer_id order by mth) as closing_balance
  from
      mthly
),
first_closing as (
    select 
  		distinct on (customer_id)
        customer_id,
        closing_balance as first_closing_balance
    from mthly_closing_balance
    order by customer_id, mth
),
last_closing as (
    select 
  		distinct on (customer_id)
        customer_id,
        closing_balance as last_closing_balance
    from mthly_closing_balance
    order by customer_id, mth desc
)
select 
	round(count(*) * 100.0 / (select count(distinct customer_id) from mthly), 2) as _5_percent_growth
from 
	first_closing f
join 
	last_closing l on
    f.customer_id = l.customer_id
where
	l.last_closing_balance >= f.first_closing_balance * 1.05;
```

| _5_percent_growth |
| ----------------- |
| 34.00             |