# ONGC Quantitative Market Analytics & Volatility Engine

A complete end-to-end data engineering and quantitative finance pipeline evaluating **ONGC (Oil and Natural Gas Corporation)** stock dynamics, international **Brent Crude oil benchmark sensitivity**, and **technical price indicators**.

This project details the full analytical lifecycle: from SQL database schema design, data ingestion, and windowed CTE mathematical modeling, to an interactive Excel financial model and Power BI executive dashboard.

---

## 📌 Executive Summary

Understanding the price sensitivity between energy sector equities and upstream commodity benchmarks is critical for portfolio management, risk modeling, and trading strategy execution. This project constructs an end-to-end quantitative pipeline that:

1. **Engineers Relational Schemas:** Stores daily stock price action (OHLCV) alongside Brent Crude macroeconomic benchmarks.
2. **Computes Dynamic Rolling Sensitivity:** Calculates 30-day rolling Beta ($\beta$) and Pearson correlation coefficients ($\rho$) in MySQL using windowed covariance and variance functions.
3. **Generates Technical Trading Indicators:** Computes 20-day Simple Moving Averages (SMA-20) and Bollinger Bands ($\pm 2\sigma$) to flag overbought and normal trading conditions.
4. **Builds an Executive Excel Dashboard:** Integrates dataset lookups (`XLOOKUP`, `INDEX/MATCH`), dynamic array statistical metrics, and interactive Pivot Table risk matrices.
5. **Deploys a Power BI Dashboard:** Implements robust DAX measures to visualize macro trends, volatility spikes, and event distributions across a unified visual grid.

---

## 🗂️ Data Architecture & Relational Schema

The relational database model relies on two core fact tables linked by trading session dates:

### 1. `Fact_ONGC_Stock` (Equity Performance)
Stores daily trading session metrics for ONGC.
* `trade_date` (**DATE**, Primary Key): Calendar date of the trading session.
* `open_price`, `high_price`, `low_price`, `close_price` (**DECIMAL 10,4**): Prices in INR.
* `volume` (**BIGINT**): Total share volume traded.
* `event_name` (**VARCHAR 100**): Geopolitical or market event description.
* `event_severity` (**VARCHAR 20**): Risk categorization (`Critical`, `High`, `Regular Trading`).

### 2. `Fact_Brent_Crude` (Macro Benchmark)
Tracks daily closing prices for Brent Crude oil.
* `trade_date` (**DATE**, Primary Key / Foreign Key): References `Fact_ONGC_Stock(trade_date)` with `ON DELETE CASCADE`.
* `crude_close` (**DECIMAL 10,4**): Daily crude oil closing price in USD.

---

## 🧮 Quantitative Methods & Mathematical Formulas

### 1. Daily Returns & Intraday Volatility
$$\text{Intraday Volatility (\%)} = \frac{\text{High} - \text{Low}}{\text{Low}} \times 100$$

$$\text{Daily Return (\%)} = \frac{\text{Close}_t - \text{Close}_{t-1}}{\text{Close}_{t-1}} \times 100$$

### 2. Rolling 30-Day Pearson Correlation
$$\rho = \frac{\text{Cov}(\text{Stock}, \text{Crude})}{\sqrt{\text{Var}(\text{Stock}) \times \text{Var}(\text{Crude})}}$$

### 3. Rolling 30-Day Financial Beta
$$\beta = \frac{\text{Cov}(\text{Stock}, \text{Crude})}{\text{Var}(\text{Crude})}$$

### 4. 20-Day Bollinger Bands
$$\text{Upper Band} = \text{SMA}_{20} + 2 \times \sigma_{20}$$

$$\text{Lower Band} = \text{SMA}_{20} - 2 \times \sigma_{20}$$

---

## 💻 SQL Pipeline Implementation

The SQL layer is executed across two modular scripts:

### 1. `sql file 1.sql` — Schema Definition & Ingestion
* **Database Setup:** Creates the `ongc_analytics` schema.
* **Table Creation:** Defines DDL for `Fact_ONGC_Stock` and `Fact_Brent_Crude` with foreign key integrity rules.
* **Data Cleaning:** Enforces non-null constraints, date formatting, and primary key checks.

### 2. `sql file 2.sql` — Quantitative CTE Analytics & Master Join
* **CTE 1 (`Returns_CTE`):** Uses `LAG()` window functions to calculate daily percentage returns for both ONGC stock and Brent Crude.
* **CTE 2 (`Rolling_Metrics_CTE`):** Executes 30-day windowed aggregation functions to compute covariance, variance, rolling Beta, and Pearson correlation coefficients over a 30-session frame (`ROWS BETWEEN 29 PRECEDING AND CURRENT ROW`).
* **CTE 3 (`Bollinger_CTE`):** Calculates 20-day windowed moving averages (`AVG() OVER`) and population standard deviations (`STDDEV_POP() OVER`) to derive upper/lower Bollinger Bands and assign trading signal statuses (`Overbought (Above Upper Band)` vs `Normal Range`).
* **Master Export Query:** Joins stock facts, crude benchmarks, event metadata, sensitivity metrics, and technical signals into a final consolidated tabular view (`Final sql output.csv`).

---

## 📈 Excel Analytical Dashboard & KPI Queries

The Excel analytical layer processes the exported structured table **`ONGC_Master`** to generate key financial metrics, high-level KPIs, and dynamic analytical lookups:

### Key Metric Formulas & Verified Results

| Metric Indicator / Query Description | Excel Formula | Verified Output | Key Analytical Context |
| :--- | :--- | :---: | :--- |
| **Latest Close Price on a 'Critical' Event** | `=XLOOKUP("Critical", ONGC_Master[event_severity], ONGC_Master[close_price], "No Event Found", 0, -1)` | **299.80** | Closing stock price recorded on the most recent critical shock date (`2026-06-05`). |
| **Average Daily Return on Geopolitical Event Days** | `=AVERAGEIFS(ONGC_Master[daily_return_pct], ONGC_Master[event_name], "<>Regular Trading")` | **0.96%** | Measures average stock return on geopolitical shock dates versus regular trading sessions. |
| **Count Days with High Volatility (>2.5%) and High Beta (>0.80)** | `=COUNTIFS(ONGC_Master[intraday_volatility_pct], ">2.5", ONGC_Master[rolling_30d_beta], ">0.80")` | **3** | Identifies trading sessions where elevated market volatility coincided with heightened crude sensitivity. |
| **Overall Stock vs Crude Pearson Correlation** | `=LET(stock_ret, FILTER(ONGC_Master[daily_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), crude_ret, FILTER(ONGC_Master[crude_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), CORREL(stock_ret, crude_ret))` | **0.9860** | Indicates an exceptionally strong direct linear co-movement between Brent Crude returns and ONGC equity returns. |
| **Overall Stock Beta against Brent Crude** | `=LET(stock_ret, FILTER(ONGC_Master[daily_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), crude_ret, FILTER(ONGC_Master[crude_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), SLOPE(stock_ret, crude_ret))` | **0.8435** | Demonstrates that ONGC stock moves approximately 0.84% for every 1.00% change in Brent Crude oil prices. |

---

## 📊 Pivot Table Architecture

### 1. Risk Matrix by Event Severity
* **Rows:** `event_severity` (`Critical`, `High`, `Regular Trading`)
* **Values:** `AVERAGE of daily_return_pct`, `AVERAGE of intraday_volatility_pct`, `AVERAGE of rolling_30d_beta`, `COUNT of trade_date`
* **Analytical Insight:** Highlights how major geopolitical shocks trigger higher intraday volatility spreads (up to **3.41%**) compared to standard trading conditions (**1.82%**).

### 2. Technical Signal Breakdown (Bollinger Bands)
* **Rows:** `signal_status` (`Normal Range`, `Overbought (Above Upper Band)`)
* **Values:** `AVERAGE of daily_return_pct`, `AVERAGE of intraday_volatility_pct`, `COUNT of trade_date`
* **Analytical Insight:** Tracks performance across **14 overbought breakout sessions**, where daily returns averaged **1.12%** compared to **-0.04%** during normal trading bands.

### 3. Monthly Trend & Macro Benchmark Analysis
Summarizes monthly ONGC stock performance against Brent Crude closing benchmarks over the trading timeframe.
* **Rows:** `trade_date` (Grouped by **Months**)
* **Values:**
  * `AVERAGE of close_price` (Format: `₹#,##0.00`)
  * `AVERAGE of crude_price` (Format: `$#,##0.00`)
  * `SUM of ongc_volume` (Format: `#,##0`)
  * `COUNT of trade_date` (Name: *"Trading Days"*)

---

## 📊 Power BI Interactive Financial Dashboard

The Power BI dashboard (`Ongc_stock_dashboard.pbix`) provides an executive visual interface across sensitivity and technical dimensions.

### Single-Page Visual Grid Blueprint

<img width="1320" height="688" alt="image" src="https://github.com/user-attachments/assets/7194ac86-fbbb-4538-9fbb-800a1dc7447c" />
 **📐 Production DAX Measure Library**

The following DAX script handles text-formatted nulls and summary row strings gracefully inside **DAX Query View**:

```dax
DEFINE
    -- Section 1: Executive KPI Measures
    MEASURE 'Final sql output'[Latest ONGC Close] = 
        CALCULATE(
            MAX('Final sql output'[close_price]),
            LASTDATE('Final sql output'[trade_date])
        )

    -- Section 2: Macro Sensitivity Measures
    MEASURE 'Final sql output'[Avg 30D Beta] = 
        AVERAGEX(
            FILTER(
                'Final sql output',
                NOT ISBLANK('Final sql output'[rolling_30d_beta]) &&
                'Final sql output'[rolling_30d_beta] <> "NULL" &&
                ISNUMBER(VALUE('Final sql output'[rolling_30d_beta]))
            ),
            VALUE('Final sql output'[rolling_30d_beta])
        )

    MEASURE 'Final sql output'[Avg 30D Correlation] = 
        AVERAGEX(
            FILTER(
                'Final sql output',
                NOT ISBLANK('Final sql output'[rolling_30d_correlation]) &&
                'Final sql output'[rolling_30d_correlation] <> "NULL" &&
                ISNUMBER(VALUE('Final sql output'[rolling_30d_correlation]))
            ),
            VALUE('Final sql output'[rolling_30d_correlation])
        )

    -- Section 3: Geopolitical Risk Analysis
    MEASURE 'Final sql output'[Avg Geopolitical Volatility %] = 
        CALCULATE(
            AVERAGEX(
                FILTER(
                    'Final sql output',
                    NOT ISBLANK('Final sql output'[intraday_volatility_pct]) &&
                    'Final sql output'[intraday_volatility_pct] <> "NULL" &&
                    ISNUMBER(VALUE('Final sql output'[intraday_volatility_pct]))
                ),
                VALUE('Final sql output'[intraday_volatility_pct])
            ),
            NOT ISBLANK('Final sql output'[event_severity]),
            'Final sql output'[event_severity] <> "Regular Trading"
        )

EVALUATE
    SUMMARIZECOLUMNS(
        "Latest ONGC Close", [Latest ONGC Close],
        "Avg 30D Beta", [Avg 30D Beta],
        "Avg 30D Correlation", [Avg 30D Correlation],
        "Avg Geopolitical Volatility %", [Avg Geopolitical Volatility %]
    )
