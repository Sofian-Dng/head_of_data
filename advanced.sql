-- Answer all the questions below with advanced SQL queries (using partitioning, CASE WHENs)
-- Remember to add a screenshot of the BigQuery results inside the basics/ folder

-- 1. Identify clients who placed more orders than the average

WITH orders_by_client AS (
  SELECT
    c.customer_unique_id,
    COUNT(*) AS total_orders
  FROM
    `head-of-data-agelle.BRONZE.orders` AS o
JOIN
    `head-of-data-agelle.BRONZE.customers` AS c
ON
    o.customer_id = c.customer_id
GROUP BY
    c.customer_unique_id
),
average_orders AS (
  SELECT
    AVG(total_orders) AS avg_total_orders
  FROM
    orders_by_client
)

SELECT
  obc.customer_unique_id,
  cust.customer_city AS city,
  cust.customer_state AS state,
  obc.total_orders
FROM
  orders_by_client AS obc
JOIN
  average_orders AS avg_o
ON
  obc.total_orders > avg_o.avg_total_orders
JOIN
  `head-of-data-agelle.BRONZE.customers` AS cust
ON
  obc.customer_unique_id = cust.customer_unique_id
ORDER BY
  obc.total_orders DESC;


-- 2. Categorize customers based on their total spending (using CASE WHEN)

WITH customer_spending AS (
  SELECT
    o.customer_id,
    SUM(IFNULL(oi.price, 0) + IFNULL(oi.freight_value, 0)) AS total_spent
  FROM
    `head-of-data-agelle.BRONZE.orders` AS o
JOIN
    `head-of-data-agelle.BRONZE.order_items` AS oi
USING(order_id)
GROUP BY
    o.customer_id
)

SELECT
  cust.customer_id,
  cust.customer_unique_id,
  ROUND(cs.total_spent, 2) AS total_spent,
  CASE
    WHEN cs.total_spent < 100 THEN 'Low'
    WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium'
    ELSE 'High'
  END AS spending_category
FROM
  customer_spending AS cs
JOIN
  `head-of-data-agelle.BRONZE.customers` AS cust
USING(customer_id)
ORDER BY
  cs.total_spent DESC;


-- 3. Calculate the difference between first and last order for each customer, and the global average

SELECT
  c.customer_unique_id,
  DATE_DIFF(
    MAX(DATE(o.order_purchase_timestamp)),
    MIN(DATE(o.order_purchase_timestamp)),
    DAY
  ) AS days_difference,
  ROUND(
    AVG(
      DATE_DIFF(
        MAX(DATE(o.order_purchase_timestamp)),
        MIN(DATE(o.order_purchase_timestamp)),
        DAY
      )
    ) OVER (),
    2
  ) AS avg_days_difference
FROM
  `head-of-data-agelle.BRONZE.orders` AS o
JOIN
  `head-of-data-agelle.BRONZE.customers` AS c
USING(customer_id)
GROUP BY
  c.customer_unique_id
ORDER BY
  days_difference DESC;


-- 4. Find each customer's first product category purchased

WITH customer_total_sales AS (
  SELECT
    o.customer_id,
    ROUND(SUM(IFNULL(oi.price, 0) + IFNULL(oi.freight_value, 0)), 2) AS total_sales,
    ROUND(SUM(IFNULL(oi.price, 0) + IFNULL(oi.freight_value, 0)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_sales,
    MIN(DATE(o.order_purchase_timestamp)) AS first_order_date
  FROM
    `head-of-data-agelle.BRONZE.orders` AS o
JOIN
    `head-of-data-agelle.BRONZE.order_items` AS oi
USING(order_id)
GROUP BY
    o.customer_id
),
first_category_purchased AS (
  SELECT
    o.customer_id,
    p.product_category_name AS first_category
  FROM
    `head-of-data-agelle.BRONZE.orders` AS o
JOIN
    `head-of-data-agelle.BRONZE.order_items` AS oi
USING(order_id)
JOIN
    `head-of-data-agelle.BRONZE.products` AS p
USING(product_id)
QUALIFY
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_purchase_timestamp, oi.order_item_id) = 1
)

SELECT
  cts.customer_id,
  cts.total_sales,
  cts.avg_order_sales,
  cts.first_order_date,
  fcp.first_category
FROM
  customer_total_sales AS cts
LEFT JOIN
  first_category_purchased AS fcp
USING(customer_id)
ORDER BY
  cts.total_sales DESC
LIMIT 1000;
