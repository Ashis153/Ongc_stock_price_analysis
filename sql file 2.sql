use ongc_db;

-- A. Crude Oil Rolling Correlation & Beta Analysis
WITH DailyReturns AS (
    SELECT 
        s.trade_date,
        s.close_price AS stock_price,
        c.crude_close AS crude_price,
        -- Daily percentage returns
        (s.close_price - LAG(s.close_price, 1) OVER (ORDER BY s.trade_date)) / 
            LAG(s.close_price, 1) OVER (ORDER BY s.trade_date) AS stock_return,
        (c.crude_close - LAG(c.crude_close, 1) OVER (ORDER BY c.trade_date)) / 
            LAG(c.crude_close, 1) OVER (ORDER BY c.trade_date) AS crude_return
    FROM Fact_ONGC_Stock s
    JOIN Fact_Brent_Crude c ON s.trade_date = c.trade_date
),
RollingStats AS (
    SELECT 
        trade_date,
        stock_price,
        crude_price,
        stock_return,
        crude_return,
        -- 30-Day Window Metrics for Correlation & Beta calculation
        COUNT(*) OVER w AS window_count,
        AVG(stock_return) OVER w AS avg_stock_return,
        AVG(crude_return) OVER w AS avg_crude_return,
        -- Covariance = E[(X - mu_x)(Y - mu_y)]
        AVG(stock_return * crude_return) OVER w - (AVG(stock_return) OVER w * AVG(crude_return) OVER w) AS covariance,
        -- Variance of Crude = E[Y^2] - (E[Y])^2
        AVG(crude_return * crude_return) OVER w - POWER(AVG(crude_return) OVER w, 2) AS var_crude,
        -- Variance of Stock = E[X^2] - (E[X])^2
        AVG(stock_return * stock_return) OVER w - POWER(AVG(stock_return) OVER w, 2) AS var_stock
    FROM DailyReturns
    WINDOW w AS (ORDER BY trade_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
)
SELECT 
    trade_date,
    stock_price,
    crude_price,
    ROUND(stock_return * 100, 2) AS stock_return_pct,
    ROUND(crude_return * 100, 2) AS crude_return_pct,
    -- Pearson Correlation Formula: Cov(X,Y) / (StdDev(X) * StdDev(Y))
    ROUND(
        covariance / NULLIF(SQRT(var_stock * var_crude), 0), 4
    ) AS rolling_30d_correlation,
    -- Financial Beta Formula: Cov(Stock, Crude) / Var(Crude)
    ROUND(
        covariance / NULLIF(var_crude, 0), 4
    ) AS rolling_30d_beta
FROM RollingStats
WHERE window_count = 30
ORDER BY trade_date ASC;





-- B. Dynamic Price Bands (Bollinger Bands)

WITH RollingVolatility AS (
    SELECT 
        trade_date,
        close_price,
        -- 20-Day Simple Moving Average
        AVG(close_price) OVER (
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS sma_20,
        -- 20-Day Standard Deviation
        STDDEV_POP(close_price) OVER (
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS std_20,
        -- Track window completeness
        COUNT(*) OVER (
            ORDER BY trade_date 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS window_count
    FROM Fact_ONGC_Stock
)
SELECT 
    trade_date,
    ROUND(close_price, 2) AS close_price,
    ROUND(sma_20, 2) AS sma_20,
    ROUND(sma_20 + (2 * std_20), 2) AS upper_bollinger_band,
    ROUND(sma_20 - (2 * std_20), 2) AS lower_bollinger_band,
    -- Trading Signal Indicator
    CASE 
        WHEN close_price > (sma_20 + (2 * std_20)) THEN 'Overbought (Above Upper Band)'
        WHEN close_price < (sma_20 - (2 * std_20)) THEN 'Oversold (Below Lower Band)'
        ELSE 'Normal Range'
    END AS signal_status
FROM RollingVolatility
WHERE window_count = 20
ORDER BY trade_date ASC;






-- single, consolidated master analytics table

WITH -- 1. Main OHLCV, Intraday Volatility, Stock Return & Event Dimension Data
sql_output AS (
    SELECT 
        s.trade_date,
        s.open_price,
        s.high_price,
        s.low_price,
        s.close_price,
        s.volume AS ongc_volume,
        ROUND(((s.high_price - s.low_price) / s.low_price) * 100, 2) AS intraday_volatility_pct,
        ROUND(((s.close_price - LAG(s.close_price) OVER (ORDER BY s.trade_date)) / LAG(s.close_price) OVER (ORDER BY s.trade_date)) * 100, 2) AS daily_return_pct,
        COALESCE(e.event_name, 'Regular Trading') AS event_name,
        COALESCE(e.severity_level, 'None') AS event_severity
    FROM Fact_ONGC_Stock s
    LEFT JOIN Dim_War_Events e 
        ON s.trade_date = e.event_date
),

-- 2. Option A: Crude Oil Rolling Correlation & Beta Analysis (30-Day Window)
DailyReturns AS (
    SELECT 
        s.trade_date,
        s.close_price AS stock_price,
        c.crude_close AS crude_price,
        (s.close_price - LAG(s.close_price) OVER (ORDER BY s.trade_date)) / LAG(s.close_price) OVER (ORDER BY s.trade_date) AS stock_return,
        (c.crude_close - LAG(c.crude_close) OVER (ORDER BY c.trade_date)) / LAG(c.crude_close) OVER (ORDER BY c.trade_date) AS crude_return
    FROM Fact_ONGC_Stock s
    JOIN Fact_Brent_Crude c ON s.trade_date = c.trade_date
),
RollingStats AS (
    SELECT 
        trade_date,
        stock_price,
        crude_price,
        stock_return,
        crude_return,
        COUNT(*) OVER w AS window_count,
        AVG(stock_return * crude_return) OVER w - (AVG(stock_return) OVER w * AVG(crude_return) OVER w) AS covariance,
        AVG(crude_return * crude_return) OVER w - POWER(AVG(crude_return) OVER w, 2) AS var_crude,
        AVG(stock_return * stock_return) OVER w - POWER(AVG(stock_return) OVER w, 2) AS var_stock
    FROM DailyReturns
    WINDOW w AS (ORDER BY trade_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
),
sql_A AS (
    SELECT 
        trade_date,
        crude_price,
        ROUND(crude_return * 100, 2) AS crude_return_pct,
        ROUND(covariance / NULLIF(SQRT(var_stock * var_crude), 0), 4) AS rolling_30d_correlation,
        ROUND(covariance / NULLIF(var_crude, 0), 4) AS rolling_30d_beta
    FROM RollingStats
    WHERE window_count = 30
),

-- 3. Option B: Bollinger Bands & Technical Signal Analysis (20-Day Window)
RollingVolatility AS (
    SELECT 
        trade_date,
        close_price,
        AVG(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS sma_20,
        STDDEV_POP(close_price) OVER (ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS std_20,
        COUNT(*) OVER (ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) AS window_count
    FROM Fact_ONGC_Stock
),
sql_B AS (
    SELECT 
        trade_date,
        ROUND(sma_20, 2) AS sma_20,
        ROUND(sma_20 + (2 * std_20), 2) AS upper_bollinger_band,
        ROUND(sma_20 - (2 * std_20), 2) AS lower_bollinger_band,
        CASE 
            WHEN close_price > (sma_20 + (2 * std_20)) THEN 'Overbought (Above Upper Band)'
            WHEN close_price < (sma_20 - (2 * std_20)) THEN 'Oversold (Below Lower Band)'
            ELSE 'Normal Range'
        END AS signal_status
    FROM RollingVolatility
    WHERE window_count = 20
)

-- 4. Final Master Joining Query
SELECT 
    -- Fact Table 1 & Event Metrics
    o.trade_date,
    ROUND(o.open_price, 2) AS open_price,
    ROUND(o.high_price, 2) AS high_price,
    ROUND(o.low_price, 2) AS low_price,
    ROUND(o.close_price, 2) AS close_price,
    o.ongc_volume,
    o.intraday_volatility_pct,
    o.daily_return_pct,
    o.event_name,
    o.event_severity,
    
    -- Option A: Crude Beta & Correlation Metrics
    a.crude_price,
    a.crude_return_pct,
    a.rolling_30d_correlation,
    a.rolling_30d_beta,
    
    -- Option B: Bollinger Band Metrics
    b.sma_20 AS bollinger_sma_20,
    b.upper_bollinger_band,
    b.lower_bollinger_band,
    COALESCE(b.signal_status, 'Normal Range') AS signal_status

FROM sql_output o
LEFT JOIN sql_A a ON o.trade_date = a.trade_date
LEFT JOIN sql_B b ON o.trade_date = b.trade_date
ORDER BY o.trade_date ASC;
