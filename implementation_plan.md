# XAU VWAP Scalper ပြင်ဆင်ရေး အစီအစဉ်

- မူရင်း Pine script ကို workspace ထဲသို့ မူရင်းမပျက်အောင် version အသစ်အဖြစ် ထည့်မည်။
- indicator-only simulation ကို TradingView Strategy Tester သုံးနိုင်သော `strategy()` အဖြစ် ပြောင်းမည်။
- H1/H4 data repaint ဖြစ်နိုင်မှုကို confirmed higher-timeframe values သုံး၍ ပိတ်မည်။
- M1 တစ်မျိုးတည်းကန့်သတ်မှုကို M1/M3/M5 execution timeframe များစမ်းနိုင်အောင် ပြောင်းမည်။
- London/New York session, volatility, VWAP slope, ADX regime နှင့် HTF alignment filters ထည့်မည်။
- FAST/Momentum defaults များကို ပိတ်ပြီး confirmed retest ကို default လုပ်ကာ order-flow gate ကိုတင်းကျပ်မည်။
- Opposing liquidity room, retest freshness, BOS quality, cooldown, daily trade limit နှင့် time-stop controls ထည့်မည်။
- TP/SL simulated orders, slippage/commission-ready settings နှင့် conservative ambiguous-bar handling ထည့်မည်။
- Static checks ဖြင့် syntax-risk, asymmetric buy/sell logic နှင့် ပြောင်းလဲထားသော defaults များကို စစ်မည်။

