# Ongc_stock_price_analysis
A quantitative MySQL and Excel pipeline evaluating daily trading performance, commodity sensitivity, and technical indicators for ONGC. By integrating ONGC stock data with Brent Crude benchmarks, it computes 30-day rolling Beta, Pearson correlation coefficients, and 20-day Bollinger Bands to quantify market risk and price sensitivity.

# ONGC Quantitative Market Analytics & Volatility Engine

An end-to-end data engineering and quantitative finance pipeline evaluating **ONGC (Oil and Natural Gas Corporation)** stock dynamics, international **Brent Crude oil benchmark sensitivity**, and **technical price indicators**[cite: 1, 2].

This repository includes relational database schemas, bulk data ingestion routines, advanced windowed analytical SQL queries, and interactive Excel modeling frameworks[cite: 1, 2].

---

## 📌 Project Overview

Understanding the price sensitivity between energy sector equities and upstream commodity pricing is critical for portfolio management and risk assessment. This project constructs a quantitative analytics environment that:
1. **Engineers Relational Schemas** to store daily stock prices (OHLCV) and macroeconomic crude benchmarks.
2. **Computes Dynamic Rolling Sensitivity** using windowed covariance and variance formulas to calculate 30-day rolling Beta and Pearson correlation coefficients.
3. **Generates Technical Indicators** including 20-day Simple Moving Averages (SMA-20) and Bollinger Bands ($\pm 2\sigma$) to identify overbought/oversold trading conditions.
4. **Consolidates Analytics** into a master dataset for financial dashboarding and executive reporting in Excel.

---

## 🗂️ Data Architecture & Schema

The relational model consists of two core fact tables linked by trading dates[cite: 1]:

### 1. `Fact_ONGC_Stock` (Equity Performance)
Stores daily trading session metrics for ONGC[cite: 1].
* `trade_date` (DATE, Primary Key): Calendar date of the trading session[cite: 1].
* `open_price`, `high_price`, `low_price`, `close_price` (DECIMAL 10,4): Price points in INR[cite: 1].
* `volume` (BIGINT): Total share volume traded[cite: 1].

### 2. `Fact_Brent_Crude` (Macro Benchmark)
Tracks daily closing prices for Brent Crude oil[cite: 1].
* `trade_date` (DATE, Primary Key / Foreign Key): References `Fact_ONGC_Stock(trade_date)` with `ON DELETE CASCADE`[cite: 1].
* `crude_close` (DECIMAL 10,4): Daily crude oil closing price in USD[cite: 1].

---

## 🧮 Quantitative Methods & Formulas

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

## 📂 Repository Structure

```text
├── sql file 1.sql      # Database initialization, schema DDL, bulk data loading & cleaning
├── sql file 2.sql      # Advanced SQL CTEs for Beta, Correlation, Bollinger Bands & Master Join
├── Final sql output.csv # Exported analytics dataset containing 127 trading days of metrics
└── README.md            # Project documentation



# ONGC Quantitative Financial & Sensitivity Analytics — Excel Dashboard

## 📌 Executive Summary
This section documents the Excel analytical layer built on top of the consolidated ONGC quantitative dataset[cite: 1]. By leveraging advanced dynamic array formulas, statistical lookups, and Pivot Tables, this model evaluates equity performance, systematic risk ($\beta$), and macro sensitivity against global Brent Crude oil prices[cite: 1].

---

## 📈 Key Metric KPI Queries

The following table details the dynamic formulas implemented in the executive summary block of the dashboard along with their verified analytical outputs:

| Metric Indicator / Query Description | Excel Formula | Verified Output | Key Analytical Context |
| :--- | :--- | :---: | :--- |
| **Latest Close Price on a 'Critical' Event** | `=XLOOKUP("Critical", ONGC_Master[event_severity], ONGC_Master[close_price], "No Event Found", 0, -1)` | **299.80** | Closing stock price recorded on the most recent critical shock date (`2026-06-05`)[cite: 1]. |
| **Average Daily Return on Geopolitical Event Days** | `=AVERAGEIFS(ONGC_Master[daily_return_pct], ONGC_Master[event_name], "<>Regular Trading")` | **0.96%** | Measures average stock return on geopolitical shock dates versus regular trading days[cite: 1]. |
| **Count Days with High Volatility (>2.5%) and High Beta (>0.80)** | `=COUNTIFS(ONGC_Master[intraday_volatility_pct], ">2.5", ONGC_Master[rolling_30d_beta], ">0.80")` | **3** | Identifies trading sessions where high market volatility coincided with high crude sensitivity[cite: 1]. |
| **Overall Stock vs Crude Pearson Correlation** | `=LET(stock_ret, FILTER(ONGC_Master[daily_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), crude_ret, FILTER(ONGC_Master[crude_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), CORREL(stock_ret, crude_ret))` | **0.9860** | Indicates an extremely high direct linear co-movement between crude oil returns and ONGC equity returns. |
| **Overall Stock Beta against Brent Crude** | `=LET(stock_ret, FILTER(ONGC_Master[daily_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), crude_ret, FILTER(ONGC_Master[crude_return_pct], ISNUMBER(ONGC_Master[crude_return_pct])), SLOPE(stock_ret, crude_ret))` | **0.8435** | Demonstrates that ONGC stock moves approximately 0.84% for every 1.00% change in Brent Crude oil prices. |

---

## 📊 Pivot Table Architecture

### 1. Risk Matrix by Event Severity
* **Rows:** `event_severity` (`Critical`, `High`, `Regular Trading`)[cite: 1]
* **Values:** `AVERAGE of daily_return_pct`, `AVERAGE of intraday_volatility_pct`, `AVERAGE of rolling_30d_beta`, `COUNT of trade_date`[cite: 1]
* **Insight:** Displays how market shocks trigger higher intraday volatility spreads (up to **3.41%**) compared to standard trading conditions (**1.82%**)[cite: 1].

### 2. Technical Signal Breakdown (Bollinger Bands)
* **Rows:** `signal_status` (`Normal Range`, `Overbought (Above Upper Band)`)
* **Values:** `AVERAGE of daily_return_pct`, `AVERAGE of intraday_volatility_pct`, `COUNT of trade_date`[cite: 1]
* **Insight:** Evaluates performance across **14 overbought breakout sessions**, where daily returns averaged **1.12%** vs **-0.04%** during normal trading bands.

---

## 🛠️ Excel File Structure
* **`Dashboard`**: Contains executive summary KPI cards, key dynamic formulas, and interactive slicers (`event_severity`, `signal_status`)[cite: 1].
* **`Analytics`**: Holds all Pivot Tables and dynamic array outputs (e.g., `FILTER` breakout sub-tables).
* **`Data`**: Houses the core structured Excel Table (`ONGC_Master`)[cite: 1].
