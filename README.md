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
