//+------------------------------------------------------------------+
//|                                                      支撑位交易系统.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

//--- 输入参数
input double TrailingStop =600;
input double maxStopPoint =500;
input double maxOpen = 0.01;
//--- 固定参数
double lots = 0.01;

//--- EA标识
string comment = "Ea开单";
int magicNum = 82934233;

//--- 全局变量
datetime lasttime;
double xR3,xR2,xR1,xP,xS1,xS2,xS3;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {


  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   GetPivotPoint();
   checkAccountInfo();
   CTP();
   trading();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkAccountInfo()
  {
   if(OrdersTotal() >= maxOpen)
      return ;
   if(Time[0] == lasttime)
      return; //每时间周期检查一次  时间控制
   lasttime = Time[0];

   if(TimeDayOfWeek(CurTime()) == 1)
     {
      if(TimeHour(CurTime()) < 3)
         return; //周一早8点前不做  时间控制
     }
   if(TimeDayOfWeek(CurTime()) == 5)
     {
      if(TimeHour(CurTime()) > 19)
         return; //周五晚11点后不做
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void trading()   //去下单交易
  {
   double middlePrice1= (xR1 + xR2)/2;
   if(Ask > xR1  && Ask < middlePrice1)//---当前价格小于R2和R1的中间价，大于R1,开多单，止损位为R1+R2的中间价，止盈位为R3
     {
      CloseSell();
      double closePrice1= (xR1 + xP)/2;
      double closePrice2= Ask - closePrice1 >= maxStopPoint*Point ? Ask - maxStopPoint*Point : closePrice1;
      int orderId =  OrderSend(Symbol(),OP_BUY,lots,Ask,3,closePrice2,xR3,comment,magicNum,0,clrNONE);
      Print("多单编号：",orderId);
     }

   double middlePrice2 = (xS1 + xS2)/2;
   if(Bid < xS1  && Bid > middlePrice2)//---当前价格大于S1和S2的中间价，小于S1,开空单，止损位为S1+S2的中间价,止盈位为S3
     {
      CloseBuy();
      double closePrice1= (xS1 + xP)/2;
      double closePrice2= closePrice1 - Bid >= maxStopPoint*Point ? Bid + maxStopPoint*Point : closePrice1;
      int orderId =  OrderSend(Symbol(),OP_SELL,lots,Bid,3,closePrice2,xS3,comment,magicNum,0,clrNONE);
      Print("空单编号：",orderId);
     }
  }

//+------------------------------------------------------------------+
//|                                止盈方式                                  |
//+------------------------------------------------------------------+
void CTP()   //跟踪止赢
  {
   bool bs = false;
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         break;
      if(OrderType() == OP_BUY && OrderSymbol() == Symbol())
        {
         if((Bid - OrderOpenPrice()) > (TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT)))     //开仓价格 当前止损和当前价格比较判断是否要修改跟踪止赢设置
           {
            if(OrderStopLoss() < Bid - TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT))
              {
               bs = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT), OrderTakeProfit(),0, Green);
              }
           }
        }
      else
         if(OrderType() == OP_SELL && OrderSymbol() == Symbol())
           {
            if((OrderOpenPrice() - Ask) > (TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT)))   //开仓价格 当前止损和当前价格比较判断是否要修改跟踪止赢设置

              {
               if((OrderStopLoss()) > (Ask + TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT)))
                 {
                  bs = OrderModify(OrderTicket(), OrderOpenPrice(),
                                   Ask + TrailingStop * MarketInfo(OrderSymbol(), MODE_POINT), OrderTakeProfit(),0, Tan);
                 }
              }
           }
     }
  }
//+------------------------------------------------------------------+

//平仓持有的买单
void CloseBuy()
  {
   if(OrdersTotal() > 0)
     {
      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
            break;
         if(OrderType()==OP_BUY && OrderSymbol() == Symbol())
           {
            OrderClose(OrderTicket(),OrderLots(),Bid,3,White);
            Sleep(5000);
           }
        }
     }
  }
//平仓持有的卖单
void CloseSell()
  {
   if(OrdersTotal() > 0)
     {
      for(int i=OrdersTotal()-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
            break;
         if(OrderType()==OP_SELL && OrderSymbol() == Symbol())
           {
            OrderClose(OrderTicket(),OrderLots(),Ask,3,White);
            Sleep(5000);
           }
        }
     }
  }



void GetPivotPoint() /*枢轴点*/
  {
   double xH=iHigh(Symbol(),PERIOD_D1,iHighest(Symbol(),PERIOD_D1,MODE_HIGH,1,1));
   double xL=iLow(Symbol(),PERIOD_D1,iLowest(Symbol(),PERIOD_D1,MODE_LOW,1,1));
   double xC=iClose(Symbol(),PERIOD_D1,1);
   PrintFormat("昨日最高价：{%f},昨日最低价：{%f},昨日收盘价：{%f}",xH,xL,xC);
   xP=(xH+xL+xC)/3;
   xR1=2*xP-xL;
   xS1=2*xP-xH;
   xR2=xP+(xR1-xS1);
   xS2=xP-(xR1-xS1);
   xR3=xH+2*(xP-xL);
   xS3=xL-2*(xH-xP);
   PrintFormat("P价：{%f},R1价：{%f},S1价：{%f},R2价：{%f},S2价：{%f},R3价：{%f}S3价：{%f},",xP,xR1,xS1,xR2,xS2,xR3,xS3);
  }
//+------------------------------------------------------------------+
