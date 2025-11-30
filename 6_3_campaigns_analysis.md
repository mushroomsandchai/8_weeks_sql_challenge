## Generate a table that has 1 single row for every unique visit_id record and has the following columns:
 - user_id
 - visit_id
 - visit_start_time: the earliest event_time for each visit
 - page_views: count of page views for each visit
 - cart_adds: count of product cart add events for each visit
 - purchase: 1/0 flag if a purchase event exists for each visit
 - campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
 - impression: count of ad impressions for each visit
 - click: count of ad clicks for each visit
 - (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
with purchased_visits as (
  	select
    	distinct visit_id
    from clique_bait.events e
    join clique_bait.event_identifier ei on ei.event_type = e.event_type
    where ei.event_name = 'Purchase'
)
select
	u.user_id,
    e.visit_id,
    min(event_time) as visit_start_time,
    count(case when ei.event_name = 'Page View' then 1 end) as page_views,
    count(case when ei.event_name = 'Add to Cart' then 1 end) as cart_adds,
    case
    	when e.visit_id in (select * from purchased_visits) then 1
        else 0
    end as purchased,
    ci.campaign_name,
    count(case when ei.event_name = 'Ad Impression' then 1 end) as ad_impression,
    count(case when ei.event_name = 'Ad Click' then 1 end) as ad_click,
    string_agg(case when ei.event_name = 'Add to Cart' then ph.page_name end, ', ' order by e.sequence_number) as product_list
from clique_bait.events e
left join clique_bait.users u on u.cookie_id = e.cookie_id
left join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
left join clique_bait.event_identifier ei on e.event_type = ei.event_type
left join clique_bait.campaign_identifier ci on 
ci.start_date >= to_char(e.event_time, 'YYYY-MM-DD')::date and 
to_char(e.event_time, 'YYYY-MM-DD')::date <= ci.end_date
group by 1, 2, 7
```
| user_id | visit_id | visit_start_time           | page_views | cart_adds | purchased | campaign_name                     | ad_impression | ad_click | product_list                                                                          |
| ------- | -------- | -------------------------- | ---------- | --------- | --------- | --------------------------------- | ------------- | -------- | ------------------------------------------------------------------------------------- |
| 1       | 02a5d5   | 2020-02-26 16:57:26.260871 | 4          | 0         | 0         |                                   | 0             | 0        |                                                                                       |
| 1       | 0826dc   | 2020-02-26 05:58:37.918618 | 1          | 0         | 0         |                                   | 0             | 0        |                                                                                       |
| 1       | 0fc437   | 2020-02-04 17:49:49.602976 | 10         | 6         | 1         |                                   | 1             | 1        | Tuna, Russian Caviar, Black Truffle, Abalone, Crab, Oyster                            |
| 1       | 30b94d   | 2020-03-15 13:12:54.023936 | 9          | 7         | 1         |                                   | 1             | 1        | Salmon, Kingfish, Tuna, Russian Caviar, Abalone, Lobster, Crab                        |
| 1       | 41355d   | 2020-03-25 00:11:17.860655 | 6          | 1         | 0         |                                   | 0             | 0        | Lobster                                                                               |
| 1       | ccf365   | 2020-02-04 19:16:09.182546 | 7          | 3         | 1         |                                   | 0             | 0        | Lobster, Crab, Oyster                                                                 |
| 1       | eaffde   | 2020-03-25 20:06:32.342989 | 10         | 8         | 1         |                                   | 1             | 1        | Salmon, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster           |
| 1       | f7c798   | 2020-03-15 02:23:26.312543 | 9          | 3         | 1         |                                   | 0             | 0        | Russian Caviar, Crab, Oyster                                                          |
| 2       | 0635fb   | 2020-02-16 06:42:42.73573  | 9          | 4         | 1         |                                   | 0             | 0        | Salmon, Kingfish, Abalone, Crab                                                       |
| 2       | 1f1198   | 2020-02-01 21:51:55.078775 | 1          | 0         | 0         | Half Off - Treat Your Shellf(ish) | 0             | 0        |                                                                                       |
| 2       | 3b5871   | 2020-01-18 10:16:32.158475 | 9          | 6         | 1         | Half Off - Treat Your Shellf(ish) | 1             | 1        | Salmon, Kingfish, Russian Caviar, Black Truffle, Lobster, Oyster                      |
| 2       | 49d73d   | 2020-02-16 06:21:27.138532 | 11         | 9         | 1         |                                   | 1             | 1        | Salmon, Kingfish, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster |
| 2       | 910d9a   | 2020-02-01 10:40:46.875968 | 8          | 1         | 0         | Half Off - Treat Your Shellf(ish) | 0             | 0        | Abalone                                                                               |
| 2       | c5c0ee   | 2020-01-18 10:35:22.765382 | 1          | 0         | 0         | Half Off - Treat Your Shellf(ish) | 0             | 0        |                                                                                       |
| 2       | d58cbd   | 2020-01-18 23:40:54.761906 | 8          | 4         | 0         | Half Off - Treat Your Shellf(ish) | 0             | 0        | Kingfish, Tuna, Abalone, Crab                                                         |
| 2       | e26a84   | 2020-01-18 16:06:40.90728  | 6          | 2         | 1         | Half Off - Treat Your Shellf(ish) | 0             | 0        | Salmon, Oyster                                                                        |


 - Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
 - Does clicking on an impression lead to higher purchase rates?
 - What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
 - What metrics can you use to quantify the success or failure of each campaign compared to eachother?

