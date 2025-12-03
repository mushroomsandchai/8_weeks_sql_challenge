# C. Data Allocation Challenge
### To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

### Option 1: End-of-Month Balance
Allocate data based on what customers had on the last day of the previous month

Example: If you had $500 on Jan 31st, you get 500 GB for February

#### Note: For months in which no transactions have been carried out the previous month's balance has been carried forward in the below query.
```sql
with cjoined as (
	select
  		distinct c.customer_id as customer_id,
  		m.month as mth
  	from
  		customer_transactions c
  	cross join
  		(
          	select 1 as month
  			union select 2
  			union select 3
  			union select 4) m
),
monthly_trans_grouped as 
(
    select
        customer_id,
        extract(month from txn_date) as mth,
        sum(case txn_type
                when 'deposit' then txn_amount
                else -txn_amount
            end) as balance
    from
        customer_transactions
  	group by
  		1, 2
)
select
	cj.customer_id,
    cj.mth,
    sum(mtg.balance) over(partition by cj.customer_id order by cj.mth) as month_end_balance
from
	cjoined cj
left join
	monthly_trans_grouped mtg on
    mtg.customer_id = cj.customer_id and
    mtg.mth = cj.mth
order by
	1, 2
```

| customer_id | mth | month_end_balance |
| ----------- | --- | ----------------- |
| 1           | 1   | 312               |
| 1           | 2   | 312               |
| 1           | 3   | -640              |
| 1           | 4   | -640              |
| 2           | 1   | 549               |
| 2           | 2   | 549               |
| 2           | 3   | 610               |
| 2           | 4   | 610               |
| 3           | 1   | 144               |
| 3           | 2   | -821              |
| 3           | 3   | -1222             |
| 3           | 4   | -729              |


#### We could assume that dataset we are given only reflects transactions carried out through a debit card. Hence, there must be positive balance in the account for the bank to have authorised withdrawls in the first place.
```sql
select
	mth as month,
    sum(month_end_balance) as required_storage
from
	above_query
group by
	mth 
order by
	mth
```
| month | required_storage |
| ----- | ---------------- |
| 1     | 126091           |
| 2     | -13708           |
| 3     | -184592          |
| 4     | -240372          |

#### If we assume that management decides to give out zero in storage space in negative balance months, then:
```sql
select
	mth as month,
    sum(
      	case
      		when month_end_balance > 0 then month_end_balance
    		else 0
    	end) as required_storage
from
	above_query
group by
	mth 
order by
	mth
```
| month | required_storage |
| ----- | ---------------- |
| 1     | 235595           |
| 2     | 261508           |
| 3     | 260971           |
| 4     | 264857           |


### Option 2: 30-Day Average

Allocate data based on the average balance over the previous 30 days

Example: If your average was $350 over 30 days, you get 350 GB next month

#### We could assume that dataset we are given only reflect transactions carried out through a debit card. Hence, there must be positive balance in the account for the bank to have authorised withdrawls in the first place.

```sql
with recursive days as (
  	select make_date(2020, 1, 1) as date
  	union
  	select date + 1 from days where date + 1 < make_date(2020, 5, 1)
),
joined as (
  	select distinct c.customer_id, d.date
  	from customer_transactions c cross join days d
),
rolling_average as (
  	select
  		j.customer_id,
  		j.date,
  		sum(coalesce(case c.txn_type
                     	when 'deposit' then c.txn_amount
                     	else -c.txn_amount
                     end , 0))
  		over(partition by j.customer_id order by j.date) as rolling_balance
  	from joined j
  	left join
  		customer_transactions c on
  		c.customer_id = j.customer_id and
  		c.txn_date = j.date
),
above_query as (
	select 
  		customer_id, 
  		extract(month from date) as month, 
  		avg(rolling_balance) as avg_balance
  	from rolling_average
	group by 1, 2
)
select
	month,
    round(sum(avg_balance)) as required_space
from
	above_query
group by
	month
```
| month | required_space |
| ----- | -------------- |
| 1     | 94060          |
| 2     | 65225          |
| 3     | -92309         |
| 4     | -229802        |

#### If we assume that management decides to give out zero in storage space in negative balance months, then:
```sql
select
	month,
    round(sum(case 
              	when avg_balance > 0 then avg_balance
             	else 0
              end)) as required_space
from
	above_query
group by
	month
```
| month | required_space |
| ----- | -------------- |
| 1     | 125218         |
| 2     | 246002         |
| 3     | 256519         |
| 4     | 256925         |

### Option 3: Real-Time
Data allocation updates instantly with every transaction

Example: Deposit $100? You immediately get 100 GB more

#### We could assume that dataset we are given only reflects transactions carried out through a debit card. Hence, there must be positive balance in the account for the bank to have authorised withdrawls in the first place.
```sql
with recursive days as (
  	select make_date(2020, 1, 1) as date
  	union
  	select date + 1 from days where date + 1 < make_date(2020, 5, 1)
),
joined as (
  	select distinct c.customer_id, d.date
  	from customer_transactions c cross join days d
),
rolling_average as (
  	select
  		j.customer_id,
  		j.date,
  		sum(coalesce(case c.txn_type
                     	when 'deposit' then c.txn_amount
                     	else -c.txn_amount
                     end , 0))
  		over(partition by j.customer_id order by j.date) as rolling_balance
  	from joined j
  	left join
  		customer_transactions c on
  		c.customer_id = j.customer_id and
  		c.txn_date = j.date
),
above_query as (
	select 
  		customer_id, 
  		extract(month from date) as month, 
  		sum(rolling_balance) as total_balance
  	from rolling_average
	group by 1, 2
)
select
	month,
    round(sum(total_balance)) as required_space
from
	above_query
group by
	month
```
| month | required_space |
| ----- | -------------- |
| 1     | 2925541        |
| 2     | 1877545        |
| 3     | -2918106       |
| 4     | -6925951       |


#### If we assume that management decides to give out zero in storage space in negative balance months, then:
```sql
select
	month,
    round(sum(case 
              	when total_balance > 0 then total_balance
             	else 0
              end)) as required_space
from
	above_query
group by
	month
```
| month | required_space |
| ----- | -------------- |
| 1     | 3919581        |
| 2     | 7180985        |
| 3     | 8004209        |
| 4     | 7750495        |

###### Note: Option 1 and 2 need a month shift since the storage space gets allocated the following month.