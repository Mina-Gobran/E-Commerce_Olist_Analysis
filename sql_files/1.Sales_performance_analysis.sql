/* Questions to answer:
1. What was the monthly and quarterly sales trends?
2. What was the average order value over time?
3. Which product categories generated the most sales revenue?
*/

--Sales trends
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) AS month, -- Extracting month from the order purchase timestamp
    COUNT(DISTINCT orders.order_id) AS total_orders, -- Counting distinct orders to get total number of orders
    SUM(order_items.price + order_items.freight_value) AS total_revenue, -- Getting total revenue 
    ROUND(AVG(order_items.price + order_items.freight_value), 2) AS avg_order_value -- Getting average order value
FROM 
    orders
JOIN order_items USING (order_id)
WHERE
    orders.order_status = 'delivered' -- Considering only delivered orders for accurate sales analysis
GROUP BY
    month
ORDER BY
    month;


--Product categories generating the most sales revenue
SELECT
    products_trans.product_category_name_english,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    SUM(order_items.price + order_items.freight_value) AS total_revenue,
    ROUND(AVG(order_items.price + order_items.freight_value), 2) AS avg_order_value
FROM
    orders
JOIN order_items USING (order_id)
JOIN products USING (product_id)
JOIN product_category_name_translation AS products_trans 
    ON products.product_category_name = products_trans.product_category_name
WHERE
    orders.order_status = 'delivered'
GROUP BY
    products_trans.product_category_name_english
ORDER BY
    total_revenue DESC;