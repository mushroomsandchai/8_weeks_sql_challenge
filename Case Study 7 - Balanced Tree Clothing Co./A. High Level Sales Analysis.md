# A. High Level Sales Analysis
### 1. What was the total quantity sold for all products?
### 2. What is the total generated revenue for all products before discounts?
### 3. What was the total discount amount for all products?
```sql
select
    sum(qty) as total_quantity,
    sum(qty * price) as total_revenue,
    round(sum((((qty * price) * discount) / 100.0)), 2) as total_discount
from balanced_tree.sales
```

| total_quantity | total_revenue | total_discount |
| -------------- | ------------- | -------------- |
| 45216          | 1289453       | 156229.14      |