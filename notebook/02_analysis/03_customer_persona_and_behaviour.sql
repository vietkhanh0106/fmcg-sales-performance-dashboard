--1. Customer Segmentation 
-- The analysis follows the RFM framework (Recency - Frequency - Monetary) to build customer persona.
-- As the 4-month dataset is quite short, run a max gap days analysis to assess whether recency should be included in the analysis.
-- Gap days analysis

WITH customer_purchase_date AS (
    SELECT 
        CustomerID,
        SalesDate::DATE AS purchase_date
    FROM fmcg.sales 
    GROUP BY CustomerID, SalesDate::DATE 
),
gaps AS (
    SELECT 
        CustomerID,
        purchase_date,
        LAG(purchase_date) OVER(PARTITION BY CustomerID ORDER BY purchase_date) AS previous_purchase_date,
        purchase_date - LAG(purchase_date) OVER(PARTITION BY CustomerID ORDER BY purchase_date) AS gap_days
    FROM customer_purchase_date
)
SELECT
    CustomerID,
    MAX(gap_days) OVER(PARTITION BY CustomerID) AS max_gap_days
FROM gaps
ORDER BY max_gap_days DESC;
-- The largest gap between two consecutive purchases is 31 days.
-- Out of a 4-month dataset window, this is relatively small.
-- => Focus only on Frequency and Monetary value to analyse customer behaviour, 
-- as the short window leaves recency with too little variation to be a reliable signal.

-- Customer segmentation - FM (Frequency + Monetary)
WITH customer_stats AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT TransactionNumber) AS frequency,
        SUM(TotalPrice) AS monetary,
        SUM(Quantity) AS total_quantity 
    FROM fmcg.sales
    GROUP BY CustomerID
),
fm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY frequency) AS f_Score,
        NTILE(5) OVER (ORDER BY monetary) AS m_Score
    FROM customer_stats
),
fm_combined AS (
    SELECT 
        *,
        (f_score * 10 + m_score) AS fm_score
    FROM fm_scores
),
fm_labelled AS (
    SELECT
        *,
        CASE 
            WHEN fm_score IN (55,54,45,44) THEN 'Champions'
            WHEN fm_score IN (53,43,35,34) THEN 'Loyal'
            WHEN fm_score IN (52,51,42,41,25,24,15,14) THEN 'Potential loyalist'
            WHEN fm_score IN (33,32,31,23,13) THEN 'Need attention'
            WHEN fm_score IN (22,21,12,11) THEN 'Lost customers'
        END AS segment
    FROM fm_combined
)
SELECT 
    segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_monetary,
    ROUND(SUM(monetary) / SUM(frequency), 2) AS aov,
    ROUND(SUM(total_quantity) / SUM(frequency), 2) AS avg_basket_size
FROM fm_labelled
GROUP BY segment
ORDER BY total_monetary;

--2. Customer order frequency
WITH customer_order AS (
    SELECT CustomerID, COUNT(DISTINCT TransactionNumber) AS order_count
    FROM fmcg.sales
    GROUP BY CustomerID
),
customer_quartile AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY order_count) AS frequency_quartile
    FROM customer_order
)
SELECT
    CASE frequency_quartile
        WHEN 1 THEN 'Low Frequency'
        WHEN 2 THEN 'Medium Frequency'
        WHEN 3 THEN 'High Frequency'
        WHEN 4 THEN 'Very High Frequency'
    END AS frequency_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) AS pct,
    MIN(order_count) AS min_orders,
    MAX(order_count) AS max_orders,
    ROUND(AVG(order_count), 1) AS avg_orders
FROM customer_quartile
GROUP BY frequency_segment
ORDER BY min_orders;
