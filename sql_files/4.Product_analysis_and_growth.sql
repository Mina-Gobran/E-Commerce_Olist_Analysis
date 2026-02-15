-- What was Product Category Growth? Month-over-Month (MoM)

WITH monthly_category_sales AS (
    SELECT 
        DATE_TRUNC('month', orders.order_purchase_timestamp) AS month,
        products.product_category_name,
        SUM(order_items.price + order_items.freight_value) AS total_revenue,
        COUNT(DISTINCT orders.order_id) AS total_orders
    FROM 
        orders
    JOIN 
        order_items USING (order_id)
    JOIN 
        products USING (product_id)
    WHERE 
        orders.order_status = 'delivered'
        AND products.product_category_name IS NOT NULL
    GROUP BY 
        DATE_TRUNC('month', orders.order_purchase_timestamp),
        products.product_category_name
),
top_5_categories AS (
    SELECT 
        product_category_name
    FROM (
        SELECT 
            product_category_name,
            SUM(total_revenue) AS overall_revenue
        FROM 
            monthly_category_sales
        GROUP BY 
            product_category_name
        ORDER BY 
            overall_revenue DESC
        LIMIT 5
    ) AS top_cats
)
SELECT 
    monthly_category_sales.month,
    monthly_category_sales.product_category_name,
    monthly_category_sales.total_revenue,
    monthly_category_sales.total_orders,
    LAG(monthly_category_sales.total_revenue) OVER (
        PARTITION BY monthly_category_sales.product_category_name 
        ORDER BY monthly_category_sales.month
    ) AS previous_month_revenue, -- using LAG to get the previous month's revenue for MoM calculation.
    ROUND(
        ((monthly_category_sales.total_revenue - LAG(monthly_category_sales.total_revenue) OVER (
            PARTITION BY monthly_category_sales.product_category_name 
            ORDER BY monthly_category_sales.month
        )) * 100 / 
        NULLIF(LAG(monthly_category_sales.total_revenue) OVER (
            PARTITION BY monthly_category_sales.product_category_name 
            ORDER BY monthly_category_sales.month
        ), 0)), 
        2
    ) AS mom_growth_rate_pct
FROM 
    monthly_category_sales
INNER JOIN 
    top_5_categories 
    ON monthly_category_sales.product_category_name = top_5_categories.product_category_name
ORDER BY 
    monthly_category_sales.total_revenue DESC,
    monthly_category_sales.month;