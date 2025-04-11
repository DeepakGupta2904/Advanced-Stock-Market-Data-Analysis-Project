

----------- Advanced Stock Market Data Analysis Project -----------


----- Understand the Table:-
SELECT TOP 10 * FROM StockData;


----- ANALYSIS & RESULTS:-

-- 1. Total Number of Records
SELECT COUNT(*) AS TotalRows FROM StockData;

-- Result: Shows total rows in the dataset. Total records :- 10,000 rows


-- 2. Distinct Stocks
SELECT DISTINCT StockSymbol FROM StockData;

-- Result: How many companies or stock symbols are represented. Distinct stocks	AAPL, GOOG, MSFT, TSLA, etc.


-- 3. Time Range of Data
SELECT MIN(Date) AS StartDate, MAX(Date) AS EndDate FROM StockData;

-- Result: Understand the span of your dataset. Date range	2020-01-01 to 2023-12-31


-- 4.  Daily Change Percent
SELECT 
    Date,
    StockSymbol,
    ROUND(((Close - Open) / Open) * 100, 2) AS DailyChangePercent
FROM StockData;

-- Result: Shows which days had the most gain or loss in price. Days with most gain/loss 12% gain on 2021-03-18 (TSLA), 
-- 10% loss on 2022-04-01 (GOOG)


-- 5. Highest and Lowest Closing Price per Stock
SELECT StockSymbol, MAX(Close) AS MaxClose, MIN(Close) AS MinClose
FROM StockData
GROUP BY StockSymbol;

-- Result: For each stock, see best and worst closing prices. Highest close per stock	TSLA: $1250, AAPL: $178, etc.


-- 6. 7-day Moving Average
SELECT 
    Date,
    StockSymbol,
    Close,
    AVG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS MovingAvg_7
FROM StockData;

-- Result: Tracks short-term trends. Moving averages Used for signal generation or short-term trading strategy


-- 7. Gain or Loss Detection
SELECT 
    Date,
    StockSymbol,
    Close,
    LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) AS PrevClose,
    CASE 
        WHEN Close > LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) THEN 'Gain'
        WHEN Close < LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) THEN 'Loss'
        ELSE 'No Change'
    END AS ChangeType
FROM StockData;

-- Result: Identifies up/down days per stock.


-- 8. Top 3 Days by Volume for Each Stock
SELECT * FROM (
    SELECT *, RANK() OVER (PARTITION BY StockSymbol ORDER BY Volume DESC) AS VolRank
    FROM StockData
) AS ranked
WHERE VolRank <= 3;

-- Result: Shows the most actively traded days.


-- 9. Monthly Price Summary
SELECT 
    StockSymbol,
    FORMAT(Date, 'yyyy-MM') AS Month,
    AVG(Close) AS AvgMonthlyClose,
    MAX(Close) AS MaxMonthlyClose,
    MIN(Close) AS MinMonthlyClose
FROM StockData
GROUP BY StockSymbol, FORMAT(Date, 'yyyy-MM');

-- Result: Track monthly trends.


-- 10. Price Volatility (Standard Deviation)
SELECT 
    StockSymbol,
    ROUND(STDEV(Close), 2) AS PriceVolatility
FROM StockData
GROUP BY StockSymbol;

-- Insight: TSLA shows the most price volatility — a riskier, but potentially high-reward stock.


-- 11. Cumulative Return Over Time
SELECT 
    Date,
    StockSymbol,
    Close,
    FIRST_VALUE(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) AS InitialClose,
    ROUND(((Close / FIRST_VALUE(Close) OVER (PARTITION BY StockSymbol ORDER BY Date)) - 1) * 100, 2) AS CumulativeReturnPercent
FROM StockData;

-- Insight: AAPL delivered a 34.62% gain over the entire time period.


-- 12. Best and Worst Performing Days (Biggest % Move)
SELECT TOP 1 *
FROM (
    SELECT *,
        ROUND(((Close - Open) / Open) * 100, 2) AS DailyChangePercent
    FROM StockData
) AS Sub
ORDER BY DailyChangePercent DESC;

SELECT TOP 1 *
FROM (
    SELECT *,
        ROUND(((Close - Open) / Open) * 100, 2) AS DailyChangePercent
    FROM StockData
) AS Sub
ORDER BY DailyChangePercent ASC;

-- Insight: Outlier days like these are important for trading alerts or risk analysis.


-- 13.  Rolling 7-Day Return
SELECT 
    Date,
    StockSymbol,
    Close,
    LAG(Close, 6) OVER (PARTITION BY StockSymbol ORDER BY Date) AS Close7DaysAgo,
    ROUND(((Close - LAG(Close, 6) OVER (PARTITION BY StockSymbol ORDER BY Date)) / 
          LAG(Close, 6) OVER (PARTITION BY StockSymbol ORDER BY Date)) * 100, 2) AS Return7Days
FROM StockData;

-- Insight: Shows weekly returns, useful for momentum-based strategies.


-- 14. Correlation Between Volume and Daily % Change

-- Estimate correlation-like insight using grouped avg % change per volume range
SELECT 
    CASE 
        WHEN Volume < 1000000 THEN 'Low Volume'
        WHEN Volume BETWEEN 1000000 AND 5000000 THEN 'Medium Volume'
        ELSE 'High Volume'
    END AS VolumeCategory,
    ROUND(AVG((Close - Open) / Open * 100), 2) AS AvgChangePercent
FROM StockData
GROUP BY 
    CASE 
        WHEN Volume < 1000000 THEN 'Low Volume'
        WHEN Volume BETWEEN 1000000 AND 5000000 THEN 'Medium Volume'
        ELSE 'High Volume'
    END;

-- Insight: High-volume days correlate with larger price movements.


-- 15.  Streak of Consecutive Gains/Losses
WITH Changes AS (
    SELECT 
        Date, 
        StockSymbol,
        Close,
        LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) AS PrevClose,
        CASE 
            WHEN Close > LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) THEN 1
            WHEN Close < LAG(Close) OVER (PARTITION BY StockSymbol ORDER BY Date) THEN -1
            ELSE 0
        END AS Direction
    FROM StockData
), Streaks AS (
    SELECT *,
        SUM(CASE WHEN Direction != 0 THEN 1 ELSE 0 END) OVER (PARTITION BY StockSymbol ORDER BY Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS StreakID
    FROM Changes
)
SELECT StockSymbol, Direction, COUNT(*) AS StreakLength
FROM Streaks
WHERE Direction != 0
GROUP BY StockSymbol, Direction, StreakID
ORDER BY StockSymbol, StreakLength DESC;

-- Insight: TSLA had a 6-day winning streak; AAPL had a 4-day losing streak — great for behavioral patterns.



