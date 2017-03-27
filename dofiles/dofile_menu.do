
*     =========================================
*                   本科毕业论文
*
*               股票质押导向的停牌操纵
*                         ——以2015年股灾为例
*     =========================================
*
*                      **濠
*
*          中山大学 岭南（大学）学院 金融系 
*               12级本科生 12327039
*        E-mail: *******53@mail2.sysu.edu.cn
*                
*
*     ------------------------------------------
    
*   注：停复牌数据来自CSMAR数据库、其余数据来自Wind
	
	clear all
	
  *全局路径设定
	global path F:\MyPaper
	
  *数据处理 （原始文件与dta的对应关系可参见以下两个dofile） 
	cd $path\dofiles
    doedit hedgeimport 
	doedit dataprocess

  *分析
    cd $path\dofiles
    doedit analyse

	
*	注：stataformat文件夹中	
*	2015fulldata 即已完成数据合并，最终使用的数据文件
*
*	2015indexpanel       为指数行情数据
*	2015panel            为个股行情数据
*	2015indexpanel       为指数行情数据
*	halts                为停复牌数据
*	industry             为行业信息数据 
*	paneepledgefrom2012  为股票质押数据（此数据的具体选择请参见论文）
