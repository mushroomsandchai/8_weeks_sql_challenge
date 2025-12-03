# B. Data Exploration
### 1. What day of the week is used for each week_date value?
```sql
select distinct to_char(date, 'Day') as weekday
from sales
```

| weekday |
| ------- |
| Mon     |


### 2. What range of week numbers are missing from the dataset?
```sql
with all_weeks as (
	select generate_series(1, 52) as week
),
gaps_and_islands as (
    select 
  		a.week, 
  		row_number() over(order by a.week) as rn
    from all_weeks a
    left join sales s on s.week = a.week
    where s.week is null
)
select 
	concat(min(week), ' - ', max(week)) as missing_range
from gaps_and_islands
group by week - rn
```

| missing_range |
| ------------- |
| 1 - 11        |
| 37 - 52       |

### 3. How many total transactions were there for each year in the dataset?
```sql
select year, sum(transactions) as total_transactions
from sales
group by year
```

| year | total_transactions |
| ---- | ------------------ |
| 2018 | 346406460          |
| 2020 | 375813651          |
| 2019 | 365639285          |

### 4. What is the total sales for each region for each month?
```sql
with calculated as(
  	select region, month, sum(sales) as total_sales
    from sales
    group by month, region
    order by 3 desc
)
select
	region,
    max(case month
    	when 3 then total_sales
    end) as Mar,
    max(case month
    	when 4 then total_sales
    end) as Apr,
    max(case month
    	when 5 then total_sales
    end) as May,
    max(case month
    	when 6 then total_sales
    end) as Jun,
    max(case month
    	when 7 then total_sales
    end) as Jul,
    max(case month
    	when 8 then total_sales
    end) as Aug,
    max(case month
    	when 9 then total_sales
    end) as Sep
from calculated
group by region
```

| region        | mar       | apr        | may        | jun        | jul        | aug        | sep       |
| ------------- | --------- | ---------- | ---------- | ---------- | ---------- | ---------- | --------- |
| SOUTH AMERICA | 71023109  | 238451531  | 201391809  | 218247455  | 235582776  | 221166052  | 34175583  |
| CANADA        | 144634329 | 484552594  | 412378365  | 443846698  | 477134947  | 447073019  | 69067959  |
| OCEANIA       | 783282888 | 2599767620 | 2215657304 | 2371884744 | 2563459400 | 2432313652 | 372465518 |
| ASIA          | 529770793 | 1804628707 | 1526285399 | 1619482889 | 1768844756 | 1663320609 | 252836807 |
| USA           | 225353043 | 759786323  | 655967121  | 703878990  | 760331754  | 712002790  | 110532368 |
| EUROPE        | 35337093  | 127334255  | 109338389  | 122813826  | 136757466  | 122102995  | 18877433  |
| AFRICA        | 567767480 | 1911783504 | 1647244738 | 1767559760 | 1960219710 | 1809596890 | 276320987 |

### 5. What is the total count of transactions for each platform
```sql
select platform, sum(transactions) as total_transactions
from sales
group by platform
order by 2 desc
```

| platform | total_transactions |
| -------- | ------------------ |
| Retail   | 1081934227         |
| Shopify  | 5925169            |

### 6. What is the percentage of sales for Retail vs Shopify for each month?
```sql
with counted as (
  	select 
        month, 
        sum(case platform
                when 'Retail' then sales
             end) as total_retail,
        sum(case platform
                when 'Shopify' then sales
              end) as total_shopify
    from sales
    group by month
)
select
	month,
    round(100.0 * total_retail / 
          (total_shopify + total_retail), 2) as retail_percentage,
    round(100.0 * total_shopify / 
          (total_retail + total_shopify), 2) as shopify_percentage
from
	counted
order by 1
```

| month | retail_percentage | shopify_percentage |
| ----- | ----------------- | ------------------ |
| 3     | 97.54             | 2.46               |
| 4     | 97.59             | 2.41               |
| 5     | 97.30             | 2.70               |
| 6     | 97.27             | 2.73               |
| 7     | 97.29             | 2.71               |
| 8     | 97.08             | 2.92               |
| 9     | 97.38             | 2.62               |

### 7. What is the percentage of sales by demographic for each year in the dataset?
```sql
with counted as (
    select year, demographic, sum(sales) as total_sales
    from sales
    group by year, demographic
),
pivoted as (
    select
        year,
        max(case demographic
            when 'Couples' then total_sales
        end) as couples,
        max(case demographic
            when 'Families' then total_sales
        end) as families,
        max(case
            when demographic is null then total_sales
        end) as unaccounted
    from counted
    group by year
)
select
	year,
    round((100.0 * couples) / (couples + families + unaccounted), 2) as couple_percentage,
    round((100.0 * families) / (couples + families + unaccounted), 2) as families_percentage,
    round((100.0 * unaccounted) / (couples + families + unaccounted), 2) as unaccounted_percentage
from pivoted
```

| year | couple_percentage | families_percentage | unaccounted_percentage |
| ---- | ----------------- | ------------------- | ---------------------- |
| 2018 | 26.38             | 31.99               | 41.63                  |
| 2020 | 28.72             | 32.73               | 38.55                  |
| 2019 | 27.28             | 32.47               | 40.25                  |

### 8. Which age_band and demographic values contribute the most to Retail sales?
```sql
with calculated as(
    select
        age_band,
        demographic,
        sum(sales) as total_sales
    from sales
    where platform = 'Retail'
    group by age_band, demographic
)
select
	coalesce(age_band, 'unknown') as age_band,
    coalesce(max(case demographic
        	when 'Families' then total_sales
        end), 0) as families,
    coalesce(max(case demographic
        	when 'Couples' then total_sales
        end), 0) as couples,
    coalesce(max(case
        	when demographic is null then total_sales
        end), 0) as unknown
from calculated
group by age_band
```

| age_band     | families   | couples    | unknown     |
| ------------ | ---------- | ---------- | ----------- |
| Middle Aged  | 4354091554 | 1854160330 | 0           |
| Retirees     | 6634686916 | 6370580014 | 0           |
| Young Adults | 1770889293 | 2602922797 | 0           |
| unknown      | 0          | 0          | 16067285533 |


### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
avg_transaction column gives the avg amount per sale per day, per region, per demographic etc.. in currency. To calculate the average number of transactions we would use transactions column directly.
```sql
with calculated as(
    select
        year,
        platform,
        sum(transactions) as total_transactions,
  		sum(sales) as total_sales
    from sales
    group by year, platform
)
select
	year,
    max(round((case platform when 'Shopify' then total_sales end) / 
              (case platform when 'Shopify' then total_transactions end), 2)) as shopify,
    max(round((case platform when 'Retail' then total_sales end) / 
              (case platform when 'Retail' then total_transactions end), 2)) as retail
from calculated
group by year
```

| year | shopify | retail |
| ---- | ------- | ------ |
| 2018 | 192.00  | 36.00  |
| 2020 | 179.00  | 36.00  |
| 2019 | 183.00  | 36.00  |