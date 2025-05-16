//+------------------------------------------------------------------+
//|                                             ScalpingVortex.mq5 |
//|                                           Copyright 2025, H3nst7 |
//|                                           https://www.h3nst7.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, H3nst7"
#property link      "https://www.h3nst7.com"
#property version   "1.00"
#property strict

// Include core system files
#include <ScalpingVortex\SVCore.mqh>

//--- Input parameters for EA configuration
// General Settings
input string   GeneralConfig       = "===== General EA Configuration ====="; // General Configuration
input ulong    MagicNumber         = 20250516;                               // Magic Number
input bool     EnableTrading       = true;                                   // Enable Trading
input bool     EnableAlerts        = false;                                  // Enable Alerts
input ENUM_LOG_LEVEL LogLevel      = LOG_LEVEL_INFO;                         // Logging Detail Level

// Strategy Selection
input string   StrategiesConfig    = "===== Trading Strategies Configuration ====="; // Strategies Configuration
input bool     UseRangeFadeStrategy = true;                                  // Use Range Fade Scalper
input bool     UseImpulseRiderStrategy = true;                               // Use Impulse Rider Scalper

// Risk Management
input string   RiskConfig          = "===== Risk Management Configuration ====="; // Risk Configuration
input double   RiskPerTrade        = 0.5;                                    // Risk Per Trade (% of Balance)
input double   MaxDailyRiskPercent = 3.0;                                    // Maximum Daily Risk (% of Balance)
input int      MaxConcurrentTrades = 3;                                      // Maximum Concurrent Trades
input bool     EnableBreakEven     = true;                                   // Enable Break-Even
input double   BreakEvenAfterPips  = 5.0;                                    // Move SL to BE after X pips profit

// Session Trading Controls
input string   SessionConfig       = "===== Trading Session Configuration ====="; // Session Configuration
input bool     TradeDuringAsian    = true;                                   // Trade During Asian Session
input bool     TradeDuringLondon   = true;                                   // Trade During London Session
input bool     TradeDuringNewYork  = true;                                   // Trade During New York Session
input string   ExcludedTimes       = "13:25-13:35;14:55-15:05";              // No-trade Time Periods (HH:MM-HH:MM;)

// Advanced Performance Options  
input string   AdvancedConfig      = "===== Advanced Performance Configuration ====="; // Advanced Configuration
input bool     UseTimer            = true;                                   // Use Timer Instead of OnTick
input int      TimerIntervalMillis = 250;                                    // Timer Interval (milliseconds)
input int      MaxSpreadPoints     = 50;                                     // Maximum Allowed Spread (points)

//--- Global variables
CSVCore* g_SVCore = NULL;  // Core EA orchestrator

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set up logging with specified level
   CSVUtils::InitializeLogging(LogLevel);
   CSVUtils::Log(LOG_LEVEL_INFO, __FUNCTION__, "ScalpingVortex EA initialization started");
   
   // Check if Symbol is XAUUSD
   if(StringCompare(Symbol(), "XAUUSD") != 0 && StringCompare(Symbol(), "XAUUSDm") != 0 && 
      StringCompare(Symbol(), "GOLD") != 0 && StringCompare(Symbol(), "XAU/USD") != 0) {
      CSVUtils::Log(LOG_LEVEL_CRITICAL, __FUNCTION__, "EA is designed for XAUUSD only. Current symbol: " + Symbol());
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Check if we're on a valid timeframe for scalping
   if(Period() > PERIOD_M15) {
      CSVUtils::Log(LOG_LEVEL_WARNING, __FUNCTION__, 
                   "EA is designed for M1-M15 timeframes. Current timeframe may not be optimal.");
   }

   // Initialize core components
   g_SVCore = new CSVCore();
   if(!g_SVCore) {
      CSVUtils::Log(LOG_LEVEL_CRITICAL, __FUNCTION__, "Failed to initialize Core component");
      return INIT_FAILED;
   }
   
   // Initialize the core with EA parameters
   if(!g_SVCore.Initialize(MagicNumber, EnableTrading, LogLevel, 
                          UseRangeFadeStrategy, UseImpulseRiderStrategy,
                          RiskPerTrade, MaxDailyRiskPercent, MaxConcurrentTrades,
                          EnableBreakEven, BreakEvenAfterPips,
                          TradeDuringAsian, TradeDuringLondon, TradeDuringNewYork,
                          ExcludedTimes, MaxSpreadPoints)) {
      CSVUtils::Log(LOG_LEVEL_CRITICAL, __FUNCTION__, "Core initialization failed");
      return INIT_FAILED;
   }
   
   // Set up timer if enabled
   if(UseTimer) {
      if(!EventSetMillisecondTimer(TimerIntervalMillis)) {
         CSVUtils::Log(LOG_LEVEL_ERROR, __FUNCTION__, "Failed to set up timer");
         return INIT_FAILED;
      }
      CSVUtils::Log(LOG_LEVEL_INFO, __FUNCTION__, "Timer successfully set to " + 
                   IntegerToString(TimerIntervalMillis) + " ms");
   }
   
   ChartRedraw();
   CSVUtils::Log(LOG_LEVEL_INFO, __FUNCTION__, "ScalpingVortex EA initialization completed successfully");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CSVUtils::Log(LOG_LEVEL_INFO, __FUNCTION__, "Deinitializing ScalpingVortex EA, reason: " + 
                IntegerToString(reason));

   // Clean up timer event
   if(UseTimer) {
      EventKillTimer();
   }

   // Clean up core and all associated components
   if(g_SVCore != NULL) {
      delete g_SVCore;
      g_SVCore = NULL;
   }
   
   CSVUtils::Log(LOG_LEVEL_INFO, __FUNCTION__, "ScalpingVortex EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // If we are using timer mode, skip processing on ticks
   if(UseTimer) return;
   
   // Process through the core
   if(g_SVCore != NULL && EnableTrading) {
      g_SVCore.ProcessTick();
   }
}

//+------------------------------------------------------------------+
//| Timer event function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Only process in timer mode
   if(!UseTimer) return;
   
   // Process through the core
   if(g_SVCore != NULL && EnableTrading) {
      g_SVCore.ProcessTick();
   }
}

//+------------------------------------------------------------------+
//| Trade event function                                             |
//+------------------------------------------------------------------+
void OnTrade()
{
   if(g_SVCore != NULL) {
      g_SVCore.ProcessTradeEvent();
   }
}

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(g_SVCore != NULL) {
      g_SVCore.ProcessTradeTransaction(trans, request, result);
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(g_SVCore != NULL) {
      g_SVCore.ProcessChartEvent(id, lparam, dparam, sparam);
   }
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
   if(g_SVCore != NULL) {
      return g_SVCore.ProcessTesterEvent();
   }
   return 0.0;
}
