//+------------------------------------------------------------------+
//|                                             SVDashboard.mq5      |
//+------------------------------------------------------------------+
#property copyright "ScalpingVortex"
#property link      "https://github.com/H3NST7/ScalpingVortex"
#property version   "1.00"
#property strict
#property script_show_inputs

#include "ScalpingVortex\SVUtils.mqh"

// Input parameters
input int InpMagicNumber = 12345;          // Magic number to analyze
input string InpSymbol = "";               // Symbol (empty for current)
input bool InpShowTrades = true;           // Show trade details
input bool InpShowStats = true;            // Show statistics
input bool InpShowAccountInfo = true;      // Show account information
input bool InpShowCurrentMarket = true;    // Show current market conditions

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   // Get symbol
   string symbol = (InpSymbol == "") ? Symbol() : InpSymbol;
   
   // Create header
   string header = "=== ScalpingVortex Dashboard ===";
   string footer = "================================";
   
   // Start building dashboard content
   string content = "";
   content += "\n" + header + "\n";
   content += "Symbol: " + symbol + "\n";
   content += "Date/Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n";
   
   // Add account information
   if(InpShowAccountInfo)
   {
      content += "--- Account Information ---\n";
      content += "Account No.: " + AccountInfoInteger(ACCOUNT_LOGIN) + "\n";
      content += "Account Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Account Equity: " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Account Margin: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Free Margin: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Margin Level: " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + "%\n";
      content += "\n";
   }
   
   // Add current market conditions
   if(InpShowCurrentMarket)
   {
      content += "--- Current Market Conditions ---\n";
      content += "Current Bid: " + DoubleToString(MarketInfo(symbol, MODE_BID), Digits) + "\n";
      content += "Current Ask: " + DoubleToString(MarketInfo(symbol, MODE_ASK), Digits) + "\n";
      content += "Spread: " + DoubleToString((MarketInfo(symbol, MODE_ASK) - MarketInfo(symbol, MODE_BID)) / Point, 1) + " points\n";
      content += "Daily Range: " + DoubleToString(GetDailyRange(symbol), Digits) + " (" + DoubleToString(GetDailyRangePoints(symbol), 0) + " points)\n";
      
      // Get daily high and low
      double dailyHigh, dailyLow;
      GetDailyHighLow(symbol, dailyHigh, dailyLow);
      content += "Daily High: " + DoubleToString(dailyHigh, Digits) + "\n";
      content += "Daily Low: " + DoubleToString(dailyLow, Digits) + "\n";
      
      // Calculate distance to high and low
      double bid = MarketInfo(symbol, MODE_BID);
      double distanceToHigh = (dailyHigh - bid) / Point;
      double distanceToLow = (bid - dailyLow) / Point;
      content += "Distance to High: " + DoubleToString(distanceToHigh, 0) + " points\n";
      content += "Distance to Low: " + DoubleToString(distanceToLow, 0) + " points\n";
      content += "\n";
   }
   
   // Collect trade statistics
   if(InpShowStats)
   {
      int totalTrades = 0;
      int winningTrades = 0;
      int losingTrades = 0;
      double totalProfit = 0.0;
      double totalLoss = 0.0;
      double maxProfit = 0.0;
      double maxLoss = 0.0;
      datetime firstTradeTime = 0;
      datetime lastTradeTime = 0;
      
      // Process historical trades
      int total = OrdersHistoryTotal();
      
      for(int i = 0; i < total; i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
            // Filter by magic number and symbol
            if(OrderMagicNumber() == InpMagicNumber && (InpSymbol == "" || OrderSymbol() == InpSymbol))
            {
               double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
               
               // Track first and last trade times
               if(firstTradeTime == 0 || OrderOpenTime() < firstTradeTime)
                  firstTradeTime = OrderOpenTime();
                  
               if(OrderCloseTime() > lastTradeTime)
                  lastTradeTime = OrderCloseTime();
               
               // Update statistics
               totalTrades++;
               
               if(orderProfit > 0)
               {
                  winningTrades++;
                  totalProfit += orderProfit;
                  
                  if(orderProfit > maxProfit)
                     maxProfit = orderProfit;
               }
               else
               {
                  losingTrades++;
                  totalLoss += orderProfit; // Note: orderProfit is negative here
                  
                  if(orderProfit < maxLoss)
                     maxLoss = orderProfit;
               }
            }
         }
      }
      
      // Calculate additional statistics
      double winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100.0 : 0.0;
      double profitFactor = (totalLoss != 0) ? MathAbs(totalProfit / totalLoss) : 0.0;
      double avgWin = (winningTrades > 0) ? totalProfit / winningTrades : 0.0;
      double avgLoss = (losingTrades > 0) ? MathAbs(totalLoss / losingTrades) : 0.0;
      double expectancy = (winRate / 100.0) * avgWin - (1.0 - winRate / 100.0) * avgLoss;
      
      // Add statistics to content
      content += "--- Trading Statistics ---\n";
      content += "Total Trades: " + IntegerToString(totalTrades) + "\n";
      content += "Winning Trades: " + IntegerToString(winningTrades) + " (" + DoubleToString(winRate, 2) + "%)\n";
      content += "Losing Trades: " + IntegerToString(losingTrades) + " (" + DoubleToString(100.0 - winRate, 2) + "%)\n";
      content += "Total Profit: " + DoubleToString(totalProfit + totalLoss, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
      content += "Average Win: " + DoubleToString(avgWin, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Average Loss: " + DoubleToString(avgLoss, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Max Profit: " + DoubleToString(maxProfit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Max Loss: " + DoubleToString(maxLoss, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      content += "Expectancy: " + DoubleToString(expectancy, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
      
      if(totalTrades > 0)
      {
         content += "First Trade: " + TimeToString(firstTradeTime, TIME_DATE|TIME_SECONDS) + "\n";
         content += "Last Trade: " + TimeToString(lastTradeTime, TIME_DATE|TIME_SECONDS) + "\n";
         
         // Calculate trading duration
         int tradingDays = (int)((lastTradeTime - firstTradeTime) / (60 * 60 * 24));
         content += "Trading Period: " + IntegerToString(tradingDays) + " days\n";
      }
      
      content += "\n";
   }
   
   // Add open trades details
   if(InpShowTrades)
   {
      content += "--- Open Positions ---\n";
      
      int openPositions = 0;
      double currentExposure = 0.0;
      
      // Loop through open orders
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            // Filter by magic number and symbol
            if(OrderMagicNumber() == InpMagicNumber && (InpSymbol == "" || OrderSymbol() == InpSymbol))
            {
               openPositions++;
               
               string orderType = (OrderType() == OP_BUY) ? "BUY" : 
                                 (OrderType() == OP_SELL) ? "SELL" : 
                                 (OrderType() == OP_BUYLIMIT) ? "BUY LIMIT" : 
                                 (OrderType() == OP_SELLLIMIT) ? "SELL LIMIT" : 
                                 (OrderType() == OP_BUYSTOP) ? "BUY STOP" : 
                                 (OrderType() == OP_SELLSTOP) ? "SELL STOP" : "UNKNOWN";
               
               content += "#" + IntegerToString(OrderTicket()) + " " + orderType + " " + 
                        DoubleToString(OrderLots(), 2) + " " + OrderSymbol() + " @ " + 
                        DoubleToString(OrderOpenPrice(), Digits) + 
                        " SL: " + DoubleToString(OrderStopLoss(), Digits) + 
                        " TP: " + DoubleToString(OrderTakeProfit(), Digits) + "\n";
               
               // Calculate current profit
               double currentProfit = OrderProfit() + OrderSwap() + OrderCommission();
               content += "   Opened: " + TimeToString(OrderOpenTime(), TIME_DATE|TIME_SECONDS) + 
                        " P/L: " + DoubleToString(currentProfit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
               
               // Calculate risk information
               double riskAmount = 0.0;
               
               if(OrderType() == OP_BUY && OrderStopLoss() > 0)
               {
                  riskAmount = (OrderOpenPrice() - OrderStopLoss()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
               }
               else if(OrderType() == OP_SELL && OrderStopLoss() > 0)
               {
                  riskAmount = (OrderStopLoss() - OrderOpenPrice()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
               }
               
               if(riskAmount > 0)
               {
                  double riskPercent = riskAmount / AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
                  content += "   Risk: " + DoubleToString(riskAmount, 2) + " (" + DoubleToString(riskPercent, 2) + "%)\n";
               }
               
               // Calculated reward-to-risk ratio
               if(OrderType() == OP_BUY && OrderTakeProfit() > 0 && OrderStopLoss() > 0)
               {
                  double reward = (OrderTakeProfit() - OrderOpenPrice()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
                  double risk = (OrderOpenPrice() - OrderStopLoss()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
                  
                  if(risk > 0)
                  {
                     double rrRatio = reward / risk;
                     content += "   R:R Ratio: " + DoubleToString(rrRatio, 2) + ":1\n";
                  }
               }
               else if(OrderType() == OP_SELL && OrderTakeProfit() > 0 && OrderStopLoss() > 0)
               {
                  double reward = (OrderOpenPrice() - OrderTakeProfit()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
                  double risk = (OrderStopLoss() - OrderOpenPrice()) * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE) / MarketInfo(OrderSymbol(), MODE_TICKSIZE);
                  
                  if(risk > 0)
                  {
                     double rrRatio = reward / risk;
                     content += "   R:R Ratio: " + DoubleToString(rrRatio, 2) + ":1\n";
                  }
               }
               
               // Add extra line for readability
               content += "\n";
               
               // Track exposure
               if(OrderType() == OP_BUY)
                  currentExposure += OrderLots();
               else if(OrderType() == OP_SELL)
                  currentExposure -= OrderLots();
            }
         }
      }
      
      if(openPositions == 0)
      {
         content += "No open positions found for MagicNumber " + IntegerToString(InpMagicNumber) + "\n";
      }
      else
      {
         content += "Total Open Positions: " + IntegerToString(openPositions) + "\n";
         content += "Net Exposure: " + DoubleToString(currentExposure, 2) + " lots\n";
      }
      
      content += "\n";
   }
   
   // Complete the dashboard
   content += footer + "\n";
   
   // Print the dashboard to the Experts tab
   Print(content);
   
   // Also display in a message box
   MessageBox(content, "ScalpingVortex Dashboard", MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| Get daily price range                                            |
//+------------------------------------------------------------------+
double GetDailyRange(string symbol)
{
   double highPrice, lowPrice;
   GetDailyHighLow(symbol, highPrice, lowPrice);
   
   return highPrice - lowPrice;
}

//+------------------------------------------------------------------+
//| Get daily price range in points                                  |
//+------------------------------------------------------------------+
double GetDailyRangePoints(string symbol)
{
   return GetDailyRange(symbol) / MarketInfo(symbol, MODE_POINT);
}

//+------------------------------------------------------------------+
//| Get daily high and low prices                                    |
//+------------------------------------------------------------------+
void GetDailyHighLow(string symbol, double &highPrice, double &lowPrice)
{
   // Get daily high and low
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   CopyHigh(symbol, PERIOD_D1, 0, 1, high);
   CopyLow(symbol, PERIOD_D1, 0, 1, low);
   
   highPrice = high[0];
   lowPrice = low[0];
}
