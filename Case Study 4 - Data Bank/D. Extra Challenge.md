# D. Extra Challenge
Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

#### If we assume that management decides to give out zero in storage space in negative balance months, then:
```sql
with recursive months as (
  	select make_date(2020, 1, 1) as mth
  	union
  	select mth + 1 from months where mth + 1 < make_date(2020, 5, 1)
),
cids as (
  	select distinct customer_id from customer_transactions
),
joined as (
  	select c.customer_id, m.mth
  	from months m cross join cids c
),
balance as (
    select
        j.customer_id,
        j.mth,
        coalesce(case c.txn_type
                   when 'deposit' then c.txn_amount
                   else -c.txn_amount
                 end, 0) as txn
    from joined j
    left join customer_transactions c on
        j.customer_id = c.customer_id and
        j.mth = c.txn_date
),
r as (
  	select customer_id, mth, 
  		txn::float as balance, 
  		0::float as accumulated_interest 
  	from balance 
  	where mth = '2020-01-01'
  	union
  	select b.customer_id, b.mth, 
  		r.balance * (1 + (0.06 / 365)) + b.txn,
  		accumulated_interest + r.balance * (0.06 / 365)
  	from r r
  	join balance b on 
  	r.customer_id = b.customer_id and r.mth = b.mth - 1
)
select
	to_char(mth, 'Month') as month,
    round(sum(case
        	when balance > 0 then balance
        	else 0
        end)) as total_required_space,
    round(sum(case
        	when accumulated_interest > 0 then accumulated_interest
        	else 0
        end)) as total_required_space_by_interest
from r
group by to_char(mth, 'Month'), extract(month from mth)
order by extract(month from mth)
```

| month     | total_required_space | total_required_space_as_interest |
| --------- | -------------------- | -------------------------------- |
| January   | 4208053.22           | 692.22                           |
| February  | 7641542.74           | 1255.74                          |
| March     | 8367563.81           | 1375.81                          |
| April     | 7882817.61           | 1295.61                          |


### Special notes:

Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!

```sql
with recursive months as (
  	select make_date(2020, 1, 1) as mth
  	union
  	select mth + 1 from months where mth + 1 < make_date(2020, 5, 1)
),
cids as (
  	select distinct customer_id from customer_transactions
),
joined as (
  	select c.customer_id, m.mth
  	from months m cross join cids c
),
balance as (
    select
        j.customer_id,
        j.mth,
        coalesce(case c.txn_type
                   when 'deposit' then c.txn_amount
                   else -c.txn_amount
                 end, 0) as txn
    from joined j
    left join customer_transactions c on
        j.customer_id = c.customer_id and
        j.mth = c.txn_date
),
r as (
  	select customer_id, mth, 
  		txn::float as balance, 
  		txn * (1 + 0.06 / 365)::float as interest 
  	from balance 
  	where mth = '2020-01-01'
  	union
  	select b.customer_id, b.mth, 
  		r.balance * (1 + (0.06 / 365)) + b.txn,
  		r.balance * (1 + (0.06 / 365)) - r.balance
  	from r r
  	join balance b on 
  	r.customer_id = b.customer_id and r.mth = b.mth - 1
)
select
	to_char(mth, 'Month') as month,
    round(sum(case
        	when balance > 0 then balance
        	else 0
        end)) as total_required_space,
    round(sum(case
        	when interest > 0 then interest
        	else 0
        end)) as total_required_space_by_interest
from r
group by to_char(mth, 'Month'), extract(month from mth)
order by extract(month from mth)
```

| month     | total_required_space | total_required_space_by_interest |
| --------- | -------------------- | -------------------------------- |
| January   | 4845705              | 8083                             |
| February  | 10737675             | 48065                            |
| March     | 14932810             | 127757                           |
| April     | 19322901             | 223367                           |

###### Note: Skipping 4.5 for now.