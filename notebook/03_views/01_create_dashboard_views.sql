-- 1. vw_category_revenue_by_city_month
CREATE VIEW fmcg.vw_category_revenue_by_city_month AS
SELECT
    DATE_TRUNC('month', s.SalesDate)::DATE AS month,
    ci.CityID,
    ci.CityName,
    c.CategoryName,
    SUM(s.TotalPrice) AS total_revenue,
    SUM(s.Quantity) AS total_quantity,
    COUNT(DISTINCT s.TransactionNumber) AS total_orders,
    ROUND(SUM(s.TotalPrice) * 100 / SUM(SUM(s.TotalPrice)) OVER (PARTITION BY DATE_TRUNC('month', s.SalesDate), ci.CityID), 2) AS pct_of_city_month
FROM fmcg.sales AS s
JOIN fmcg.products AS p ON s.ProductID = p.ProductID
JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
JOIN fmcg.customers AS cu ON s.CustomerID = cu.CustomerID
JOIN fmcg.cities AS ci ON cu.CityID = ci.CityID
WHERE s.SalesDate < '2018-05-01'
GROUP BY DATE_TRUNC('month', s.SalesDate), ci.CityID, ci.CityName, c.CategoryName;

-- 2. vw_class_performance
CREATE VIEW fmcg.vw_class_performance AS
SELECT
    p.Class,
    c.CategoryName,
    COUNT(DISTINCT p.ProductID) AS product_count,
    SUM(s.Quantity) AS total_quantity,
    SUM(s.TotalPrice) AS total_revenue,
    ROUND(AVG(s.TotalPrice), 2) AS avg_order_value,
    ROUND(SUM(s.TotalPrice) * 100 / SUM(SUM(s.TotalPrice)) OVER (), 2) AS pct_total_revenue
FROM fmcg.sales AS s
JOIN fmcg.products AS p ON s.ProductID = p.ProductID
JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
WHERE s.SalesDate < '2018-05-01'
GROUP BY p.Class, c.CategoryName;

-- 3. vw_product_performance
CREATE VIEW fmcg.vw_product_performance AS
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    SUM(s.TotalPrice) AS total_revenue,
    SUM(s.Quantity) AS total_quantity,
    COUNT(*) AS num_transactions,
    RANK() OVER (ORDER BY SUM(s.TotalPrice) DESC) AS revenue_rank
FROM fmcg.sales AS s
JOIN fmcg.products AS p ON s.ProductID = p.ProductID
JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
WHERE s.SalesDate < '2018-05-01'
GROUP BY p.ProductID, p.ProductName, c.CategoryName;

-- 4. vw_product_segment
CREATE VIEW fmcg.vw_product_segment AS
WITH product_metrics AS (
    SELECT
        p.ProductID, p.ProductName, p.Price, p.Class, c.CategoryName,
        SUM(s.Quantity) AS total_quantity,
        ROUND(SUM(s.TotalPrice) / NULLIF(SUM(s.Quantity), 0), 2) AS avg_revenue_per_unit,
        PERCENT_RANK() OVER (ORDER BY SUM(s.Quantity)) AS quantity_percentile,
        PERCENT_RANK() OVER (ORDER BY SUM(s.TotalPrice) / NULLIF(SUM(s.Quantity), 0)) AS avg_revenue_per_unit_percentile
    FROM fmcg.sales AS s
    JOIN fmcg.products AS p ON s.ProductID = p.ProductID
    JOIN fmcg.categories AS c ON p.CategoryID = c.CategoryID
    WHERE s.SalesDate < '2018-05-01'
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
FROM product_metrics;

-- 5. vw_customer_segment_fm
CREATE VIEW fmcg.vw_customer_segment_fm AS
WITH customer_stats AS (
    SELECT
        s.CustomerID,
        ci.CityID,
        ci.CityName,
        COUNT(DISTINCT s.TransactionNumber) AS frequency,
        SUM(s.TotalPrice) AS monetary,
        SUM(s.Quantity) AS total_quantity
    FROM fmcg.sales AS s
    JOIN fmcg.customers AS cu ON s.CustomerID = cu.CustomerID
    JOIN fmcg.cities AS ci ON cu.CityID = ci.CityID
    WHERE s.SalesDate < '2018-05-01'
    GROUP BY s.CustomerID, ci.CityID, ci.CityName
),
fm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM customer_stats
),
fm_combined AS (
    SELECT *, (f_score * 10 + m_score) AS fm_score
    FROM fm_scores
)
SELECT *,
    CASE
        WHEN fm_score IN (55,54,45,44) THEN 'Champions'
        WHEN fm_score IN (53,43,35,34) THEN 'Loyal'
        WHEN fm_score IN (52,51,42,41,25,24,15,14) THEN 'Potential loyalist'
        WHEN fm_score IN (33,32,31,23,13) THEN 'Need attention'
        WHEN fm_score IN (22,21,12,11) THEN 'Lost customers'
    END AS segment
FROM fm_combined;

-- 6. vw_customer_segment_summary
CREATE VIEW fmcg.vw_customer_segment_summary AS
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_monetary,
    ROUND(SUM(monetary) / SUM(frequency), 2) AS aov,
    ROUND(SUM(total_quantity) / SUM(frequency), 2) AS avg_basket_size
FROM fmcg.vw_customer_segment_fm
GROUP BY segment;

-- 7. vw_employee_performance
CREATE VIEW fmcg.vw_employee_performance AS
WITH emp_stats AS (
    SELECT
        e.EmployeeID,
        CONCAT(e.FirstName, ' ', e.MiddleInitial, ' ', e.LastName) AS employee_name,
        e.Gender,
        ci.CityID,
        ci.CityName,
        SUM(s.TotalPrice) AS total_revenue,
        SUM(s.Quantity) AS total_quantity,
        COUNT(DISTINCT s.TransactionNumber) AS total_orders,
        RANK() OVER (ORDER BY SUM(s.TotalPrice) DESC) AS revenue_rank
    FROM fmcg.sales AS s
    JOIN fmcg.employees AS e ON s.SalesPersonID = e.EmployeeID
    JOIN fmcg.cities AS ci ON e.CityID = ci.CityID
    WHERE s.SalesDate < '2018-05-01'
    GROUP BY e.EmployeeID, e.FirstName, e.MiddleInitial, e.LastName, e.Gender, ci.CityID, ci.CityName
)
SELECT *,
    CASE
        WHEN revenue_rank <= 3 THEN 'Top Performer'
        WHEN revenue_rank > (SELECT MAX(revenue_rank) FROM emp_stats) - 3 THEN 'Underperformer'
        ELSE 'Normal'
    END AS performance_tier
FROM emp_stats;

-- 8. vw_employee_monthly_trend
CREATE VIEW fmcg.vw_employee_monthly_trend AS
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.MiddleInitial, ' ', e.LastName) AS employee_name,
    e.Gender,
    DATE_TRUNC('month', s.SalesDate)::DATE AS month,
    SUM(s.TotalPrice) AS monthly_revenue,
    SUM(s.TotalPrice) - LAG(SUM(s.TotalPrice)) OVER (PARTITION BY e.EmployeeID ORDER BY DATE_TRUNC('month', s.SalesDate)) AS mom_change
FROM fmcg.sales AS s
JOIN fmcg.employees AS e ON s.SalesPersonID = e.EmployeeID
WHERE s.SalesDate < '2018-05-01'
GROUP BY e.EmployeeID, e.FirstName, e.MiddleInitial, e.LastName, e.Gender, DATE_TRUNC('month', s.SalesDate);

SELECT table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'fmcg'
ORDER BY table_name;