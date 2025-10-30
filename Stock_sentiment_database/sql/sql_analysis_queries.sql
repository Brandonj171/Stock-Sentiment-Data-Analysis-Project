-- Stock Sentiment Analysis Queries
-- Author: Brandon Jordan
-- Date: 08/27/25

--#1 Sentiment vs Price Movement
--Do positive sentiment days actually have positive price changes
SELECT 
	sentiment_label,
	COUNT(*) as days,
	ROUND(AVG(price_change_pct)::numeric, 2) as avg_price_change,
	ROUND(MIN(price_change_pct)::numeric, 2) as min_change,
	ROUND(MAX(price_change_pct)::numeric, 2) as max_change
FROM stock_sentiment_analysis
GROUP BY sentiment_label
ORDER BY
	CASE sentiment_label
		WHEN 'Positive' THEN 1
		WHEN 'Neutral' THEN 2
		WHEN 'Negative' THEN 3
	END;

--#2 Basic Summary Statistics
--Which stocks have most positive/negative sentiment overall 
SELECT 
    ticker,
    COUNT(*) as trading_days,
    ROUND(AVG(sentiment_score)::numeric, 4) as avg_sentiment,
    ROUND(AVG(price_change_pct)::numeric, 2) as avg_price_change,
    ROUND(STDDEV(sentiment_score)::numeric, 4) as sentiment_volatility
FROM stock_sentiment_analysis
GROUP BY ticker
ORDER BY avg_sentiment DESC;

--#3 Sentiment Distribution
--How many days were positive vs negative vs neutral
SELECT 
    sentiment_label,
    COUNT(*) as days,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM stock_sentiment_analysis
GROUP BY sentiment_label
ORDER BY days DESC;

--#4 Correlation Analysis
--Which stocks are most sentiment-driven (high correlation = sentiment predicts price)
SELECT 
    ticker,
    ROUND(CORR(sentiment_score, price_change_pct)::numeric, 4) as correlation,
    COUNT(*) as sample_size
FROM stock_sentiment_analysis
GROUP BY ticker
ORDER BY correlation DESC;
--#5 Top Sentiment Days (Most Positive/Negative)
--Extreme sentiment days and what happened to prices 
-- Top 10 most positive sentiment days
SELECT 
    ticker,
    date,
    sentiment_score,
    price_change_pct,
    sentiment_label
FROM stock_sentiment_analysis
ORDER BY sentiment_score DESC
LIMIT 10;

-- Top 10 most negative sentiment days
SELECT 
    ticker,
    date,
    sentiment_score,
    price_change_pct,
    sentiment_label
FROM stock_sentiment_analysis
ORDER BY sentiment_score ASC
LIMIT 10;

--#6 Prediction Accuracy
--How often does sentiment correctly predict price direction
SELECT 
    ticker,
    COUNT(*) as total_days,
    SUM(CASE 
        WHEN sentiment_score > 0.3 AND price_change_pct > 0 THEN 1
        WHEN sentiment_score < -0.3 AND price_change_pct < 0 THEN 1
        ELSE 0 
    END) as correct_predictions,
    ROUND(
        100.0 * SUM(CASE 
            WHEN sentiment_score > 0.3 AND price_change_pct > 0 THEN 1
            WHEN sentiment_score < -0.3 AND price_change_pct < 0 THEN 1
            ELSE 0 
        END) / COUNT(*), 2
    ) as accuracy_pct
FROM stock_sentiment_analysis
WHERE ABS(sentiment_score) > 0.3  -- Only count strong sentiment days
GROUP BY ticker
ORDER BY accuracy_pct DESC;

--#7 Monthly Trends
--Trends over time - is sentiment getting more positive/negative
SELECT 
    DATE_TRUNC('month', date) as month,
    ROUND(AVG(sentiment_score)::numeric, 4) as avg_sentiment,
    ROUND(AVG(price_change_pct)::numeric, 2) as avg_price_change,
    COUNT(*) as trading_days
FROM stock_sentiment_analysis
GROUP BY DATE_TRUNC('month', date)
ORDER BY month;

--#8 False Positive/Negatives
--When sentiment was most wrong
SELECT 
    ticker,
    date,
    sentiment_score,
    price_change_pct,
    CASE 
        WHEN sentiment_score > 0.3 AND price_change_pct < 0 THEN 'False Positive'
        WHEN sentiment_score < -0.3 AND price_change_pct > 0 THEN 'False Negative'
    END as prediction_error
FROM stock_sentiment_analysis
WHERE (sentiment_score > 0.3 AND price_change_pct < 0)
   OR (sentiment_score < -0.3 AND price_change_pct > 0)
ORDER BY ABS(sentiment_score) DESC
LIMIT 20;

--#9 Window Function -7-Day Moving Average
--Smoothes sentiment trends 
SELECT 
    ticker,
    date,
    sentiment_score,
    price_change_pct,
    ROUND(AVG(sentiment_score) OVER (
        PARTITION BY ticker 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::numeric, 4) as sentiment_7day_avg
FROM stock_sentiment_analysis
ORDER BY ticker, date
LIMIT 100;

--#10 Best Performing Stocks
--Which stocks gained/lost most over the year
SELECT 
    ticker,
    ROUND(AVG(price_change_pct)::numeric, 2) as avg_daily_change,
    ROUND(SUM(price_change_pct)::numeric, 2) as cumulative_change,
    ROUND(AVG(sentiment_score)::numeric, 4) as avg_sentiment
FROM stock_sentiment_analysis
GROUP BY ticker
ORDER BY cumulative_change DESC;
