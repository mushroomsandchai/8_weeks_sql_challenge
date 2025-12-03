# A. Customer Journey
### Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
```sql
select
	s.customer_id,
    p.plan_id,
    s.start_date,
    p.plan_name,
    p.price
from
	subscriptions s
join
	plans p on
    p.plan_id = s.plan_id
where
	s.customer_id in (1, 2, 11, 13, 15, 16, 18, 19)
order by
	s.customer_id,
    s.start_date
```

    - Customer 1 started their trial on 2020-08-01 and upgraded to basic monthly after the trial period ended.

    - Customer 2 started their trial on 2020-09-20 and upgraded to pro annual after the trial period ended.

    - Customer 11 started their trial on 2020-11-19 and cancelled their subscription after the trial period ended.

    - Custoemr 13 startd their trial on 2020-12-15 and upgraded to basic monthly after the trial period ended, continued with basic monthly till 2021-03-29 at which point they decided to upgrade to pro monthly, receiving the pro plan provisions immediately.

    - Custoemr 15 startd their trial on 2020-03-17 and upgraded to pro monthly after the trial period ended, continued with pro monthly till 2020-04-29 at which point they decided to cancel their subscription. Since the most recent billing date for pro monthly was 2020-04-24, they'll continue to receive services till 2020-05-23.

    - Custoemr 16 startd their trial on 2020-05-31 and upgraded to basic monthly after the trial period ended, continued with basic monthly till 2020-10-21 at which point they decided to upgrade to pro annual, receiving the pro plan provisions immediately.

    - Customer 18 started their trial on 2020-07-06 and upgraded to pro monthly after the trial period ended.

    - Custoemr 19 startd their trial on 2020-06-22 and upgraded to pro monthly after the trial period ended, continued with basic monthly till 2020-08-29 at which point they decided to upgrade to pro annual.