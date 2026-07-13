--1. Revenue & ranking by City 
SELECT
    ci.CityID,
    ci.CityName,
    SUM(s.TotalPrice) AS total_revenue,
    SUM(s.Quantity) AS total_qty,
    COUNT(DISTINCT s.CustomerID) AS unique_customers,
    RANK() OVER (ORDER BY SUM(s.TotalPrice) DESC) AS city_rank
FROM fmcg.sales AS s
JOIN fmcg.customers AS cu ON s.CustomerID = cu.CustomerID
JOIN fmcg.cities AS ci ON cu.CityID = ci.CityID
GROUP BY ci.CityID, ci.CityName
ORDER BY total_revenue DESC;

-- 2. Quantity gap comparison between cities
WITH city_quantity AS (
    SELECT
        ci.CityID,
        ci.CityName,
        SUM(s.Quantity) AS total_qty
    FROM fmcg.sales AS s
    JOIN fmcg.customers AS cu ON s.CustomerID = cu.CustomerID
    JOIN fmcg.cities AS ci ON cu.CityID = ci.CityID
    GROUP BY ci.CityID, ci.CityName
)
SELECT
    CityID,
    CityName,
    total_qty,
    RANK() OVER (ORDER BY total_qty DESC) AS qty_rank,
    total_qty - ROUND(AVG(total_qty) OVER (), 2) AS qty_diff_vs_avg,
    total_qty - LAG(total_qty) OVER (ORDER BY total_qty DESC) AS qty_diff_from_prior_rank
FROM city_quantity
ORDER BY total_qty DESC;


--5.3. Efficiency indicators for market strategy review
WITH city_summary AS (
    SELECT
        ci.CityID,
        ci.CityName,
        SUM(s.TotalPrice) AS total_revenue,
        COUNT(DISTINCT s.CustomerID) AS unique_customers
    FROM fmcg.sales AS s
    JOIN fmcg.customers AS cu ON s.CustomerID = cu.CustomerID
    JOIN fmcg.cities AS ci ON cu.CityID = ci.CityID
    GROUP BY ci.CityID, ci.CityName
)
SELECT
    CityID,
    CityName,
    total_revenue,
    unique_customers,
    ROUND(total_revenue / unique_customers, 2) AS revenue_per_customer,
    CASE NTILE(4) OVER (ORDER BY total_revenue DESC)
        WHEN 1 THEN 'Strong Market'
        WHEN 2 THEN 'Above Average'
        WHEN 3 THEN 'Below Average'
        WHEN 4 THEN 'Weak Market'
    END AS revenue_tier
FROM city_summary
ORDER BY total_revenue DESC;