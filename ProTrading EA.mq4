//+------------------------------------------------------------------+
//|                                                ProTrading EA.mq4 |
//|                                                        Capriatto |
//|                              https://capriatto.github.io/scripts |
//+------------------------------------------------------------------+
#property copyright "Capriatto"
#property link      "https://capriatto.github.io/scripts"
#property version   "1.00"
#property strict
#property show_inputs
#include <Functions.mqh>

enum entryOptions
  {
   Buy=0,
   Sell=1,
  };

input string expert_parameters = "==EXPERT PARAMETERS==";
input int magicNumber = 9310;

input string risk_management = "==RISK MANAGEMENT==";
input double maxLossPercentage = 0.01;
extern double lotSize = 0.01;
input int  trailingStopPipNumber = 0;
input bool calculatelotSize = False;
input string trade_parameters = "==TRADE PARAMETERS==";
input entryOptions entryType = Buy;
input double entryPrice = 0.0;
input double slPrice = 0.0;
input double tpPrice = 0.0;

string limitOrStopOrder = ""; // this var says if the entry is limit or stop type.

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--CREATING ENTRY PRICE LINE --- //
   ObjectCreate(0,"OBJ_ENTRY_PRICE",OBJ_HLINE,0,0,entryPrice);
   ObjectSetInteger(0,"OBJ_ENTRY_PRICE",OBJPROP_COLOR, clrBlack);

//--CREATING SL PRICE LINE --- //
   ObjectCreate(0,"OBJ_SL_PRICE",OBJ_HLINE,0,0,slPrice);
   ObjectSetInteger(0,"OBJ_SL_PRICE",OBJPROP_COLOR, clrRed);

//--CREATING TP PRICE LINE --- //
   ObjectCreate(0,"OBJ_TP_PRICE",OBJ_HLINE,0,0,tpPrice);
   ObjectSetInteger(0,"OBJ_TP_PRICE",OBJPROP_COLOR, clrLimeGreen);
//---
   double currentPrice = getCurrentPrice(entryType);
   limitOrStopOrder = limitOrStopOrder(currentPrice,entryPrice,entryType);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"OBJ_ENTRY_PRICE"); //--REMOVING ENTRY PRICE LINE --- //
   ObjectDelete(0,"OBJ_SL_PRICE");  //--REMOVING SL PRICE LINE --- //
   ObjectDelete(0,"OBJ_TP_PRICE"); //--REMOVING TP PRICE LINE --- //
//---}
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//---
   if(checkIfTradeAlreadyOpened(magicNumber) == false)
     {
      if(limitOrStopOrder=="Buy Limit")
         openBuyLimit();
      else
         if(limitOrStopOrder == "Sell Limit")
            openSellLimit();
         else
            if(limitOrStopOrder == "Buy Stop")
               openBuyStop();
            else
               if(limitOrStopOrder == "Sell Stop")
                  openSellStop();
     }

   Comment("Waiting for: " + string(limitOrStopOrder)  +"\nAt value : " +  string(entryPrice) + " \nSL: " + string(slPrice)+ "\nTP: " + string(tpPrice));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openBuyLimit()
  {
   int buyTrade = -1;

   if(Close[0] < entryPrice // Price closes below the entry signal
      && Open[0] > entryPrice // Price opens above the entry signal
      && entryType == 0  // Entry Type is Buy
      && limitOrStopOrder == "Buy Limit")  // Signal type : Buy Limit
     {
      if(calculatelotSize)
        {
         double lots = OptimalLotSize(maxLossPercentage,entryPrice,slPrice);
         buyTrade = OrderSend(NULL,OP_BUY,lots,Ask,10,slPrice,tpPrice,"ProTrading EA buy limit trade",magicNumber,0,clrGreen);

         if(buyTrade > 0) // order sent succesfully
            return true;
         else
            Alert("Buy Order failed because of " + string(GetLastError()));

        }
      else   // not to calculate the proper LotSize
        {
         Print("Buying without optimal lotSize");
         lotSize =normalizeLotSize(lotSize);
         buyTrade = OrderSend(NULL,OP_BUY,lotSize,Ask,10,slPrice,tpPrice,"ProTrading EA buy limit trade",magicNumber,0,clrGreen);

         if(buyTrade > 0) // order sent succesfully
            return true;
         else
            Alert("Buy Order failed because of " + string(GetLastError()));

        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openSellLimit()
  {
   int sellTrade = -1;

   if(Close[0] > entryPrice  //Price closes above the entry signal
      && Open[0] < entryPrice // Price opens below the entry signal
      && entryType == 1 // Entry Type is Sell
      && limitOrStopOrder == "Sell Limit") // Signal type : Sell Limit
     {
      if(calculatelotSize)
        {
         double lots = OptimalLotSize(maxLossPercentage,entryPrice,slPrice);
         sellTrade = OrderSend(NULL,OP_SELL,lots,Bid,15,slPrice,tpPrice,"ProTrading EA sell limit trade",magicNumber,0,clrRed);

         if(sellTrade > 0) // order sent succesfully
            return true;
         else
            Alert("Sell Order failed because of " + string(GetLastError()));

        }
      else // not to calculate the proper LotSize
        {
         Print("Selling without optimal lotSize");
         lotSize =normalizeLotSize(lotSize);
         sellTrade = OrderSend(NULL,OP_SELL,lotSize,Bid,15,slPrice,tpPrice,"ProTrading EA sell limit trade",magicNumber,0,clrRed);

         if(sellTrade > 0)
            return true;
         else
            Alert("Sell Order failed because of " + string(GetLastError()));

        }

     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openBuyStop()
{
int buyTrade = -1;

if(Close[0] > entryPrice // Price closes below the entry signal
   && Open[0] < entryPrice // Price opens above the entry signal
   && entryType == 0  // Entry Type is Buy
   && limitOrStopOrder == "Buy Stop")  // Signal type : Buy Stop
  {
   if(calculatelotSize)
     {
      double lots = OptimalLotSize(maxLossPercentage,entryPrice,slPrice);
      buyTrade = OrderSend(NULL,OP_BUY,lots,Ask,10,slPrice,tpPrice,"ProTrading EA buy stop trade",magicNumber,0,clrGreen);

      if(buyTrade > 0) // order sent succesfully
         return true;
      else
         Alert("Buy Order failed because of " + string(GetLastError()));

     }
   else   // not to calculate the proper LotSize
     {
      Print("Buying without optimal lotSize");
      lotSize =normalizeLotSize(lotSize);
      buyTrade = OrderSend(NULL,OP_BUY,lotSize,Ask,10,slPrice,tpPrice,"ProTrading EA buy stop trade",magicNumber,0,clrGreen);

      if(buyTrade > 0) // order sent succesfully
         return true;
      else
         Alert("Buy Order failed because of " + string(GetLastError()));

     }
  }
return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openSellStop()
  {
   int sellTrade = -1;

   if(Close[0] < entryPrice  //Price closes above the entry signal
      && Open[0] > entryPrice // Price opens below the entry signal
      && entryType == 1 // Entry Type is Sell
      && limitOrStopOrder == "Sell Stop") // Signal type : Sell Stop
     {
      if(calculatelotSize)
        {
         double lots = OptimalLotSize(maxLossPercentage,entryPrice,slPrice);
         sellTrade = OrderSend(NULL,OP_SELL,lots,Bid,15,slPrice,tpPrice,"ProTrading EA sell stop trade",magicNumber,0,clrRed);

         if(sellTrade > 0) // order sent succesfully
            return true;
         else
            Alert("Sell Order failed because of " + string(GetLastError()));

        }
      else // not to calculate the proper LotSize
        {
         Print("Selling without optimal lotSize");
         lotSize =normalizeLotSize(lotSize);
         sellTrade = OrderSend(NULL,OP_SELL,lotSize,Bid,15,slPrice,tpPrice,"ProTrading EA sell stop trade",magicNumber,0,clrRed);

         if(sellTrade > 0)
            return true;
         else
            Alert("Sell Order failed because of " + string(GetLastError()));

        }

     }
   return false;
  }
//+------------------------------------------------------------------+

//void trailingStop(entryType,trailingStopPipNumber){
//   if (trailingStopPipNumber > 0){
//
//          double currentPrice = Ask;
//          int accountLotSize = MarketInfo(NULL, MODE_LOTSIZE);
//          
//          Print(currentPrice);
//          Print(accountLotSize);
//          
//          if((currentPrice - entryPrice)*accountLotSize > trailingStopPipNumber)
//            {
//             Alert("okay");
//            }       
//
//   }
