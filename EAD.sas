

/*****************************************************************
Exploratory Data Analysis - EDA

EDA includes basic data analysis and statistic visualization to 
explore the data size, integrity, structure, distribution, and 
relationships/associations between continuous and categorical 
variables.  
*****************************************************************/

/*****************************************************************
Basic Data Analysis
*****************************************************************/

/*Data set size and table structure*/
ods select attributes variables;
proc contents data=project.diamonds_raw;
run;

/*Stat summary - 5 number summary*/
ods noproctitle;
title '5 Number Summary';
proc means data=project.diamonds_raw min max median q1 q3;
var carat depth price table x y z;
run;
ods graphics off;

/*Check duplicates - exporting clean one to diamonds_uniq and 
duplication to diamonds_dup(note that one duplicate was removed in
each duplicate record)*/
proc sort data=project.diamonds_raw nodupkey 
	out=project.diamonds_uniq 
	dupout=project.diamonds_dup;
 by carat cut color clarity depth table price x y z;
run; 

/*Get unique records from diamonds_dup dataset, which will be 
joined back to diamonds_uniq (clean one)*/
proc sql;
	create table project.diamonds_uni_dup as 
    select carat, cut, color, clarity, depth, table, price, x, y, z, 
    count(*) as numRows
    from project.diamonds_dup
    group by carat, cut, color, clarity, depth, table, price, x, y, z
   ;
quit;

/*Get the records that are duplicated from diamonds_uniq*/
proc sql;
	create table project.diamonds_single_dup as
	select a.rec_id, a.carat, a.cut, a.color, a.clarity, a.depth, a.table, 
           a.price, a.x, a.y, a.z 
	from project.diamonds_uniq as a inner join project.diamonds_uni_dup as b
	on a.carat=b.carat and a.cut=b.cut and a.color=b.color and 
       a.clarity=b.clarity and a.depth=b.depth and a.table=b.table and
       a.price=b.price and a.x=b.x and a.y=b.y and a.z=b.z; 
quit;

/*Get the total duplicates - diamonds_dup + diamonds_single_dup*/
data project.diamonds_total_dup;
	set project.diamonds_single_dup project.diamonds_dup;
run;


/*Check the validity of x, y or z, which involve in the zero.*/ 
proc sql;
	create table project.zero as
	select * from project.diamonds_raw
	where x=0 or y=0 or z=0;
quit;

/*Remove invalid records and the total records of diamonds_clean is 53775*/
data project.diamonds_clean;
	set project.diamonds_uniq;
	if x=0 or y=0 or z=0 then delete;
run;

/**************************************************************** 
Statistical data visulization
*****************************************************************/

/*Comparison of the 5 number summary before and after cleaning. */
ods noproctitle;
title '5 number summary before and after cleaning';
proc means data=project.diamonds_raw (drop=rec_id) min max median q1 q3;
run;
title;
proc means data=project.diamonds_clean (drop=rec_id) min max median q1 q3;
run;
ods graphics off;

/*Explore the distribution of numeric variables*/
ods graphics on;
ods noproctitle;
ods select Histogram ParameterEstimates GoodnessFit FitQuantiles;
title;
footnote;
proc univariate data=project.diamonds_clean (drop=rec_id);
  histogram carat depth price table x y z/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ods graphics off;

/*Q-Q plots*/
Ods graphics on;
title 'Q-Q plot';
proc univariate data=project.diamonds_clean noprint;
	qqplot price /normal(mu=3931.2 sigma=3985.9) 
         odstitle = 'Normal Quartile-Quartile Plot for Diamonds (price)';;

	qqplot carat /normal(mu=0.7975 sigma=0.4732) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (carat)';

	qqplot depth /normal(mu=61.748 sigma=1.4296) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (depth)';

	qqplot table /normal(mu=57.457 sigma=2.2333) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (table)';

	qqplot x /normal(mu=5.7316 sigma=1.1186) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (x)';

	qqplot y /normal(mu=5.7349 sigma=1.1395) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (y)';

	qqplot z /normal(mu=3.5399 sigma=0.7020) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (z)';
run;

/*Scatter plots*/
ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=carat y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=dodgerblue )
						;
title color=white 'Scatter Plot of Price by Carat';
footnote color=white 'Remark: data has carat > 3';

xaxis label='carat'
	  labelattrs=(color=dimgray weight=bold)
	  values=(0 1 2 3)
	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=depth y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=Green )
						;
title color=white 'Scatter Plot of Price by depth';
footnote;

xaxis label='depth'
	  labelattrs=(color=dimgray weight=bold)
	  values=(40 60 80)  
 	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=table y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=wheat )
						;
title color=white 'Scatter Plot of Price by Table';
footnote color=white 'Remark: data has table > 80';

xaxis label='table'
	  labelattrs=(color=dimgray weight=bold)
	  values=(40 60 80)
	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=x y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=bib )
						;
title color=white 'Scatter Plot of Price by x';
footnote color=white 'Remark: data has x>9';

xaxis label='x'
	  labelattrs=(color=dimgray weight=bold)
	  values=(3 4 5 6 7 8 9)
valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=y y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=yellow )
						;
title color=white 'Scatter Plot of Price by y';
footnote color=white 'Remark: data has y>9';

xaxis label='y'
	  labelattrs=(color=dimgray weight=bold)
	  values=(3 4 5 6 7 8 9)
	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

ods graphics on;
proc sgplot data=project.diamonds_clean;
  scatter x=z y=price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=bio )
						;
title color=white 'Scatter Plot of Price by z';
footnote color=white 'Remark: data has z>6';

xaxis label='z'
	  labelattrs=(color=dimgray weight=bold)
	  values=(2 4 6)
	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price DOLLAR.;
run;
ods graphics off;

/**************************************************************** 
Correlation between continuous variables
*****************************************************************/

ods graphics off;
ods select PearsonCorr;
title 'Pearson Correlation between Continuous Variables';
proc corr data=project.diamonds_clean;
	var price carat depth table x y z;
run;

/*This is very time consuming in EG. Therefore, it will be run on SAS 9.4*/
/*matrix of correlation between continuous variables*/
title 'Matrix of correlation between continuous variables';
proc sgscatter data=project.diamonds_clean; 
matrix price carat depth table x y z/diagonal=(histogram kernel);
run;
ods graphics off;

/**************************************************************** 
Associations between categorical variables
*****************************************************************/

/*Chi square test for 3 Cs*/
ods graphics off;
title 'Chi square test for 3Cs';
proc freq data=project.diamonds_clean;
	table clarity*(cut color)/chisq;
	table cut*color /chisq;
run; 
ods graphics off;

/*Box-plot of Price vs categorical variables*/
ods graphics off;
ods graphics on;
title 'Price vs clarity';
proc sgplot data=project.diamonds_clean;
  vbox price/ category=clarity
  			  dataskin=sheen
			  outlierattrs=(color=green)
			  meanattrs=(color=black)
       	      medianattrs=(color=black)
              connect=mean
			  connectattrs=(color=red)
;
format price DOLLAR.
run;
ods graphics off;

ods graphics on;
title 'Price vs cut';
proc sgplot data=project.diamonds_clean;
  vbox price/ category=cut
  			  dataskin=sheen
			  outlierattrs=(color=green)
			  meanattrs=(color=black)
       	      medianattrs=(color=black)
              connect=mean
			  connectattrs=(color=red)
;
format price DOLLAR.
run;
ods graphics off;

ods graphics on;
title 'Price vs color';
proc sgplot data=project.diamonds_clean;
  vbox price/ category=color
  			  dataskin=sheen
			  outlierattrs=(color=green)
			  meanattrs=(color=black)
       	      medianattrs=(color=black)
              connect=mean
			  connectattrs=(color=red)
;
format price DOLLAR.
run;
ods graphics off;

ods graphics on;
title 'Price vs carat';
proc sgplot data=project.diamonds_clean;
  vbox price/ category=carat
  			  dataskin=sheen
			  nooutliers
			  connect=mean
			  connectattrs=(color=red);
xaxis display=(novalues);
format price DOLLAR.
run;


