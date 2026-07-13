--1. Product ranking
WITH product_performance AS (
    SELECT
        p.ProductID,
        p.ProductName,
        c.CategoryName,
        SUM(s.TotalPrice) AS total_revenue,
        SUM(s.Quantity) AS total_quantity,
        COUNT(*) AS num_transactions,
        RANK() OVER(ORDER BY SUM(s.TotalPrice) DESC) AS revenue_rank
    FROM fmcg.sales AS s 
    JOIN fmcg.products AS p ON s.ProductID = p.ProductID 
    JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
    GROUP BY p.ProductID, p.ProductName, c.CategoryName
)
SELECT * FROM product_performance
WHERE revenue_rank <= 5 OR revenue_rank > (SELECT MAX(revenue_rank) - 5 FROM product_performance)
ORDER BY revenue_rank;

--2. Product segmentation by quantity vs revenue
WITH product_metrics AS(
    SELECT
        p.ProductID, p.ProductName, p.Price, p.Class, c.CategoryName,
        SUM(s.Quantity) AS total_quantity,
        ROUND(SUM(s.TotalPrice)/NULLIF(SUM(s.Quantity),0),2) AS avg_revenue_per_unit,
        PERCENT_RANK() OVER(ORDER BY SUM(s.Quantity)) AS quantity_percentile,
        PERCENT_RANK() OVER(ORDER BY SUM(s.TotalPrice)/NULLIF(SUM(s.Quantity),0)) AS avg_revenue_per_unit_percentile
    FROM fmcg.sales AS s
    JOIN fmcg.products AS p ON s.ProductID = p.ProductID
    JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
    GROUP BY p.ProductID, p.ProductName, p.Price, p.Class, c.CategoryName
)
SELECT *,
    CASE
        WHEN quantity_percentile >= 0.75 AND avg_revenue_per_unit_percentile < 0.25
        THEN 'High Volume / Low Efficiency'
        WHEN quantity_percentile >= 0.75 AND avg_revenue_per_unit_percentile >= 0.75
        THEN 'High Volume / High Efficiency'
        WHEN quantity_percentile < 0.25 AND avg_revenue_per_unit_percentile >= 0.75
        THEN 'Low Volume / High Efficiency'
        ELSE 'Standard'
    END AS product_segment
FROM product_metrics
ORDER BY quantity_percentile DESC;

--3. Class impact on sale performance
SELECT
    p.Class,
    COUNT(DISTINCT p.ProductID) AS product_count,
    SUM(s.Quantity) AS total_quantity,
    SUM(s.TotalPrice) AS total_revenue,
    ROUND(AVG(s.TotalPrice),2) AS avg_order_value,
    ROUND(SUM(s.TotalPrice)*100 / SUM(SUM(s.TotalPrice)) OVER(), 2) AS pct_total_revenue
FROM fmcg.sales AS s
JOIN fmcg.products AS p ON s.ProductID = p.ProductID
GROUP BY p.Class
ORDER BY total_revenue