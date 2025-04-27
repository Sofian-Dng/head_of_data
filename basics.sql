-- Answer all the questions below with basics SQL queries
-- don't forget to add a screenshot of the result from BigQuery directly in the basics/ folder

-- 1. What are the possible values of an order status? 

SELECT
  DISTINCT order_status
FROM
  `head-of-data-agelle.BRONZE.orders`
ORDER BY
  order_status;


-- 2. Who are the 5 last customers that purchased a DELIVERED order (order with status DELIVERED)?
-- print their customer_id, their unique_id, and city

SELECT
  o.customer_id,
  c.customer_unique_id,
  c.customer_city
FROM
  `head-of-data-agelle.BRONZE.orders`    AS o
JOIN
  `head-of-data-agelle.BRONZE.customers` AS c
  USING(customer_id)
WHERE
  o.order_status = 'delivered'
ORDER BY
  o.order_purchase_timestamp DESC
LIMIT
  5;


-- 3. Add a column is_sp which returns 1 if the customer is from São Paulo and 0 otherwise

SELECT
  c.customer_id,
  c.customer_unique_id,
  c.customer_city,
  c.customer_state,
  CASE
    WHEN c.customer_city = 'São Paulo' THEN 1
    ELSE 0
  END AS is_sp
FROM
  `head-of-data-agelle.BRONZE.customers` AS c;


-- 4. add a new column: what's the product category associated to the order?

SELECT
  o.order_id,
  (
    SELECT
      ARRAY_AGG(DISTINCT p2.product_category_name
                ORDER BY p2.product_category_name)
    FROM
      `head-of-data-agelle.BRONZE.order_items` AS oi2
    JOIN
      `head-of-data-agelle.BRONZE.products`    AS p2
      ON oi2.product_id = p2.product_id
    WHERE
      oi2.order_id = o.order_id
      AND p2.product_category_name IS NOT NULL
  ) AS product_categories
FROM
  `head-of-data-agelle.BRONZE.orders` AS o
ORDER BY
  o.order_id;
