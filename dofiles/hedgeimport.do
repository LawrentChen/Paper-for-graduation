
  *-导入股票质押数据,添加日期
  
	clear all
	global path F:\MyPaper\data
	cd $path\上证A股\pledge
	
	forvalues j = 1/12{
	 forvalues i = 1/31{
	 clear all
	 cap import excel using `j'_`i'.xlsx, sheet(Wind资讯)
	 gen date = date(`"`i'/`j'/2015"',"DMY")
     save `j'_`i'.dta, replace
	 }
	}
	
	clear all 
	use 1_4
	forvalues i = 1/31{
	 forvalues j = 1/12 {
	 cap append using `j'_`i'
	 }
	}
	
	set more off
	
	
   *-整理变量
	drop if C == "全部交易" 
	drop if C == "交易次数"
	drop if A == ""
	drop if A == "数据来源：Wind资讯" //去除原有表头和版权信息
	
	destring C D E F G H I J K, replace
	rename (C D E F G H I J K) (alltrade allnumber allrefer_value ///
	untrade unnumber unrefer_value retrade renumber rerefer_value)
	
	gen company_id = substr(A,1,6)
	destring company_id, replace
	drop A B //抽出证券代码六位，去除公司名
	
	label var date           "日期"
	label var company_id     "证券代码"
	
	order company_id date
	sort company_id date
    
	format %tdDD/NN/CCYY date
	
	duplicates drop company_id date, force //去除重复的一月四日数据
	tsset company_id date 
	
  *-存为dta
	save panelpledgefrom2012, replace
	cd $path\上证A股\stataformat
	save panelpledgefrom2012, replace
	