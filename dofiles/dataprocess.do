 
  *-导入数据，合并前先行处理
  
	*-----------
	*停复牌数据
	*-----------
	clear all
	global path F:\MyPaper\data
	cd $path\上证A股\2015halts
	
	import excel using TSR_Stkstat.xlsx, firstrow sheet(TSR_Stkstat)
	rename Stkcd company_id //统一接头变量名
	gen date = Suspdate
	format %tdnn/dd/CCYY date
	sort company_id date
	
	*注：直接进行面板声明会发现有重复数据，可以用以下两条命令去除问题数据
	*    duplicates report id date
	*    duplicates drop id date, force
	
	*    bysort id: count if date[_n]==date[_n-1] 
	     //具体查找重复时间的数据，发现601155在12月4日有两次停牌记录
	
	replace Susptime = clock("31dec1899 09:55:00","DMYhms") in 1346
	replace Timeperd = 4 in 1346
	drop in 1345 if company_id == 601155 //修正当日相隔仅两分钟的连续停牌记录
	
	tsset company_id date

	cd $path\上证A股\stataformat
	save halts, replace
	
	*----------------
	*2015个股行情序列
	*----------------
	clear all
	cd $path\上证A股
	
	import excel using 上证A股2015行情序列.xlsx, firstrow sheet(A股2015行情序列)
	drop if company_id == ""
	drop if company_id == "数据来源：Wind资讯" //去除最后多余的两行
	gen id = substr(company_id,1,6) //提取证券代码前六位
	drop company_id 
	destring id, replace
	rename id company_id //替换原有的带.SH后缀的代码
	sort company_id date 
	tsset company_id date
	
	cd $path\上证A股\stataformat
	save 2015panel, replace
	
	*----------------
	*2015指数行情序列
	*----------------
	clear all
	cd $path\上证A股
	
	import excel using 上证综指2015行情序列1.xlsx, firstrow sheet(上证综指2015行情序列)
	sort date
	tsset date
	
	cd $path\上证A股\stataformat
	save 2015indexpanel, replace
	
	*---------
	*行业信息
	*---------
	clear all 
	cd $path\上证A股
	
	import excel using 上证A股上市股票一览1.xlsx, firstrow sheet(Wind资讯)
	drop if company_id == ""
	drop if company_id == "数据来源：Wind资讯" //去除最后多余的两行
	gen id = substr(company_id,1,6) //提取证券代码前六位
	drop company_id
	destring id, replace
	rename id company_id
	sort company_id

	cd $path\上证A股\stataformat
	save industry, replace
	*----------------------------
	
  *-合并数据
  
	clear all
	cd $path\上证A股\stataformat
	
	use 2015panel.dta //以个股面板为基础
	merge m:m company_id date using halts.dta //合并停牌面板
	merge m:m company_id date using panelpledgefrom2012.dta, gen(_merge2) //合并股票质押数据
	merge m:1 date using 2015indexpanel.dta, gen(_merge3) //合并上证综指面板
	merge m:1 company_id using industry.dta, gen(_merge4) //合并行业分类
	
	
  *-处理标签
  
	label var 	company_id            "证券代码"
	label var 	date                  "日期"
	label var   comname               "公司名称"
	label var 	opening_price         "开盘价"
	label var 	closing_price         "收盘价"
	label var 	mean_price            "均价"
	label var 	Asharecirvalue        "A股流通市值（元）"
	label var	market_cap 			  "总市值（元）"
	label var 	Asharecirequity       "A股流通股本（股）"
	label var 	total_equity 	  	  "总股本（股）"
	label var   Stknme                "停牌公司名称"
	label var 	Annctime			  "停牌公告日期"
	label var   Type                  "停牌类型"
	label var 	Suspdate			  "停牌日期"
	label var 	Susptime			  "停牌时刻"
	label var 	Resmdate			  "复牌日期"
	label var 	Resmtime			  "复牌时刻"
	label var 	Timeperd 			  "停牌交易时长"
	label var 	Reason				  "停牌原因"
	label var   inopening_price       "上证综指开盘价"
	label var   inclosing_price       "上证综指收盘价"
	label var   inhigh                "上证综指最高价"
	label var   inlow                 "上证综指最低价"
    label var   alltrade              "全部交易次数"
	label var   allnumber             "全部质押股数（万股）"
	label var   allrefer_value        "全部参考市值（万元）"
	label var   untrade               "未解押交易次数"
	label var   unnumber              "未解押质押股数（万股）"
	label var   unrefer_value         "未解押参考市值（万元）"
	label var   retrade               "已解押交易次数"
	label var   renumber              "已解押质押股数（万股）"
	label var   rerefer_value         "已解押参考市值（万元）"
	label var   CSRCindustry          "CSRC行业"
	label var   Windindustry          "Wind行业"
	
  *-简化变量名
    # delimit ;
    rename (company_id opening_price closing_price mean_price Asharecirvalue 
	        market_cap Asharecirequity total_equity inopening_price inclosing_price) 
	       (id open close mean Acapital capital Aequity equity inopen inclose) ;
	# delimit cr
	
	
  *-优化变量排序
    order id date
	sort id date
	tsset id date
	
  *-存档
    save 2015fulldata, replace
