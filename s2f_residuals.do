*(c)2019 @Phraudsta *
*BTC: 18sCrV4EZ3FzfQ3H7iamx9HKzKZoC1AMtz *
*written with stata 14*
*get daily data from coinmetrics*
import delimited https://coinmetrics.io/newdata/btc.csv, clear
*fix date formats and tsset the data*
gen d = date(date, "YMD")
drop date
rename d date
format %tdMon_dd,_CCYY date
tsset date
*we will extend the range a bit
set obs 10000
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
gen sfmiss = (tsupply-1e6)/flow
gen sf = (tsupply)/flow
gen lnsf = ln(sf)
gen lnsf_miss=ln(sfmiss)
gen lnprice = ln(priceusd)
tssmooth ma smooth_lnsf=lnsf, window(365 1 0)
reg lnprice smooth_lnsf
predict lnprice_hat, xb
gen price_hat = exp(lnprice_hat)
predict resid, res
summ resid, detail
gen uci = exp(lnprice_hat+r(p95))
gen lci = exp(lnprice_hat+r(p5))
label variable uci "95th Quantile of Residuals"
label variable lci "5th Quantile of Residuals"
label variable price_hat "Stock-to-Flow estimation"
tsline uci lci priceusd price_hat if date<d(20jan2022) & date>d(1jan2011) , ylabel(1 10 100 1000  10000 100000 1000000, grid labsize(vsmall) angle(horizontal)) yscale(log) ymtick(1 2 3 4 5 6 7 8 9 10 10 (10) 100 100 (100) 1000 1000 (1000) 10000 10000 (10000) 100000 100000 (100000) 1000000, labsize(tiny) angle(horizontal)  grid) xlabel(#10, grid angle(45) labsize(tiny)) xscale(log) xmtick(##5, grid) title(Bitcoin Stock-to-Flow) xtitle(, size(zero) color(none)) subtitle(Residuals Bands) caption(@phraudsta)
