--1. Revenue by month
SELECT
    date_trunc('month',SalesDate)::DATE AS month,
    COUNT(DISTINCT TransactionNumber) AS total_orders,
    SUM(Quantity) AS total_quantity,
    ROUND(SUM(TotalPrice),2) AS total_revenue,
    ROUND(AVG(TotalPrice),2) AS aov,
    ROUND(SUM(TotalPrice) - LAG(SUM(TotalPrice)) OVER(ORDER BY date_trunc('month',SalesDate)),2) AS month_change
FROM fmcg.sales
GROUP BY date_trunc('month', SalesDate)
ORDER BY date_trunc('month',SalesDate);

--2. Monthly revenue share by category
WITH monthly_cat AS (
    SELECT
        DATE_TRUNC('month',SalesDate)::DATE AS month,
        c.CategoryName,
        SUM(s.TotalPrice) AS cat_revenue
    FROM fmcg.sales AS s 
    JOIN fmcg.products AS p ON s.ProductID = p.ProductID
    JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
    GROUP BY 
        DATE_TRUNC('month',SalesDate),
        c.CategoryName
)
SELECT
    month,
    CategoryName,
    cat_revenue,
    ROUND(cat_revenue * 100 / SUM(cat_revenue) OVER(PARTITION BY month),2) AS pct_of_month
FROM monthly_cat
ORDER BY month, cat_revenue DESC





