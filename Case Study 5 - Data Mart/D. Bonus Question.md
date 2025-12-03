# D. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

    region
    platform
    age_band
    demographic
    customer_type

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
```sql
with periods as (
  	select
  		coalesce(region, 'unknown') as region,
  		sum(case when date >= '2020-06-15' and
            		  date < '2020-06-15'::date + interval '12 weeks'
            	 then sales
            end) as after,
  		sum(case when date < '2020-06-15' and
            		  date >= '2020-06-15'::date - interval '12 weeks'
            	 then sales
            end) as before
  	from sales
  	group by 1
)
select
	region,
    after - before as actual_growth,
    round(((after - before)::numeric 
          / before) * 100, 2) as growth_percentage
from periods
order by growth_percentage
```

#### Region
| region        | actual_growth | growth_percentage |
| ------------- | ------------- | ----------------- |
| ASIA          | -53436845     | -3.26             |
| OCEANIA       | -71321100     | -3.03             |
| SOUTH AMERICA | -4584174      | -2.15             |
| CANADA        | -8174013      | -1.92             |
| USA           | -10814843     | -1.60             |
| AFRICA        | -9146811      | -0.54             |
| EUROPE        | 5152392       | 4.73              |


#### Platform
| platform | actual_growth | growth_percentage |
| -------- | ------------- | ----------------- |
| Retail   | -168083834    | -2.43             |
| Shopify  | 15758440      | 7.18              |


#### Age_band
| age_band     | actual_growth | growth_percentage |
| ------------ | ------------- | ----------------- |
| unknown      | -92393021     | -3.34             |
| Middle Aged  | -22994292     | -1.97             |
| Retirees     | -29549521     | -1.23             |
| Young Adults | -7388560      | -0.92             |


#### demographic
| demographic | actual_growth | growth_percentage |
| ----------- | ------------- | ----------------- |
| unknown     | -92393021     | -3.34             |
| Families    | -42320015     | -1.82             |
| Couples     | -17612358     | -0.87             |


#### customer_type
| customer_type | actual_growth | growth_percentage |
| ------------- | ------------- | ----------------- |
| Guest         | -77202666     | -3.00             |
| Existing      | -83872973     | -2.27             |
| New           | 8750245       | 1.01              |
