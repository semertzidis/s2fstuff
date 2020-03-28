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
