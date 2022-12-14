//+------------------------------------------------------------------+
//|                                                    Functions.mqh |
//|                                                        Capriatto |
//|                             https://capriatto.github.io/includes |
//+------------------------------------------------------------------+
#property copyright "Capriatto"
#property link      "https://capriatto.github.io/includes"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printAccountDetails()
  {
   double accountBalance = AccountBalance();
   Alert("Your account Balance Is : " + string(accountBalance));
   Alert("Your loss allowed is: " + string(accountBalance*0.02));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getStopLossPrice(bool isLongPosition, double entriePrice, int maxLossInPips)
  {
   double stopLossPrice;

   if(isLongPosition)
     {
      stopLossPrice = entriePrice - maxLossInPips * 0.0001;
     }
   else
     {
      stopLossPrice = entriePrice + maxLossInPips * 0.0001;
     }
   return stopLossPrice;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPipValue()
  {
   if(Digits >= 4)
     {
      return 0.0001;
     }
   else
     {
      return 0.01;
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isLong, int pipsTakeProfit)
  {
   double priceTakeProfit  = 0.0;
   if(isLong)
     {
      priceTakeProfit = Ask + pipsTakeProfit * GetPipValue();
     }
   else
     {
      priceTakeProfit = Bid - pipsTakeProfit * GetPipValue();
     }

   return priceTakeProfit;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isLong, int pipsStopLoss)
  {
   double  priceStopLoss  = 0.0;
   if(isLong)
     {
      priceStopLoss = Ask - pipsStopLoss * GetPipValue();
     }
   else
     {
      priceStopLoss = Bid + pipsStopLoss * GetPipValue();
     }

   return priceStopLoss;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
  {
   if(!IsTradeAllowed())
     {
      Alert("Está deshabilitado el botón de Trading Automático. Por favor revise..");
      return  false;
     }

   if(!IsTradeAllowed(Symbol(), TimeCurrent()))
     {
      Alert("No puede operar en este horario con ese par de divisas.");
      return false;
     }

   return true;
  }
//+------------------------------------------------------------------+

//+-------------------------------------------------------------------------------------+
//| Calculate the optimal LotSize based on the account equity |
//+-------------------------------------------------------------------------------------+
double OptimalLotSize(double maxLossPtg, int maxLossInPips)
  {

   double accountEquity = AccountEquity();
   Print("Account Equity " + string(accountEquity));

   double accountLotSize = MarketInfo(NULL, MODE_LOTSIZE);
   Print("Account LotSize: " + string(accountLotSize));

   double tickValue      = MarketInfo(Symbol(),MODE_TICKVALUE);

   if(Digits <= 3)
     {
      tickValue = tickValue / 100;
     }
   Print(" Tick value is : " + string(tickValue));

   double maxLossDollar= accountEquity * maxLossPtg;
   Print("maxLossDollar : " + string(NormalizeDouble(maxLossDollar,3)));

   double maxLossQuoteCurrency = maxLossDollar / tickValue;
   Print("maxLossQuoteCurrency : " + string(maxLossQuoteCurrency));

   double optimalLotSize = NormalizeDouble(maxLossQuoteCurrency / (maxLossInPips * GetPipValue()) / accountLotSize,3) ;

   return optimalLotSize;
  }
//+------------------------------------------------------------------+

//+--------------------------------------------------------------------------------------+
//|  Calculate the optimal LotSize based on the account equity |
//+--------------------------------------------------------------------------------------+
double OptimalLotSize(double maxLossPtg, double entriePrice, double stopLoss)
  {
   double lots = 0;
   double maxLossInPips = (entriePrice - stopLoss)/ GetPipValue();
   int  CalculatedLossInPips = int(maxLossInPips);
   lots = OptimalLotSize(maxLossPtg, CalculatedLossInPips);
   lots = normalizeLotSize(lots);
   Print("Optimal lotSize= "+ string(lots));
   return lots;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                                             |
//+------------------------------------------------------------------+
double checkIfTradeAlreadyOpened(int magicNB)
  {
   int openOrders = OrdersTotal();

   for(int i=0; i<openOrders; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS)==true)
        {
         if(OrderMagicNumber() == magicNB)
           {
            return true;
           }
        }
     }
   return false;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTicketID(int magicNB)
  {
   int openOrders = OrdersTotal();

   for(int i=0; i<openOrders; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS)==true)
        {
         if(OrderMagicNumber() == magicNB)
           {
            return OrderTicket();
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+

//+---------------------------------------------------------------------------------------------------------------------------+
//| If lotSize setted up by the user is less than allowed then use the minlotSizeAllowed  |
//| if lotSize setted up by the user is max than allowed then use the maxlotSizeAllowed |
//+---------------------------------------------------------------------------------------------------------------------------+
double normalizeLotSize(double lots)
  {

   double minlotSizeAllowed = MarketInfo(Symbol(),MODE_MINLOT);
   double maxlotSizeAllowed = MarketInfo(Symbol(),MODE_MAXLOT);

   Print("minlotSizeAllowed = " + string(minlotSizeAllowed) + ", maxlotSizeAllowed = " + string(maxlotSizeAllowed));

   if(lots < minlotSizeAllowed)
     {
      lots =  minlotSizeAllowed;
     }
   if(lots > maxlotSizeAllowed)
     {
      lots =  maxlotSizeAllowed;
     }
   Print("Normalized lotSize is => " +string(lots));
   return lots;
  }

//+---------------------------------------------------------------------------------------------------------------------------+
//| This method aims to return the entry type i.e. buy limit, buy stop, sell limit, sell stop. |
//+---------------------------------------------------------------------------------------------------------------------------+
string limitOrStopOrder(double currentPrice, double signalPrice, int signalType /*0 buy; 1 sell*/)
  {
   if(signalPrice < currentPrice && signalType == 0)
     {
     Print("Buy Limit");
         return "Buy Limit";
     }
   else
       if(signalPrice > currentPrice && signalType == 0)
        {
        Print("Buy Stop");
      return "Buy Stop";
        }
      else
         if(signalPrice > currentPrice && signalType == 1)
           {
           Print("Sell Limit");
            return "Sell Limit";
           }
         else
            if(signalPrice < currentPrice && signalType == 1)
              {
              Print("Sell Stop");
               return "Sell Stop";
              }
   Print("No se pudo determinar el tipo de Entrada");
   return "Error";
  }

//+------------------------------------------------------------------+

double getCurrentPrice(int BuyOrSell){
   double currentPrice;
   
   if(BuyOrSell == 0) // Buy
      currentPrice = Ask;
   else
      currentPrice = Bid;
      
   return currentPrice;
}