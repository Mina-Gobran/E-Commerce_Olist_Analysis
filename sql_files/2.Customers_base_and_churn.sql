/* Questions to answer:
1. How many repeat customers do we have?
2. What is the customer lifetime value (CLV) for our customers?
3. Where is our highest customer base located?
4. What is the Churn rate for our customers?  (customers not ordering in the last 6 months)
*/

-- Repeat customers bascket: Classify customers based on their order count and calculate the number of customers in each category along with their percentage of the total customer base.
SELECT
    CASE -- Classify customers based on their order count using a CASE statement
        WHEN order_count = 1 THEN 'One-time customer'
        WHEN order_count = 2 THEN 'Repeat customer (2 orders)'
        WHEN order_count >= 3 THEN 'Repeat customer (3+ orders)'
    END AS customer_type,
    COUNT(customer_unique_id) AS number_of_customers,
    ROUND(COUNT(customer_unique_id) * 100 / SUM(COUNT(customer_unique_id)) OVER(), 2) AS percentage
FROM ( -- Subquery to calculate the order count for each customer
    SELECT
        customers.customer_unique_id,
        COUNT(DISTINCT orders.order_id) AS order_count
    FROM
        customers
    JOIN orders USING (customer_id)
    WHERE
        orders.order_status = 'delivered'
    GROUP BY
        customers.customer_unique_id
) customer_orders
GROUP BY customer_type
ORDER BY number_of_customers DESC;

-- Customer Lifetime Value (CLV)
SELECT
    customers.customer_unique_id,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(order_items.price + order_items.freight_value) AS lifetime_value, -- total CLV for customers using customer unique id
    ROUND(AVG(order_items.price + order_items.freight_value), 2) AS avg_order_value, -- calculating average order value for customers
    MIN(orders.order_purchase_timestamp) AS first_purchase_date,
    MAX(orders.order_purchase_timestamp) AS last_purchase_date 
FROM
    customers
JOIN orders USING (customer_id)
JOIN order_items USING (order_id)
WHERE
    orders.order_status = 'delivered'
GROUP BY
    customers.customer_unique_id
ORDER BY
    lifetime_value DESC;

-- Customer base location
SELECT
    customers.customer_state,
    customers.customer_city,
    COUNT(DISTINCT customers.customer_unique_id) AS total_customers,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(order_items.price + order_items.freight_value) AS total_revenue,
    ROUND(AVG(order_items.price + order_items.freight_value), 2) AS avg_order_value
FROM
    customers
JOIN orders USING (customer_id)
JOIN order_items USING (order_id)
WHERE
    orders.order_status = 'delivered'
GROUP BY
    customers.customer_state,
    customers.customer_city
ORDER BY
    total_customers DESC;

--Churn rate:
WITH dataset_max_date AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS max_date
    FROM orders
)
SELECT
    customers.customer_unique_id,
    customers.customer_state,
    customers.customer_city,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    MAX(orders.order_purchase_timestamp) AS last_purchase_date,
    (SELECT max_date FROM dataset_max_date) - MAX(orders.order_purchase_timestamp)::DATE AS days_since_last_order,
    SUM(order_items.price + order_items.freight_value) AS lifetime_value,
    CASE -- Using a CASE statement to classify customers into baskets.
        WHEN MAX(orders.order_purchase_timestamp) < (SELECT max_date FROM dataset_max_date) - INTERVAL '6 months' THEN 'At Risk'
        WHEN MAX(orders.order_purchase_timestamp) < (SELECT max_date FROM dataset_max_date) - INTERVAL '3 months' THEN 'Warning'
        ELSE 'Active'
    END AS churn_status
FROM
    customers
JOIN orders USING (customer_id)
JOIN order_items USING (order_id)
WHERE
    orders.order_status = 'delivered'
GROUP BY
    customers.customer_unique_id,
    customers.customer_state,
    customers.customer_city
ORDER BY
    days_since_last_order DESC;