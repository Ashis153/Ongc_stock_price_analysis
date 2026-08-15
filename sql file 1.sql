-- Create Database
CREATE DATABASE IF NOT EXISTS ongc_db;
USE ongc_db;

-- Table 1: ONGC Stock Daily OHLCV Data
CREATE TABLE IF NOT EXISTS Fact_ONGC_Stock (
    trade_date DATE PRIMARY KEY,
    open_price DECIMAL(10,4) NOT NULL,
    high_price DECIMAL(10,4) NOT NULL,
    low_price DECIMAL(10,4) NOT NULL,
    close_price DECIMAL(10,4) NOT NULL,
    volume BIGINT NOT NULL
);

-- Table 2: Brent Crude Benchmark Data (Macro Context)
CREATE TABLE IF NOT EXISTS Fact_Brent_Crude (
    trade_date DATE PRIMARY KEY,
    crude_close DECIMAL(10,4) NOT NULL,
    FOREIGN KEY (trade_date) REFERENCES Fact_ONGC_Stock(trade_date) ON DELETE CASCADE
);

-- Table 3: Geopolitical & War Conflict Events
CREATE TABLE IF NOT EXISTS Dim_War_Events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    event_date DATE NOT NULL,
    event_name VARCHAR(150) NOT NULL,
    impact_category VARCHAR(50) DEFAULT 'Geopolitical Shock',
    severity_level VARCHAR(20) CHECK (severity_level IN ('Low', 'Medium', 'High', 'Critical'))
);


LOAD DATA INFILE '"C:/Users/ashis/Downloads/ongc_last_6months.xls"'
INTO TABLE Fact_ONGC_Stock
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 3 LINES
(trade_date, close_price, high_price, low_price, open_price, volume);



SET SQL_SAFE_UPDATES = 0;




-- 3. SQL Data Cleaning & Integrity Checks
-- 1. Identify and remove any anomalous or zero-volume non-trading records
DELETE FROM Fact_ONGC_Stock 
WHERE volume <= 0 OR close_price IS NULL OR open_price IS NULL;

-- 2. Verify dataset date boundaries matches 6-month timeline
SELECT 
    MIN(trade_date) AS dataset_start_date,
    MAX(trade_date) AS dataset_end_date,
    COUNT(*) AS total_trading_days
FROM Fact_ONGC_Stock;

-- 3. Populate Conflict Timeline dimension (Key events during the 6-month period)
INSERT INTO Dim_War_Events (event_date, event_name, impact_category, severity_level) 
VALUES 
    ('2026-03-02', 'Red Sea Shipping Channel Attacks Escalate', 'Supply Chain Disruptions', 'High'),
    ('2026-04-14', 'Middle East Energy Infrastructure Sanctions', 'Sanctions & Tariffs', 'Critical'),
    ('2026-06-05', 'OPEC+ Unscheduled Oil Production Cuts', 'Global Crude Supply Shock', 'Critical'),
    ('2026-07-20', 'Strait of Hormuz Tanker Intercept Warning', 'Maritime Risk Factor', 'High');



-- 4. Analytical Joins & SQL Data Processing Query
WITH StockReturns AS (
    SELECT 
        s.trade_date,
        s.open_price,
        s.high_price,
        s.low_price,
        s.close_price AS ongc_close,
        s.volume AS ongc_volume,
        -- Calculate day-over-day price change
        LAG(s.close_price, 1) OVER (ORDER BY s.trade_date) AS prev_close,
        -- Measure intraday price fluctuation (%)
        ROUND(((s.high_price - s.low_price) / s.low_price) * 100, 2) AS intraday_volatility_pct
    FROM Fact_ONGC_Stock s
)
SELECT 
    r.trade_date,
    ROUND(r.open_price, 2) AS open_price,
    ROUND(r.high_price, 2) AS high_price,
    ROUND(r.low_price, 2) AS low_price,
    ROUND(r.ongc_close, 2) AS close_price,
    r.ongc_volume,
    r.intraday_volatility_pct,
    -- Daily stock return percentage
    ROUND(((r.ongc_close - r.prev_close) / r.prev_close) * 100, 2) AS daily_return_pct,
    -- Join with Event Lookup Dimension
    COALESCE(e.event_name, 'Regular Trading') AS event_name,
    COALESCE(e.severity_level, 'None') AS event_severity
FROM StockReturns r
LEFT JOIN Dim_War_Events e ON r.trade_date = e.event_date
ORDER BY r.trade_date ASC;



-- Testing Relational Joins
SELECT 
    s.trade_date,
    s.close_price AS ongc_close_inr,
    c.crude_close AS brent_crude_usd,
    ROUND((s.close_price / c.crude_close), 2) AS price_ratio
FROM Fact_ONGC_Stock s
INNER JOIN Fact_Brent_Crude c ON s.trade_date = c.trade_date
ORDER BY s.trade_date ASC
LIMIT 10;



