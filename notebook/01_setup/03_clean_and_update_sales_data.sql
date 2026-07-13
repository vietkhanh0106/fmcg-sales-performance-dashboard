--1. Update total price
UPDATE fmcg.sales AS s 
SET TotalPrice = ROUND(p.Price * s.Quantity * (1 - s.Discount), 2)
FROM fmcg.products AS p
WHERE s.ProductID = p.ProductID;

--2. Check null and duplicate
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE SalesDate IS NULL)  AS null_date,
    COUNT(*) FILTER (WHERE TotalPrice IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE Quantity IS NULL)   AS null_qty
FROM fmcg.sales;

SELECT SalesID, COUNT(*) AS cnt
FROM fmcg.sales
GROUP BY SalesID
HAVING COUNT(*) > 1;

-- No duplicate, check null percentage
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE SalesDate IS NULL) AS null_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE SalesDate IS NULL) / COUNT(*), 2) AS null_pct
FROM fmcg.sales;
-- Null value in SalesDate < 5% -> safe to delete
-- Delete null value in SalesDate
DELETE FROM fmcg.sales
WHERE SalesDate IS NULL;
-- Verify
SELECT COUNT(*) AS remaining_rows FROM fmcg.sales;

