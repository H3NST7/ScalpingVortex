//+------------------------------------------------------------------+
//|                                               ScalpingVortex.mq5 |
//+------------------------------------------------------------------+
#property copyright "ScalpingVortex"
#property link      "https://github.com/H3NST7/ScalpingVortex"
#property version   "1.00"
#property strict

// Include system core
#include "ScalpingVortex\SVCore.mqh"

//--- Input Parameters
// General settings
input int    InpMagicNumber = 12345;       // Magic number
input int    InpSlippage = 3;              // Maximum slippage in points

// Risk management
input double InpRiskPerTrade = 1.0;        // Risk per trade (% of account)
input int    InpMaxTrades = 5;             // Maximum concurrent trades

// Trading schedule
input bool   InpTradingEnabled = true;     // Enable trading
input string InpTradingHoursStart = "08:00"; // Trading hours start (server time)
input string InpTradingHoursEnd = "20:00";  // Trading hours end (server time)
input bool   InpTradeFriday = true;        // Allow trading on Friday
input bool   InpTradeMonday = true;        // Allow trading on Monday

// Trading direction
input bool   InpAllowLongs = true;         // Allow long trades
input bool   InpAllowShorts = true;        // Allow short trades

// Indicators
input int    InpFastMA = 20;               // Fast MA period
input int    InpSlowMA = 50;               // Slow MA period
input int    InpRSIPeriod = 14;            // RSI period
input int    InpATRPeriod = 14;            // ATR period
input double InpMinVolatilityATR = 0.0005; // Minimum volatility (ATR value)

// Trade management
input bool   InpUseTrailingStop = true;    // Use trailing stop
input double InpTrailingStopATR = 1.5;     // Trailing stop (ATR multiplier)
input bool   InpUseBreakEven = true;       // Enable break even
input double InpBreakEvenPips = 15.0;      // Break even after profit (pips)
input double InpBreakEvenBuffer = 5.0;     // Break even buffer (pips)

// Timeframe settings
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M15; // Trading timeframe

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CSVCore* g_core = NULL;           // Core system pointer
int g_timerInterval = 60;         // Timer interval in seconds
datetime g_lastTrailingCheckTime = 0; // Last trailing stop check time
datetime g_lastBreakEvenCheckTime = 0; // Last break even check time

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Print system start message
   Print("ScalpingVortex EA initializing...");
   
   // Create the core system
   if(g_core != NULL)
   {
      delete g_core;
      g_core = NULL;
   }
   
   g_core = new CSVCore();
   
   if(g_core == NULL)
   {
      Print("Failed to create core system! Not enough memory?");
      return INIT_FAILED;
   }
   
   // Initialize core system with input parameters
   if(!g_core.Initialize(InpMagicNumber, InpSlippage, InpRiskPerTrade, Symbol(), InpTimeframe))
   {
      Print("Failed to initialize core system!");
      delete g_core;
      g_core = NULL;
      return INIT_FAILED;
   }
   
   // Configure the system based on input parameters
   g_core.SetMaxConcurrentTrades(InpMaxTrades);
   g_core.SetDirectionalBias(InpAllowLongs, InpAllowShorts);
   g_core.SetMinimumVolatility(InpMinVolatilityATR);
   
   // Set trading mode
   if(InpTradingEnabled)
      g_core.EnableTrading();
   else
      g_core.DisableTrading();
   
   // Initialize the market analyzer with custom settings
   CSVMarketAnalyzer* marketAnalyzer = g_core.GetMarketAnalyzer();
   if(marketAnalyzer != NULL)
   {
      // Re-initialize with custom indicator settings
      marketAnalyzer.Initialize(InpFastMA, InpSlowMA, InpATRPeriod, InpRSIPeriod, 20, 2.0, 10);
   }
   
   // Initialize timer
   EventSetTimer(g_timerInterval);
   
   // Reset tracking variables
   g_lastTrailingCheckTime = 0;
   g_lastBreakEvenCheckTime = 0;
   
   // Display initialization success message
   Print("ScalpingVortex EA initialized successfully!");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Stop the timer
   EventKillTimer();
   
   // Clean up the core system
   if(g_core != NULL)
   {
      delete g_core;
      g_core = NULL;
   }
   
   // Print deinitialization message
   Print("ScalpingVortex EA deinitialized. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_core == NULL || !g_core.IsInitialized())
      return;
      
   // Process tick in the core system
   g_core.ProcessTick();
   
   // Check if we need to update trailing stops
   if(InpUseTrailingStop)
      ManageTrailingStops();
   
   // Check if we need to update break even stops
   if(InpUseBreakEven)
      ManageBreakEven();
}

//+------------------------------------------------------------------+
//| Expert timer function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_core == NULL || !g_core.IsInitialized())
      return;
      
   // Process timer in the core system
   g_core.ProcessTimer();
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                     |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
   // Get current time
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // Check day of week restrictions
   if(dt.day_of_week == 1 && !InpTradeMonday)
      return false;
      
   if(dt.day_of_week == 5 && !InpTradeFriday)
      return false;
      
   // Check trading hours
   int currentHour = dt.hour;
   int currentMinute = dt.min;
   int currentTimeMinutes = currentHour * 60 + currentMinute;
   
   // Parse trading hours start
   int startHour = (int)StringToInteger(StringSubstr(InpTradingHoursStart, 0, 2));
   int startMinute = (int)StringToInteger(StringSubstr(InpTradingHoursStart, 3, 2));
   int startTimeMinutes = startHour * 60 + startMinute;
   
   // Parse trading hours end
   int endHour = (int)StringToInteger(StringSubstr(InpTradingHoursEnd, 0, 2));
   int endMinute = (int)StringToInteger(StringSubstr(InpTradingHoursEnd, 3, 2));
   int endTimeMinutes = endHour * 60 + endMinute;
   
   // Check if current time is within trading hours
   return (currentTimeMinutes >= startTimeMinutes && currentTimeMinutes <= endTimeMinutes);
}

//+------------------------------------------------------------------+
//| Manage trailing stops for open positions                          |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
   // Check if it's time to update trailing stops (once per minute)
   datetime currentTime = TimeCurrent();
   if(currentTime - g_lastTrailingCheckTime < 60)
      return;
      
   g_lastTrailingCheckTime = currentTime;
   
   // Get trade manager
   CSVTradeManager* tradeManager = g_core.GetTradeManager();
   if(tradeManager == NULL)
      return;
      
   // Get market analyzer for ATR values
   CSVMarketAnalyzer* marketAnalyzer = g_core.GetMarketAnalyzer();
   if(marketAnalyzer == NULL)
      return;
      
   // Get ATR value for trailing stop calculation
   double atr = marketAnalyzer.GetAverageTrueRange(Symbol(), InpTimeframe);
   double trailingDistance = atr * InpTrailingStopATR;
   
   // Get current price
   double bid = MarketInfo(Symbol(), MODE_BID);
   double ask = MarketInfo(Symbol(), MODE_ASK);
   
   // Loop through all open orders
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
         
      // Only process orders for our EA
      if(OrderMagicNumber() != InpMagicNumber || OrderSymbol() != Symbol())
         continue;
         
      int orderType = OrderType();
      int ticket = OrderTicket();
      double openPrice = OrderOpenPrice();
      double currentSL = OrderStopLoss();
      double currentTP = OrderTakeProfit();
      
      // Calculate new stop loss based on trailing settings
      double newSL = currentSL;
      
      if(orderType == OP_BUY)
      {
         // For buy orders, move stop loss up as price moves up
         double potentialSL = NormalizeDouble(bid - trailingDistance, Digits);
         
         // Only move stop loss up, never down
         if(potentialSL > currentSL && bid > openPrice)
            newSL = potentialSL;
      }
      else if(orderType == OP_SELL)
      {
         // For sell orders, move stop loss down as price moves down
         double potentialSL = NormalizeDouble(ask + trailingDistance, Digits);
         
         // Only move stop loss down, never up
         if((potentialSL < currentSL || currentSL == 0) && ask < openPrice)
            newSL = potentialSL;
      }
      
      // Modify the order if stop loss has changed
      if(MathAbs(newSL - currentSL) > Point)
      {
         if(!tradeManager.ModifyOrder(ticket, newSL, currentTP))
         {
            int errorCode = GetLastError();
            Print("Failed to update trailing stop for order #", ticket, ": ", errorCode, " - ", GetErrorDescription(errorCode));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage break even stops for open positions                       |
//+------------------------------------------------------------------+
void ManageBreakEven()
{
   // Check if it's time to update break even stops (once per minute)
   datetime currentTime = TimeCurrent();
   if(currentTime - g_lastBreakEvenCheckTime < 60)
      return;
      
   g_lastBreakEvenCheckTime = currentTime;
   
   // Get trade manager
   CSVTradeManager* tradeManager = g_core.GetTradeManager();
   if(tradeManager == NULL)
      return;
      
   // Convert pips to points
   double breakEvenPipsPoints = InpBreakEvenPips * 10.0 * Point;
   double breakEvenBufferPoints = InpBreakEvenBuffer * 10.0 * Point;
   
   // Get current price
   double bid = MarketInfo(Symbol(), MODE_BID);
   double ask = MarketInfo(Symbol(), MODE_ASK);
   
   // Loop through all open orders
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
         
      // Only process orders for our EA
      if(OrderMagicNumber() != InpMagicNumber || OrderSymbol() != Symbol())
         continue;
         
      int orderType = OrderType();
      int ticket = OrderTicket();
      double openPrice = OrderOpenPrice();
      double currentSL = OrderStopLoss();
      double currentTP = OrderTakeProfit();
      
      // Skip orders that already have SL at or better than break even
      if(orderType == OP_BUY && currentSL >= openPrice)
         continue;
         
      if(orderType == OP_SELL && currentSL <= openPrice && currentSL > 0)
         continue;
      
      // Calculate break even stop loss
      double newSL = 0;
      bool shouldModify = false;
      
      if(orderType == OP_BUY)
      {
         // For buy orders, set to break even if price moves up enough
         if(bid >= openPrice + breakEvenPipsPoints)
         {
            newSL = openPrice + breakEvenBufferPoints;
            shouldModify = true;
         }
      }
      else if(orderType == OP_SELL)
      {
         // For sell orders, set to break even if price moves down enough
         if(ask <= openPrice - breakEvenPipsPoints)
         {
            newSL = openPrice - breakEvenBufferPoints;
            shouldModify = true;
         }
      }
      
      // Modify the order if needed
      if(shouldModify)
      {
         if(!tradeManager.ModifyOrder(ticket, newSL, currentTP))
         {
            int errorCode = GetLastError();
            Print("Failed to update break even stop for order #", ticket, ": ", errorCode, " - ", GetErrorDescription(errorCode));
         }
         else
         {
            Print("Updated order #", ticket, " to break even. New SL: ", newSL);
         }
      }
   }
}
