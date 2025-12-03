# B. Transaction Analysis
### 1. How many unique transactions were there?
### 2. What is the average unique products purchased in each transaction?
### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
### 4. What is the average discount value per transaction?
### 5. What is the percentage split of all transactions for members vs non-members?
### 6. What is the average revenue for member transactions and non-member transactions?
```sql
with transactions_group as (
 	select
  		txn_id,
  		max(case when member then 't' else 'f' end) as member,
  		count(distinct prod_id) as unique_products,
  		sum(price * qty) as total_revenue,
  		sum((((qty * price) * discount) / 100.0)) as total_discount
  	from balanced_tree.sales
  	group by 1
)
select 
	count(*) as unique_transactions,
    round(avg(unique_products), 2) as avg_unique_prod,
    percentile_cont(0.25) within group(order by total_revenue) as percentile_25,
    percentile_cont(0.5) within group(order by total_revenue) as percentile_50,
    percentile_cont(0.75) within group(order by total_revenue) as percentile_75,
    round(count(case when member = 't' then 1 end) * 100.0 / count(*), 2) as member_percentage,
    round(count(case when member = 'f' then 1 end) * 100.0 / count(*), 2) as member_percentage,
    round(avg(total_discount), 2) as avg_discount,
    round(avg(case when member = 'f' then total_revenue end), 2) as avg_non_member,
    round(avg(case when member = 't' then total_revenue end), 2) as avg_member
from transactions_group
```
| unique_transactions | avg_unique_prod | percentile_25 | percentile_50 | percentile_75 | member_percentage | member_percentage | avg_discount | avg_non_member | avg_member |
| ------------------- | --------------- | ------------- | ------------- | ------------- | ----------------- | ----------------- | ------------ | -------------- | ---------- |
| 2500                | 6.04            | 375.75        | 509.5         | 647           | 60.20             | 39.80             | 62.49        | 515.04         | 516.27     |