 *=================================================
 * 请先执行第7~87行命令，完成分析所需的先行处理
 * 第90行开始对应论文中出现的各个图表
 * 第250行往后是弃用的命令（相当混乱请忽略）
 *=================================================
 
	clear all
	global path F:\MyPaper\data
	
	cd $path\上证A股\stataformat
    use 2015fulldata

  *-筛选数据	
	panels id //查看公司数量
  
    drop if id == .
	bysort id: gen n = _n //按id生成交易日排序号码
	*------------
	*->去除ST股票
		replace Stknme  =  "ST" if strmatch(Stknme,"*ST*")
		gen ST1 = 1 if Stknme == "ST" //标定停牌资料中的ST股票
		bysort id: egen yesST1 = max(ST1) //拓展ST股票标记
		drop if yesST1  == 1 //舍弃停牌资料中的ST股票
	
		replace comname =  "ST" if strmatch(comname,"*ST*")
		gen ST2 = 1 if comname == "ST"
		bysort id: egen yesST2 = max(ST2)
		drop if yesST2 == 1 //舍弃行情序列中的ST股票
	
		*br if _merge == 2  
		drop if _merge == 2 
		*注：终止上市  601299中国北车 601268*ST二重 600832东方明珠 
		//   暂停上市  600656*ST博元 
	panels id //再确认剩余数量
	*------------
	*->去除其他有问题的数据
		qui tab Type //检查是否还有Type != 1 的数据 2为退市 3为暂停上市
		qui tab Timeperd //检查停牌数据为负值的数据
	             //-8888为暂停上市，-9666为复牌日期超过2015年
		* drop if Timeperd < 0   暂时不舍弃这部分数据
		drop if id == 603798 //某条奇怪的记录
	panels id //再确认剩余数量
	*------------
	
  *-调整统一日期格式
	format %tdDD/NN/CCYY date Annctime Suspdate Resmdate 
	
  *-数据初步把握
  
*	order id date in* n
*	br if n > 152 //8月跌势主要从18日开始，19日有短暂反复，然后快速向下
*	br if inclose < 3000
	*注：全年上证综指收盘价低于3000点的为8月25、26两日
 
 
  *-进一步分析
	*->准备好变量
	gen unprice = unrefer_value/unnumber   //生成未解押均价
	format unprice %8.2f                   //保留两位小数
	gen ratio = close/unprice              //生成目标比例
	format ratio %8.2f
	encode Reason, gen(reason)             //编码类别变量
	encode CSRCindustry, gen(csrcindustry) //编码证监会行业分类
	
	# delimit ;
	gen julyhalt = 1 if Suspdate == date("6/7/2015","DMY") 
					   |Suspdate == date("7/7/2015","DMY") 
					   |Suspdate == date("8/7/2015","DMY") 
					   |Suspdate == date("9/7/2015","DMY") ;
	# delimit cr  //生成七月停牌区间标记
	
	replace julyhalt = 0 if julyhalt == . //准备好停牌日标记的虚拟变量
	bysort id: egen yesjulyhalt = max(julyhalt) //拓展标记
	replace yesjulyhalt = 0 if yesjulyhalt == .
		
	# delimit ;
	gen aughalt = 1 if Suspdate == date("18/8/2015","DMY")
			          |Suspdate == date("19/8/2015","DMY")
				      |Suspdate == date("20/8/2015","DMY")
			          |Suspdate == date("21/8/2015","DMY") 
			          |Suspdate == date("24/8/2015","DMY") 
			          |Suspdate == date("25/8/2015","DMY") 
			          |Suspdate == date("26/8/2015","DMY") ;
	# delimit cr  //生成八月停牌区间标记
	
	bysort id: egen yesaughalt = max(aughalt) //拓展标记
	replace yesaughalt = 0 if yesaughalt == .
	
		
	*-图表
		set scheme rbn1mono, permanently //设定图形模板
		tab reason if julyhalt==1, sort //停牌潮停牌原因统计，须自行整合
		*----------------------------------------------
		* 图1 2015年指数走势与停牌情况
		*----------------------------------------------
		# delimit ;
		twoway (histogram Suspdate, frequency yaxis(2))
			(line inclose date if id==600000, yaxis(1)) 
			,
			xtitle("日期")
			ytitle("停牌频数", axis(2))
			xlabel(#12,angle(30)) 
			legend(rows(1)
			       label(1 "停牌频数"))
			saving(basicglance, replace)
			;
		# delimit cr
		
		*----------------------------------------------
		* 图2 股票质押与停牌操纵示意简图
		*----------------------------------------------
		# delimit ;
		twoway function y=(x-10)^2+10
			   ,
			   range(0 20)
			   yline(39, lcolor(red) lpattern(solid))
			   yline(45, lcolor(brown) lpattern(solid))
			   ylabel(39 45)
			   xlabel("")
			   ytitle("股价")
			   xtitle("时间")
			   saving(figure1, replace)
			   ;
		# delimit cr
	
		
		# delimit ;
		twoway function y=(x-10)^2+10
			   ,
			   range(0 20)
			   yline(39, lcolor(red) lpattern(solid))
			   yline(45, lcolor(brown) lpattern(solid))
			   ylabel(39 45)
			   xlabel("")
			   ytitle("股价")
			   xtitle("时间")
			   lpattern(dash)
			   saving(figure2, replace)
			   ;
		# delimit cr
	
	    *----------------------------------------------
		* 表1 停牌开始日期
		*----------------------------------------------
		tab Suspdate, sort //查看停牌情况
		*注：全年停牌集中于7月6、7、8、9四日
		
		*----------------------------------------------
	    * 表2 仓位水平分布
		*----------------------------------------------
		tabstat ratio if julyhalt == 1 & ratio<2, stat(N mean sd p25 p50 p75 min max) f(%4.2f)
	    
		*----------------------------------------------
		* 图3 7月6日-7月9日停牌个股仓位水平分布
		*----------------------------------------------
		# delimit ;
		twoway kdensity ratio if julyhalt == 1 & ratio < 2
				, 
				xtitle("仓位水平")
				ytitle("kdensity")
				xlabel(#3 0.5 0.65 0.75, angle(0))
				xline(0.5,lcolor(red) lpattern(solid))
				xline(0.65,lcolor(red) lpattern(shortdash))
				xline(0.75,lcolor(red) lpattern(longdash))
				saving(7density, replace)
				;
		# delimit cr
		
		*----------------------------------------------
		* 图4 7月8日个股仓位水平分布
		*----------------------------------------------
		# delimit ;
		twoway (kdensity ratio if date == date("8/7/2015","DMY") & ratio < 2, lpattern(dot))
			   (kdensity ratio 
			    if date == date("8/7/2015","DMY")&julyhalt==0 & ratio < 2, lpattern(dash))
			   (kdensity ratio 
			    if date == date("8/7/2015","DMY")&julyhalt==1 & ratio < 2, lpattern(solid))
				,
			    xtitle("仓位水平")
				ytitle("kdensity")
				xlabel(#3 0.5 0.65 0.75,angle(0))
				xline(0.5,lcolor(red) lpattern(solid))
				xline(0.65,lcolor(red) lpattern(longdash))
				xline(0.75,lcolor(red) lpattern(shortdash))
				legend(label(1 "七月八日全体") 
				       label(2 "七月八日未停牌") 
					   label(3 "七月八日停牌")
					   rows(1))
				saving(7density+, replace)
				;
		# delimit cr
	
		*----------------------------------------------
		* 表3 月度均值差异检验
		*----------------------------------------------
		gen month = .
		forvalues i = 1/31{
			forvalues j = 1/12{
			replace month = `j' if date == date(`"`i'/`j'/2015"',"DMY")
			}
		}
		//生成月份标记
		set more off
	
		bysort id month:egen mratio = mean(ratio) //生成每股每月均值
	
		forvalues i = 1/12{
			logout, save(ttest`i') word replace:ttable2 mratio if month==`i', by(yesjulyhalt)
			}
		
		set more off
	
	   	*----------------------------------------------
		* 表4 七、八月停牌个股数量对比
		*----------------------------------------------
  		preserve
			keep if n == 1
			tab yesjulyhalt yesaughalt
		restore
  
		*----------------------------------------------
		* 表5 停牌潮复牌时间统计
		*----------------------------------------------
		tab Resmdate if julyhalt == 1, sort
		

  
  
  *-图形调用输出
	graph use basicglance
	graph export basicglance.png, width(2622) height(1908) replace
	graph use figure1
	graph export figure1.png, width(2622) height(1908) replace	
	graph use figure2
	graph export figure2.png, width(2622) height(1908) replace
	graph use 7density
	graph export 7density.png, width(2622) height(1908) replace
	graph use 7density+
	graph export 7density+.png, width(2622) height(1908) replace


	
	
	
	
	
	
	
	
*------------------------------------------------------------------------		
*   备用命令
*------------------------------------------------------------------------	
	dropvars Yes
	gen Yes = ( date == date("8/7/2015","DMY")&yesjulyhalt==1 )
    ttable2 ratio if date==date("13/7/2015","DMY"), by(yesjulyhalt)
	
    tabstat ratio if date==date("13/7/2015","DMY")&yesjulyhalt==1,  ///
	     s(p5 p25 p50 p75 p95 sd mean) f(%3.2f) c(s)
    tabstat ratio if date==date("13/7/2015","DMY")&yesjulyhalt==0,  ///
	     s(p5 p25 p50 p75 p95 sd mean) f(%3.2f) c(s)
*------------------------------------------------------------------------		
	
	*-->>目标比率:七月停牌
		bysort id: gen ratio1 = close[_n-1]/unprice[_n-1] ///
		if julyhalt == 1
		format ratio1 %8.2f //保留两位小数
	*-->>目标比率:七月、八月连续停牌
		bysort id: gen ratio2 = close[_n-1]/unprice[_n-1] if ///
		yesjulyhalt == 1 & aughalt == 1
		format ratio2 %8.2f
	*-->>目标比率:七月没停八月停了
		bysort id: gen ratio3 = close[_n-1]/unprice[_n-1] if ///
		yesjulyhalt != 1 & aughalt == 1 
		format ratio3 %8.2f
	
	*-->>有质押余额的股票数目
		panels id if ratio1 != . //七月停牌而无质押
		panels id if ratio2 != . //八月停牌（七月也停了）而无质押
		panels id if ratio3 != . //八月停牌（七月没停）而无质押
	
	
		
  *-集中输出
    cd F:\MyPaper\First draft\output
    logout, save(reason) word replace:tab reason if julyhalt == 1 
	logout, save(distri) word replace:tabstat ratio if julyhalt == 1 ///
	, stat(N mean sd min max p25 p50 p75) f(%4.2f)
	//输出七月停牌原因统计
	
	
		 list id date unnumber yesaughalt if yesjulyhalt==1 ///
	     & (date == date("6/7/2015","DMY")|date == date("26/8/2015","DMY")) ///
		 , sepby(id)
	//七月停牌而且有未解押余额的股票，余额在这段时间内只有增加没有减少
   
   set more off
	
	
	
  *-检验  不管没有股票质押余额的，因为没有余额的话平仓风险就不可能和停不停牌的决策有关
	logout, save(t6) word replace:ttable2 ratio if date==date("6/7/2015","DMY"), by(julyhalt)
	logout, save(t7) word replace:ttable2 ratio if date==date("7/7/2015","DMY"), by(julyhalt)
	logout, save(t8) word replace:ttable2 ratio if date==date("8/7/2015","DMY"), by(julyhalt)
	logout, save(t9) word replace:ttable2 ratio if date==date("9/7/2015","DMY"), by(julyhalt)
	
	forvalues i = 1/31{
		dis _n(2) `"`i'/7/2015"'
		capture noisily ttable2 ratio if date == date(`"`i'/7/2015"',"DMY"), by(yesjulyhalt)
		}
		
	set more off
	
	forvalues i = 1/31{
		dis _n(2) `"`i'/8/2015"'
		capture noisily ttable2 ratio if date == date(`"`i'/8/2015"',"DMY"), by(yesjulyhalt)
		}
	
	set more off
 
 
 
 
 
	# delimit ;
	global octarea Suspdate == date("8/10/2015","DMY")
			      |Suspdate == date("9/10/2015","DMY")
				  |Suspdate == date("12/10/2015","DMY")
			      |Suspdate == date("13/10/2015","DMY") 
			      |Suspdate == date("14/10/2015","DMY") 
			      |Suspdate == date("15/10/2015","DMY") 
			      |Suspdate == date("16/10/2015","DMY")
				  |Suspdate == date("19/10/2015","DMY")
				  |Suspdate == date("20/10/2015","DMY")
				  |Suspdate == date("21/10/2015","DMY")
				  |Suspdate == date("22/10/2015","DMY")
				  |Suspdate == date("23/10/2015","DMY")
				  |Suspdate == date("26/10/2015","DMY")
				  |Suspdate == date("27/10/2015","DMY")
				  |Suspdate == date("28/10/2015","DMY")
				  |Suspdate == date("29/10/2015","DMY")
				  |Suspdate == date("30/10/2015","DMY")
				  ;
	# delimit cr 

	gen octhalt = 1 if $octarea
	
	tab reason if octhalt == 1, sort
	
	
	
	# delimit ;
		twoway (kdensity ratio if date == date("6/7/2015","DMY"))
			   (kdensity ratio 
			    if date == date("6/7/2015","DMY")&yesjulyhalt==0 , color(brown))
		       (kdensity ratio1, color(red))
			   (kdensity ratio2, color(blue))
			   (kdensity ratio3, color(green))
				,
			    title("目标比率")
				legend(label(1 "七月全体") 
				       label(2 "七月不停牌") 
					   label(3 "七月停牌") 
					   label(4 "七月停牌八月也停牌") 
					   label(5 "七月没停八月停牌"))
				saving(fulldensity, replace)
				;
		# delimit cr
		
		
		
			
  *-回归

	logit julyhalt ratio if date == date("6/7/2015","DMY")
	logit julyhalt ratio if date == date("7/7/2015","DMY")
	logit julyhalt ratio if date == date("8/7/2015","DMY")
	logit julyhalt ratio if date == date("9/7/2015","DMY")
	logit julyhalt ratio if date == date("10/7/2015","DMY")
	logit julyhalt ratio if date == date("11/7/2015","DMY")
	
	
	reg Timeperd ratio if date == date("6/7/2015","DMY")
	reg Timeperd ratio if date == date("7/7/2015","DMY")
	reg Timeperd ratio if date == date("8/7/2015","DMY")
	reg Timeperd ratio if date == date("9/7/2015","DMY")
