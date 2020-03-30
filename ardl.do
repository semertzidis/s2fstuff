*(c)2019-2020 @btconometrics *
*BTC: 18sCrV4EZ3FzfQ3H7iamx9HKzKZoC1AMtz *
*written with stata 14*
*in support of https://medium.com/@btconometrics/stock-to-flow-influences-on-bitcoin-price-8a52e475c7a1*

*get daily data from coinmetrics*
import delimited https://coinmetrics.io/newdata/btc.csv, clear

*fix date formats and tsset the data*
gen d = date(date, "YMD")
drop date
rename d date
format %td date
tsset date

replace date = 17900 + _n-1 if date == .
replace blkcnt = 6*24 if blkcnt == .

gen sum_blocks = sum(blkcnt)
gen hp_blocks = mod(sum_blocks, 210001)

gen hindicator = 0
replace hindicator = 1 if hp_blocks <200 & hp_blocks[_n-1]>209000

gen hperiod =sum(hindicator) -1

gen reward = 50/(2^hperiod)
 
gen daily_reward = blkcnt * reward
gen tsupply = sum(daily_reward)
sort date
gen flow = d.tsupply*365.25
gen s2f = tsupply/flow

gen lnprice = ln(priceusd)
gen lns2f = ln(s2f)

reg lnprice lns2f
estat bgod
predict res, res
graph matrix res l(1/10).res

prais lnprice lns2f, corc rhotype(tscorr)

dfgls lns2f if hperiod == 0
dfgls lns2f if hperiod == 1
dfgls lns2f if hperiod  == 2

zandrews lns2f

ardl lnprice lns2f, ec

*OK lets collapse to difficulty adjustment periods*
gen ke = 1
gen be = mod(sum_blocks,2016)
replace ke = 0 if be[_n-1]<be[_n]
gen ksum = sum(ke)

collapse (mean) date priceusd tsupply flow hperiod reward s2f, by(ksum)

gen diffperiod = _n
tsset diffperiod

gen lnprice = ln(priceusd)
gen lns2f = ln(s2f)

*check for stationarity - we can see lns2f is stationary and lnprice is not
dfgls lns2f if hperiod== 0
dfgls lns2f if hperiod== 1
dfgls lns2f if hperiod== 2

zandrews lns2f
dfgls lnprice if hperiod== 0
dfgls lnprice if hperiod== 1
dfgls lnprice if hperiod== 2

zandrews lnprice

*cant mix integration orders except in ARDL. 
ardl lnprice lns2f, lags(. .)  ec
estat ectest
*can reject no cointegration at the 5% level
format %tdMon_CCYY date
predict dlnprice, xb
predict ec, ec
tsline dlnprice d.lnprice title(Log Price Daily Difference)
tsline  ec, yline(0) title(Error correction)
qui summ lnprice
local m = r(min)
gen hat_lnprice = sum(dlnprice)+`m'
tsline hat_lnprice lnprice
twoway  (lfitci hat_lnprice lnprice, stdf) (scatter hat_lnprice lnprice, sort), title(Model v Actual) ytitle(Model lnprice) xtitle(lnprice)
line exphat_lnprice priceusd date if date>d(1Jan2011) & date<d(30mar2020), yscale(log) ylabel(1 10 100 1000 10000, angle(horizontal) labsize(small) grid glwidth(thin)) ymtick(2 3 4 5 6 7 8 9 20 30 40 50 60 70 80 90 200 300 400 500 600 700 800 900 2000 3000 4000 5000 6000 7000 8000 9000 20000, grid glwidth(vvthin)) title(ARDL model) xlabel(#10, grid angle(45) labsize(small)) xtitle(, size(zero))
