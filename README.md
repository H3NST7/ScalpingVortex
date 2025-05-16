# ScalpingVortex: A High-Frequency Algorithmic Trading System for XAUUSD

**Version:** 1.0.0 (Genesis Build)
**Lead Architect:** H3nst7
**Copyright:** 2025, H3nst7
**License:** MIT License

[![MQL5 Compilation](https://img.shields.io/badge/MQL5-Compile_Pass-brightgreen.svg)](https://www.mql5.com)
[![Platform](https://img.shields.io/badge/Platform-MetaTrader_5-blue.svg)](https://www.metatrader5.com)
[![Instrument](https://img.shields.io/badge/Instrument-XAUUSD_(Gold)-gold.svg)]()
[![Strategy](https://img.shields.io/badge/Strategy-Scalping-critical.svg)]()

---

## I. Executive Summary

ScalpingVortex is an institutional-grade Expert Advisor (EA) meticulously engineered for high-frequency scalping operations exclusively on the XAUUSD (Gold) market within the MetaTrader 5 platform. This system represents a sophisticated synthesis of quantitative trading principles, robust software architecture, and advanced risk management protocols. Its primary design objective is to achieve consistent alpha generation and facilitate systematic capital growth, particularly enabling the scaling of trading accounts from modest initial balances towards significant capital thresholds (e.g., $10,000 and beyond).

The architecture emphasizes modularity, computational efficiency, resilience, and adaptability, aiming to provide a durable edge in the dynamic and highly competitive XAUUSD environment.

---

## II. Architectural Philosophy & Design Principles

ScalpingVortex is built upon a foundation of modern software engineering and quantitative finance best practices:

*   **Object-Oriented Design (OOP):** Leverages encapsulation, inheritance, and polymorphism for a clean, modular, and extensible codebase, facilitating complex system development and maintenance.
*   **Separation of Concerns (SoC):** Each module possesses a distinct, well-defined responsibility (e.g., market analysis, risk, execution), promoting clarity and reducing inter-dependencies.
*   **High Cohesion, Low Coupling:** Modules are internally focused with strong internal logic and externally independent, minimizing cascading changes and simplifying isolated testing and upgrades.
*   **Data-Driven & Empirically Validated:** The system is designed to support strategies and parameters that can be rigorously backtested, optimized using MT5's Strategy Tester, and statistically validated with exported trade data.
*   **Resilience & Fault Tolerance:** Robust error handling, state management (e.g., `PAUSED_NEWS`, `RISK_LIMIT_HIT`), and graceful degradation are implemented to ensure operational stability under adverse market or broker conditions.
*   **Performance-Critical Implementation:** Core logic paths, indicator calculations, and event handling are optimized for low-latency execution, which is paramount for effective high-frequency scalping.
*   **Adaptive Risk Management:** Risk is not merely a constraint but an integral component of the growth engine. The `CSVRiskEngine` dynamically adjusts parameters based on market volatility and portfolio performance, aiming for consistent risk exposure and capital protection.

---

## III. System Components & Modules

ScalpingVortex employs a modular architecture, with each component residing in its dedicated include file within the `MQL5/Include/ScalpingVortex/` directory.

1.  **`ScalpingVortex.mq5` (Main EA Orchestrator):**
    *   Entry point for MetaTrader 5.
    *   Manages global EA parameters (Magic Number, Logging Level, Master Risk Factor), event handling (`OnInit`, `OnTick`, `OnDeinit`, `OnTester`), and overall EA lifecycle.
    *   Instantiates and coordinates the `CSVCore`.

2.  **`SVCore.mqh` (`CSVCore` Class - Central Nervous System):**
    *   The core logic unit, orchestrating interactions between all other service modules.
    *   Manages EA operational states, the main trading loop (typically driven by `OnTick` or a high-resolution `OnTimer`), and the flow of signals from market analysis to strategy evaluation and trade execution.

3.  **`SVMarketAnalyzer.mqh` (`CSVMarketAnalyzer` Class - Market Intelligence):**
    *   Provides comprehensive, real-time, and historical analysis specifically tailored for XAUUSD scalping.
    *   Calculates scalping-relevant indicators: ATR (e.g., 14-period), short-term EMAs (e.g., 5, 10, 20), RSI (e.g., 7, 14), Stochastic Oscillator (e.g., 5,3,3), Bollinger Bands (e.g., 20-period, 2.0 SD).
    *   Analyzes market microstructure: real-time spread, tick velocity/density, intraday volatility regimes (ATR vs. historical benchmarks), and XAUUSD active trading session identification (Asia, London, New York, and their overlaps).

4.  **`SVRiskEngine.mqh` (`CSVRiskEngine` Class - Capital Preservation & Growth):**
    *   Implements sophisticated, multi-layered risk management protocols.
    *   Features dynamic position sizing (e.g., Volatility-Normalized Risk, targeting 0.5% equity risk per trade adjusted by ATR), adaptive Stop-Loss/Take-Profit logic (ATR-multiples), portfolio-level drawdown controls (e.g., max 2% daily drawdown), and advanced trade management rules (e.g., move to Break-Even at +0.75R, ATR-based trailing stop).

5.  **`SVStrategies.mqh` (`CSVStrategyBase` & Concrete Strategies - Alpha Generation):**
    *   Houses the specific trading algorithms. `CSVStrategyBase` defines the common interface.
    *   Includes concrete implementations like:
        *   `CSVRangeFadeScalper`: Targets mean reversion from short-term XAUUSD range extremes.
        *   `CSVImpulseRiderScalper`: Aims to capture initial momentum from rapid price/volume surges.
    *   Strategies utilize `CSVMarketAnalyzer` for signal inputs and `CSVRiskEngine` for risk parameterization.

6.  **`SVTradeManager.mqh` (`CSVTradeManager` Class - Execution Precision):**
    *   Manages all aspects of order placement, modification, and closure with a focus on reliability.
    *   Employs asynchronous order handling (`OrderSendAsync` and `OnTradeTransaction`), slippage control (e.g., max 2-3 pips deviation for XAUUSD), retry mechanisms for transient errors, and robust processing of `TRADE_RETCODE` values.

7.  **`SVOptimizer.mqh` (`CSVOptimizer` Class - Parameter & Performance Hub):**
    *   Facilitates parameter set management and provides hooks for potential future adaptive parameter tuning.
    *   Critically, supports detailed trade logging during `OnTester` (to `MQL5/Files/ScalpingVortex_OptimizationTrades.csv`) for external performance analysis with tools like Python (Pandas, Matplotlib) or QuantAnalyzer.

8.  **`SVUtils.mqh` (Static `CSVUtils` Class / Namespace `SVUtils` - Utility Toolkit):**
    *   Provides common, reusable functionalities:
        *   Advanced Logging: `CSVUtils::Log(LogLevel::INFO, "SVCore", "Initialization complete.")`.
        *   Date/Time Utilities: Session identification, news window checks (e.g., input string: `"08:25-08:35=NO_TRADE;12:25-12:35=NO_TRADE"` for pre-London/NY open news).
        *   XAUUSD Financial Property Retrieval: `SymbolInfoDouble(XAUUSD_SYMBOL, SYMBOL_POINT)`, `SymbolInfoInteger(XAUUSD_SYMBOL, SYMBOL_DIGITS)`.
        *   Standardized error formatting.

9.  **`SVPortfolio.mqh` (`CSVPortfolio` Class - Holistic Performance Accounting):**
    *   Tracks overall account health (Balance, Equity, Margin) and EA-specific performance metrics: Realized/Unrealized P&L, Current Drawdown from Equity Peak, Win Rate, Profit Factor, Trade Expectancy.
    *   Interfaces with `CSVRiskEngine` to enforce portfolio-level risk limits (e.g., halting trades if daily drawdown hits configured threshold).

---

## IV. Key Features & Capabilities

*   **XAUUSD Specialization:** All components, calculations, and default parameters are fine-tuned for the unique volatility and microstructure of Gold trading.
*   **Advanced Risk Management:** Volatility-adjusted position sizing, ATR-based dynamic stops & targets, intelligent break-even logic, multi-stage trailing stops, and comprehensive account/session drawdown controls.
*   **Modular Strategy Framework:** Supports diverse, pluggable scalping algorithms (currently `CSVRangeFadeScalper` and `CSVImpulseRiderScalper`). Easily extensible for new strategies.
*   **High-Precision Execution:** Asynchronous order management designed to minimize latency and handle common broker execution quirks, with slippage control and robust error recovery.
*   **Adaptive Potential:** Architectural hooks within `SVOptimizer` and `CSVRiskEngine` for future integration of adaptive parameter tuning based on evolving performance or diagnosed market regimes.
*   **Comprehensive Logging & Auditing:** Granular logging (DEBUG, INFO, WARN, ERROR, CRITICAL levels) to Experts tab and optional disk file for debugging, performance monitoring, and detailed audit trails.
*   **Optimization-Ready:** Designed for efficient parameter optimization using MetaTrader 5's Strategy Tester. The `SVOptimizer` module facilitates detailed trade data export (CSV format) for sophisticated external analysis.
*   **Session & News Awareness:** User-configurable time windows to restrict trading activity during specific sessions or around high-impact news releases to mitigate event risk.

---

## V. Installation & Setup

1.  **Clone/Download Repository:**
    ```bash
    git clone https://github.com/H3nst7/ScalpingVortex.git
    ```
    Alternatively, download the ZIP archive from the repository page and extract its contents.

2.  **File Placement (Standard MT5 Structure):**
    *   Copy `ScalpingVortex.mq5` to your MetaTrader 5 Data Folder: `[MT5 Data Folder]/MQL5/Experts/`.
    *   Create a subdirectory named `ScalpingVortex` within `[MT5 Data Folder]/MQL5/Include/`.
    *   Copy all `.mqh` files (e.g., `SVCore.mqh`, `SVMarketAnalyzer.mqh`, etc.) into this newly created `[MT5 Data Folder]/MQL5/Include/ScalpingVortex/` directory.

3.  **Compilation:**
    *   Open MetaEditor from your MetaTrader 5 terminal (Tools -> MetaQuotes Language Editor, or F4).
    *   In the MetaEditor's "Navigator" window, locate and expand `Experts`. Double-click `ScalpingVortex.mq5` to open it.
    *   Click the "Compile" button in the toolbar (or press F7).
    *   Verify that the compilation completes successfully, with "0 error(s), 0 warning(s)" displayed in the "Errors" tab (ensure "strict" compilation is enabled in MetaEditor options).

4.  **EA Configuration (Input Parameters):**
    When attaching ScalpingVortex to a XAUUSD chart in MetaTrader 5:
    *   Navigate to the "Inputs" tab in the EA properties window.
    *   **Key Parameters to Review & Configure:**
        *   `MagicNumber`: (Default: `2025001`) Unique identifier for trades placed by this EA instance.
        *   `LotSizingMethod`: (Enum: `FixedLot`, `PercentEquityRisk`, `VolatilityNormalizedRisk`)
        *   `FixedLotSize`: (e.g., `0.01`) Used if `LotSizingMethod` is `FixedLot`.
        *   `RiskPercentPerTrade`: (e.g., `0.5` for 0.5%) Used for equity-based sizing.
        *   `ATR_Period_Risk`: (e.g., `14`) ATR period for volatility-normalized sizing and SL/TP.
        *   `MaxSpread_Pips`: (e.g., `3.0`) Maximum allowable spread in pips for trade entry.
        *   `MaxSlippage_Pips`: (e.g., `2.0`) Maximum allowable slippage for order execution.
        *   `DailyDrawdownLimit_Percent`: (e.g., `2.0` for 2% of starting daily balance/equity).
        *   `Strategy_RangeFade_Active`: (bool: `true`/`false`) Enable/disable the Range Fade strategy.
        *   `Strategy_ImpulseRider_Active`: (bool: `true`/`false`) Enable/disable the Impulse Rider strategy.
        *   (Additional parameters for each strategy's indicators and thresholds will be listed).
        *   `NewsFilter_TimesUTC`: (string: e.g., `"08:25-08:35;12:25-12:35;13:55-14:05"`) Semicolon-separated UTC time windows to pause trading.
        *   `LoggingLevel`: (Enum: `Info`, `Debug`, `Warning`, `Error`, `Critical`)

    **It is CRITICAL to understand the function and impact of each parameter before any live trading. Always begin with conservative settings on a demo account.**

---

## VI. Usage Guidelines & Best Practices

*   **DEMO TRADING FIRST:** Extensively test ScalpingVortex on a demo account that mirrors live conditions (spreads, execution speed) for a significant period (weeks/months) before considering live deployment.
*   **XAUUSD Chart Only:** This EA is hyper-optimized for XAUUSD. Performance on other instruments is untested and not recommended.
*   **Timeframe:** While adaptable, scalping strategies within ScalpingVortex are generally designed for M1 or M5 timeframes. Test thoroughly to find optimal chart period settings for your chosen strategies and broker.
*   **Broker Selection:** A broker offering ECN/STP execution with consistently low spreads (e.g., below 1.5-2.0 pips on XAUUSD typically), fast order execution, and minimal slippage is paramount for scalping success.
*   **VPS Recommended:** For 24/7 operation, consistent connectivity, and low latency to broker servers, running ScalpingVortex on a Virtual Private Server (VPS) located geographically close to your broker's trading servers is highly recommended.
*   **Parameter Optimization:** Utilize MetaTrader 5's Strategy Tester (Ctrl+R) with the "Complex criterion max" optimization mode or custom criteria. Leverage the detailed CSV trade logs generated by `SVOptimizer` for in-depth external analysis (e.g., walk-forward analysis, equity curve smoothing, Monte Carlo simulations).
*   **Start Small & Scale Incrementally:** When transitioning to live trading, begin with the absolute minimum risk settings and lot sizes allowed by your broker. Validate performance in the live environment before gradually increasing risk in a controlled manner, aligned with your risk tolerance and capital growth.
*   **Continuous Monitoring & Adaptation:** Regularly monitor the EA's performance, review its logs (especially WARNINGS and ERRORS), and stay informed about the broader market environment. No trading system is a "set and forget" solution, especially in dynamic markets like XAUUSD. Be prepared to re-optimize or adjust parameters as market characteristics evolve.

---

## VII. Risk Disclaimer

**Trading foreign exchange (Forex), contracts for difference (CFDs), and other leveraged financial products carries a high level of risk and may not be suitable for all investors. The high degree of leverage can work against you as well as for you. Before deciding to trade any such leveraged products, you should carefully consider your investment objectives, level of experience, risk tolerance, and financial situation.**

**ScalpingVortex is an Expert Advisor provided "as is," without any express or implied warranty of profitability or fitness for a particular purpose. Past performance, whether in backtests or historical live trading, is not indicative of future results. The developers and distributors of ScalpingVortex assume no liability for any financial losses or damages incurred through its use. You are solely responsible for all your trading decisions and the financial risks associated with them.**

**It is strongly recommended that you seek advice from an independent financial advisor if you have any doubts.**

---

## VIII. Future Development Roadmap (Potential Enhancements - Post v1.0.0)

*   **V1.1:** Integration of more sophisticated market regime detection algorithms (e.g., Hidden Markov Models, volatility clustering) within `SVMarketAnalyzer` to dynamically adjust strategy selection or parameters.
*   **V1.2:** Implementation of advanced adaptive parameter tuning within `SVOptimizer` and `CSVRiskEngine` using feedback loops from recent performance metrics.
*   **V1.3:** Framework for dynamic strategy weighting and capital allocation if multiple strategies are run concurrently.
*   **V1.4:** Enhanced news filtering via integration with a reliable external news calendar API (e.g., ForexFactory, Myfxbook).
*   **V1.5:** Development of an optional on-chart GUI panel for real-time display of key EA stats, performance metrics, and quick-access controls.

---

## IX. Contribution & Feedback

While ScalpingVortex is currently a closed-source project by H3nst7, constructive feedback and bug reports are appreciated. Please open an issue on the GitHub repository if you encounter any problems or have suggestions for improvement that align with the project's core objectives.

---

## X. Contact

For inquiries specifically related to ScalpingVortex, please contact H3nst7 via the project's GitHub issues page:
[https://github.com/H3nst7/ScalpingVortex/issues](https://github.com/H3nst7/ScalpingVortex/issues)
