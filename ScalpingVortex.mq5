//+------------------------------------------------------------------+
//|                                             ScalpingVortex.mq5 |
//|                                             Scalping Vortex EA |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Scalping Vortex"
#property link      "https://github.com/H3NST7/ScalpingVortex"
#property version   "1.00"

// Include required files
#include <Trade\Trade.mqh>
#include "SVCore.mqh"
#include "SVMarketAnalyzer.mqh"
#include "SVTradeManager.mqh"
#include "SVPortfolio.mqh"
#include "SVRiskEngine.mqh"
#include "SVUtils.mqh"

// Input parameters
input string          InpGeneral         = "=== General Settings ===";       // === General Settings ===
input string          InpSymbol          = "";                               // Symbol (empty = current)
input ENUM_TIMEFRAMES InpTimeframe       = PERIOD_CURRENT;                   // Timeframe
input int             InpMagicNumber     = 123456;                           // Magic number
input bool            InpEnableTrading   = true;                             // Enable trading
input bool            InpDebugMode       = false;                            // Debug mode

input string          InpTradeParams     = "=== Trading Parameters ===";     // === Trading Parameters ===
input int             InpMaxTrades       = 3;                                // Maximum concurrent trades
input bool            InpAllowLongs      = true;                             // Allow long trades
input bool            InpAllowShorts     = true;                             // Allow short trades
input double          InpMinVolatilityATR= 0.0;                              // Minimum ATR volatility

input string          InpIndicators      = "=== Indicator Parameters ===";   // === Indicator Parameters ===
input int             InpFastMA          = 20;                               // Fast MA period
input int             InpSlowMA          = 50;                               // Slow MA period
input int             InpRSIPeriod       = 14;                               // RSI period
input int             InpATRPeriod       = 14;                               // ATR period
input int             InpMACDFast        = 12;                               // MACD fast EMA period
input int             InpMACDSlow        = 26;                               // MACD slow EMA period
input int             InpMACDSignal      = 9;                                // MACD signal period

input string          InpRiskParams      = "=== Risk Parameters ===";        // === Risk Parameters ===
input double          InpRiskPercent     = 2.0;                              // Risk per trade in percentage
input double          InpMaxEquityRisk   = 10.0;                             // Maximum equity at risk
input double          InpMinRewardRatio  = 1.5;                              // Minimum reward-to-risk ratio
input double          InpATRMultiplier   = 2.0;                              // ATR multiplier for stops
input bool            InpUseFixedLots    = false;                            // Use fixed lot size
input double          InpFixedLotSize    = 0.01;                             // Fixed lot size
input bool            InpUseEquityProtection = true;                         // Use equity protection
input double          InpEquityProtectionLevel = 90.0;                       // Equity protection level in percentage

input string          InpSessionParams   = "=== Session Parameters ===";     // === Session Parameters ===
input bool            InpFilterSessions  = false;                            // Filter trading sessions
input bool            InpAllowAsianSession = true;                          // Allow trading during Asian session
input bool            InpAllowEuropeanSession = true;                       // Allow trading during European session
input bool            InpAllowUSSession  = true;                            // Allow trading during US session

// Global variables
CSVCore*             g_core = NULL;              // Core EA object
bool                 g_initialized = false;      // Initialization flag
int                  g_timerCounter = 0;         // Timer counter

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize utility class
   CSVUtils::Initialize("ScalpingVortex");
   
   // Set debug mode
   if(InpDebugMode)
      CSVUtils::SetLogLevel(LOG_LEVEL_DEBUG);
   else
      CSVUtils::SetLogLevel(LOG_LEVEL_INFO);
   
   // Log initialization
   CSVUtils::Log(LOG_LEVEL_INFO, "Initializing ScalpingVortex EA...");
   
   // Determine symbol
   string symbol = InpSymbol == "" ? Symbol() : InpSymbol;
   
   // Create and initialize core object
   g_core = new CSVCore();
   if(!g_core.Initialize(symbol, InpTimeframe, InpMagicNumber))
   {
      CSVUtils::Log(LOG_LEVEL_ERROR, "Failed to initialize EA core. Error: " + g_core.GetLastErrorDescription());
      delete g_core;
      g_core = NULL;
      return INIT_FAILED;
   }
   
   // Set trading parameters
   g_core.SetMaxConcurrentTrades(InpMaxTrades);
   g_core.SetDirectionalBias(InpAllowLongs, InpAllowShorts);
   g_core.SetMinimumVolatility(InpMinVolatilityATR);
   
   // Enable/disable trading
   if(InpEnableTrading)
      g_core.EnableTrading();
   else
      g_core.DisableTrading();
   
   // Initialize market analyzer
   CSVMarketAnalyzer* analyzer = g_core.GetMarketAnalyzer();
   if(analyzer != NULL)
   {
      analyzer.Initialize(symbol, InpFastMA, InpSlowMA, InpATRPeriod, InpRSIPeriod, InpMACDFast, InpMACDSlow, InpMACDSignal);
      analyzer.EnableSessionFiltering(InpFilterSessions);
      analyzer.SetTradingSessions(InpAllowAsianSession, InpAllowEuropeanSession, InpAllowUSSession);
   }
   
   // Initialize risk engine
   CSVRiskEngine* riskEngine = g_core.GetRiskEngine();
   if(riskEngine != NULL)
   {
      riskEngine.SetRiskPercent(InpRiskPercent);
      riskEngine.SetMaxEquityRisk(InpMaxEquityRisk);
      riskEngine.SetMinRewardRatio(InpMinRewardRatio);
      riskEngine.UseFixedLots(InpUseFixedLots);
      riskEngine.SetFixedLotSize(InpFixedLotSize);
      riskEngine.UseATRStops(true, InpATRMultiplier);
      riskEngine.UseEquityProtection(InpUseEquityProtection, InpEquityProtectionLevel);
   }
   
   // Set initialization flag
   g_initialized = true;
   
   // Set timer for periodic checks
   EventSetTimer(1);
   
   // Log successful initialization
   CSVUtils::Log(LOG_LEVEL_INFO, "ScalpingVortex EA initialized successfully");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Log deinitialization
   CSVUtils::Log(LOG_LEVEL_INFO, "Deinitializing ScalpingVortex EA. Reason: " + IntegerToString(reason));
   
   // Stop timer
   EventKillTimer();
   
   // Clean up core object
   if(g_core != NULL)
   {
      delete g_core;
      g_core = NULL;
   }
   
   // Reset initialization flag
   g_initialized = false;
   
   // Deinitialize utility class
   CSVUtils::Deinitialize();
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if EA is initialized
   if(!g_initialized || g_core == NULL)
      return;
      
   // Check if trading is allowed
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      CSVUtils::Log(LOG_LEVEL_WARNING, "Trading is not allowed");
      return;
   }
   
   // Process tick in core
   if(!g_core.ProcessTick())
   {
      CSVUtils::Log(LOG_LEVEL_ERROR, "Error processing tick: " + g_core.GetLastErrorDescription());
   }
}

//+------------------------------------------------------------------+
//| Expert timer function                                           |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Check if EA is initialized
   if(!g_initialized || g_core == NULL)
      return;
      
   // Process timer event
   if(!g_core.ProcessTimer())
   {
      CSVUtils::Log(LOG_LEVEL_ERROR, "Error processing timer: " + g_core.GetLastErrorDescription());
   }
   
   // Increment timer counter
   g_timerCounter++;
   
   // Every 60 seconds, perform additional checks
   if(g_timerCounter >= 60)
   {
      // Reset counter
      g_timerCounter = 0;
      
      // Check for daily limits, equity protection, etc.
      CheckProtectionLimits();
   }
}

//+------------------------------------------------------------------+
//| Trade event function                                            |
//+------------------------------------------------------------------+
void OnTrade()
{
   // This function is called when a trade operation occurs
   // It can be used to update portfolio statistics, etc.
   
   // Check if EA is initialized
   if(!g_initialized || g_core == NULL)
      return;
      
   // Update portfolio
   CSVPortfolio* portfolio = g_core.GetPortfolio();
   if(portfolio != NULL)
   {
      portfolio.Update();
   }
}

//+------------------------------------------------------------------+
//| Check protection limits                                          |
//+------------------------------------------------------------------+
void CheckProtectionLimits()
{
   // Check if EA is initialized
   if(!g_initialized || g_core == NULL)
      return;
      
   // Get components
   CSVRiskEngine* riskEngine = g_core.GetRiskEngine();
   CSVPortfolio* portfolio = g_core.GetPortfolio();
   
   if(riskEngine == NULL || portfolio == NULL)
      return;
      
   // Check equity protection
   if(InpUseEquityProtection && !riskEngine.IsEquityRiskAcceptable())
   {
      CSVUtils::Log(LOG_LEVEL_WARNING, "Equity protection triggered. Disabling trading.");
      g_core.DisableTrading();
      
      // Close all positions
      CSVTradeManager* tradeManager = g_core.GetTradeManager();
      if(tradeManager != NULL)
      {
         tradeManager.CloseAllPositions();
         tradeManager.DeleteAllOrders();
      }
   }
   
   // Check daily loss limit
   if(riskEngine.UseDailyLossLimit() && !riskEngine.IsDailyLossAcceptable())
   {
      CSVUtils::Log(LOG_LEVEL_WARNING, "Daily loss limit triggered. Disabling trading for today.");
      g_core.DisableTrading();
   }
}
