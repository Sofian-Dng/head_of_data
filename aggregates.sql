-- Answer all the questions below with aggregate SQL queries
-- Don't forget to add a screenshot of the result from BigQuery inside the basics/ folder

-- 1. What was the total revenue and order count for 2018?

SELECT
  COUNT(DISTINCT o.order_id) AS total_orders,
  SUM(oi.price + oi.freight_value) AS total_revenue
FROM
  `head-of-data-agelle.BRONZE.orders` AS o
INNER JOIN
  `head-of-data-agelle.BRONZE.order_items` AS oi
ON
  o.order_id = oi.order_id
WHERE
  EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018;


-- 2. What is the total_sales, average_order_sales, and first_order_date by customer?
-- Round the values to 2 decimal places, order by total_sales descending
-- Limit to 1000 results

SELECT
  o.customer_id,
  ROUND(SUM(IFNULL(oi.price, 0) + IFNULL(oi.freight_value, 0)), 2) AS total_sales,
  ROUND(SUM(IFNULL(oi.price, 0) + IFNULL(oi.freight_value, 0)) / COUNT(DISTINCT o.order_id), 2) AS average_order_sales,
  CAST(MIN(o.order_purchase_timestamp) AS DATE) AS first_order_date
FROM
  `head-of-data-agelle.BRONZE.orders` AS o
JOIN
  `head-of-data-agelle.BRONZE.order_items` AS oi
USING(order_id)
GROUP BY
  o.customer_id
ORDER BY
  total_sales DESC
LIMIT
  1000;


-- 3. Who are the top 10 most successful sellers?

SELECT
  s.seller_id,
  s.seller_city,
  s.seller_state,
  ROUND(SUM(COALESCE(oi.price, 0) + COALESCE(oi.freight_value, 0)), 2) AS total_sales,
  COUNT(DISTINCT oi.order_id) AS number_of_orders,
  COUNT(oi.order_item_id) AS number_of_items_sold
FROM
  `head-of-data-agelle.BRONZE.order_items` AS oi
JOIN
  `head-of-data-agelle.BRONZE.sellers` AS s
USING(seller_id)
GROUP BY
  s.seller_id, s.seller_city, s.seller_state
ORDER BY
  total_sales DESC
LIMIT
  10;


-- 4. What’s the preferred payment method by product category?

WITH category_payment AS (
  SELECT
    p.product_category_name,
    pay.payment_type,
    COUNT(DISTINCT oi.order_id) AS number_of_orders
  FROM
    `head-of-data-agelle.BRONZE.order_items` AS oi
  JOIN
    `head-of-data-agelle.BRONZE.products` AS p
  ON
    oi.product_id = p.product_id
  JOIN
    `head-of-data-agelle.BRONZE.payments` AS pay
  ON
    oi.order_id = pay.order_id
    AND pay.payment_sequential = 1  -- Only consider the first payment per order
  GROUP BY
    p.product_category_name, pay.payment_type
)

SELECT
  product_category_name,
  payment_type AS preferred_payment_method,
  number_of_orders
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY number_of_orders DESC) AS row_num
  FROM
    category_payment
)
WHERE row_num = 1
ORDER BY
  product_category_name;


