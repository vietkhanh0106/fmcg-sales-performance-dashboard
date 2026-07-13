--1. Sales & Ranking
WITH emp_stats AS (
    SELECT
        e.EmployeeID,
        CONCAT(e.FirstName,' ',e.MiddleInitial,' ',e.LastName) AS employee_name,
        e.Gender,
        SUM(s.TotalPrice) AS total_revenue,
        SUM(s.Quantity) AS total_quantity,
        COUNT(DISTINCT s.TransactionNumber) AS total_orders,
        RANK() OVER(ORDER BY SUM(s.TotalPrice) DESC) AS revenue_rank
    FROM fmcg.sales AS s 
    JOIN fmcg.employees AS e ON s.SalesPersonID = e.EmployeeID
    GROUP BY e.EmployeeID
)
SELECT 
    *,
    CASE 
        WHEN revenue_rank <= 3 THEN 'Top Performer'
        WHEN revenue_rank > (SELECT MAX(revenue_rank) FROM emp_stats) - 3 THEN 'Underperformer'
        ELSE 'Normal'
    END AS performance_tier
FROM emp_stats
ORDER BY revenue_rank;

--2. Monthly sales trend by employee
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName,' ',e.MiddleInitial,' ',e.LastName) AS employee_name,
    e.Gender,
    DATE_TRUNC('month', s.SalesDate)::DATE AS month,
    SUM(s.TotalPrice) AS monthly_revenue,
    SUM(s.TotalPrice) - LAG(SUM(s.TotalPrice)) OVER (PARTITION BY e.EmployeeID ORDER BY DATE_TRUNC('month', s.SalesDate)) AS mom_change
FROM fmcg.sales AS s
JOIN fmcg.employees AS e ON s.SalesPersonID = e.EmployeeID
GROUP BY e.EmployeeID, DATE_TRUNC('month', s.SalesDate)
ORDER BY e.EmployeeID, month


