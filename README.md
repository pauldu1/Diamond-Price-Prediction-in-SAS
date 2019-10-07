# Diamond Price Prediction in SAS
 A complete data science process poject with SAS
 ## Introduction
 Diamonds have been believed to bring luck – health, wealth and protection against most of the ills that can befall mankind. They are a multi-billion-dollar business. The worldwide retail market for diamond jewelry was $60 billion in 2010.

Recently, a diamond distributor decided to exit the market and has put up a set of 3,000 diamonds up for auction. A jewelry company wants to put in a bid to purchase but is unsure how much it should bid.

Among a matrix of techniques of data science, SAS is recognized as one of the most powerful data science machine learning tools in data exploration, data mining and predictive analysis. This project will use Base SAS 9.4 M6 and SAS Enterprise Guide 8.1 to conduct the diamond data exploration and diamond price prediction.

## Objectives
The data science team was tasked to collect the historical diamond data set and conduct the data science project to provide the actionable insights about diamond dataset and predict the prices for 3,000 diamonds to bid.

#### The objectives are to:
*	Establish the Lifecycle pipeline of data science process
*	Conduct Exploratory Data Analysis (EDA)
*	Build Machine Learning model
*	Predict prices of Diamonds
*	Provide recommendations

## Assumptions
We assume that historical diamond data was collected from the current retail market. The diamond price that the model predicts represents the final retail price the consumer will pay. The company generally purchases diamonds from distributors at 70% of the retail price, so the recommended bid price will represent that.

## Lifecycle Data Science Process
Diamond price prediction is a project with a lifecycle of data science process, which includes data collection, data exploratory analysis (EDA), feature engineering (FE), feature selection (FS), model building, model evaluation, price prediction and recommendations.

<p align="center">
<img src=images/ds_process.jpg alt="Your image title" align="center" width="400" />
</p>

## Import data

There are two diamond datasets - one is historical data named diamonds.csv and the other new diamond named new_diamonds.csv.

CSV files are loaded with **proc import** and **macro**. There is an unnamed column (var1), therefore, a new rec_id field is created and var1 is dropped.
Macro allows to repeatedly use the code that increase the efficiency of data loading.

Imported SAS diamond datasets are saved to the “project” SAS library (`libname project "C:\DIAMONDS\REPORT\EDA"`).

```
%macro import(folder, in_put, out_put);
proc import datafile="C:\DIAMONDS\DATA\&folder.\&in_put..csv"
     out=project.&out_put.
     dbms=csv
     replace;
     guessingrows=Max;     
     getnames=yes;     
run;

Data project.&out_put.;
     Format rec_id BEST12.;
     Set project.&out_put.;
     rec_id = input(VAR1, BEST12.);
     Drop VAR1;
Run;
%mend;

%import(training, diamonds, diamonds_raw)
%import(test, new_diamonds, TestDiamonds)

```
## Exploratory Data Analysis (EDA)
### Environment Setting
SAS EG 8.1 provides an interface to customize the output background. In this project, the output background is set to black by selecting “`HighContrast`” in Appearance Style in Result>HTML tab in Tools>Options. In addition to the background, SAS EG also allows to control the output through ODS (Output Delivery System). The steps include:
*	Print out the list of output using “`ODS TRACE ON/OFF`”
*	Select output from the list by “`ODS SELECT`”

### Dataset Overall
**proc contents** – After importing CSV files into SAS, we want to get an overview about diamond dataset, such as data size, columns, type, etc. “`proc contents`” is the tool to get those information. The syntax is showed in the code at below. Note that proc contents has many outputs by default. To specify the output, “`ODS SELECT`” is used to select only attributes and variables tables.
```
ODS SLECT attributes variables;
proc contents data=project.diamonds_raw;
run;
```
**Output:**
<p align="center">
<img src=images/attributes.jpg alt="Your image title" width="400" />
</p>
<p align="center">
<img src=images/variables.jpg alt="Your image title" width="300" />
</p>

Diamond dataset includes 53,940 observations, 11 variables, 3 of them categorical and 8 numeric. Besides, the output also tells the other information such as length and format of variables. 

**5 Number Statistics** - To go further inside the data, “`proc mean`” is used to get the descriptive statistics about the data.  It allows to customize the statistics and “`ODS NOPROCTITLE`” suppresses the default title.  Variables are listed after “`var`” keyword. Note that only numeric variables can be listed after “`var`”. 
```
ODS NOPROCTITLE;
title '5 Number Summary';
proc means data=project.diamonds_raw min max median q1 q3;
var carat depth price table x y z;
run;
ODS GRAPHICS OFF; 

```
**Output:**
<p align="center">
<img src=images/5_num_stat.jpg alt="Your image title" width="450" />
</p>

The output is a 5-number statistics - minimum, maximum, median, lower quartile and upper quartile. 5-number statistics tells the distribution of data about the central line or mean. If the mean is in the middle of range between minimum and maximum, it is called normal distribution. Otherwise, if the mean is close to one side, it is called skewed distribution. In this output, depth and table are normally distributed based on their mean, min and max. The variable carat and price, on the other hand, the mean extremely goes to the minimum side. They are extremely skewed to the right. Note that minimum x, y and z are 0. This indicates that the data is not clean because x, y, or z cannot be 0. 

**Duplication Check** - The 5-number statistics provided a clue that diamond dataset is not clean. We need to examine its integrity and validity. “`proc sort`” allows to check the duplication. If data is duplicated, we need to clean it up. Code at below checks the duplicates by using keyword “`nodupkey`” and finally exports clean and duplicated datasets. Note that rec_id is not used. It’s simply the record ID. It’s not necessary to participate in duplication checking. The exported clean dataset is a dataset that removed all duplicated records and duplicated dataset is the data that contained all unwanted records we want to remove. Therefore, the total number of records that involve duplication will be removed duplicated records plus records in the clean dataset that are associated with removed duplicated records.
```
proc sort data=project.diamonds_raw nodupkey 
	out=project.diamonds_uniq 
	dupout=project.diamonds_dup;
 by carat cut color clarity depth table price x y z;
run;   

```
The way to get the total number of records that involve duplication is “`proc sql`” that is described as: 
* Get unique records from the removed duplicated dataset by group aggregation. The aggregation loses the rec_id. 
* To get rec_id, join unique duplicate data set back to clean data set with all fields except rec_id as the common keys.
* Merge unique duplicates with rec_id and original removed duplicates.

```
proc sql;
    create table project.diamonds_uni_dup as 
    select carat, cut, color, clarity, depth, table, price, x, y, z, 
    count(*) as numRows
    from project.diamonds_dup
    group by carat, cut, color, clarity, depth, table, price, x, y, z
   ;
quit;

proc sql;
	create table project.diamonds_single_dup as
	select a.rec_id, a.carat, a.cut, a.color, a.clarity, a.depth, a.table, 
           a.price, a.x, a.y, a.z 
	from project.diamonds_uniq as a inner join project.diamonds_uni_dup as b 
	on a.carat=b.carat and a.cut=b.cut and a.color=b.color and 
       a.clarity=b.clarity and a.depth=b.depth and a.table=b.table and
       a.price=b.price and a.x=b.x and a.y=b.y and a.z=b.z; 
quit;

data project.diamonds_total_dup;
	set project.diamonds_single_dup project.diamonds_dup;
run;

```
As the result, the total number of observations that involve in duplication is 289, which will be exported to the exception report. 

**Validity Check** – To deal with the validity that some zero values involved in x, y and z, “`proc sql`” is used. We use the raw diamond dataset, rather than the clean dataset to check the invalid records that are created and saved to zero SAS dataset. It will be exported to exception report. After removing the records with zero values, the total number of records of diamond dataset – diamonds_clean is 53,775.

```
proc sql;
	create table project.zero as
	select * from project.diamonds_raw
	where x=0 or y=0 or z=0;
quit;

data project.diamonds_clean;
	set project.diamonds_uniq;
	if x=0 or y=0 or z=0 then delete;
run;

```
### Statistical Data Visualization 
After getting the clean data, a simple and straightforward way is to visualize the data. Visualization is a critical part for SAS in EDA and data mining. SAS has built a wide range of techniques to visualize data. For example, to explore the normality of data distribution, the histogram method is very effective. To find the relationship between variables, the scatter method is very straightforward. There are two different types of variables in the diamond dataset – numeric and categorical. We will start with the numeric variable. 

**Histogram for Individual Variables** – To explore the data distribution of variables, “proc univariate” has function histogram and inset that allow to create histogram with statistic inset. The code at below uses the “`ODS SELECT`” to export `histogram`, `parameter estimates`, `goodness fit` and `fit quantiles`.  `Inset` includes `min`, `max`, `mean`, `std`, `Q1`, `Q3`, `skewness` and `kurtosis` with “`ne`” – northeast position. After keyword “`histogram`”, the code only uses carat and price. In source code, depth, table, x, y, and z are also used. Similarly, the code will produce all items in “`ODS SELECT`” list. However, we only select the histogram of carat and price as the report illustration.

```
ODS GRAPHICS ON;
ODS NOPROCTITLE;
ODS SELECT Histogram ParameterEstimates GoodnessFit FitQuantiles;
TITLE;
FOOTNOTE;
proc univariate data=project.diamonds_clean (drop=rec_id);
  histogram carat price/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/carat_histogram.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/price_histogram.jpg alt="Your image title" width="450" />
</p>

The histograms show that both diamond price and carat are skewed to the right, especially the price. This confirmed the result interpretation from previous 5-number statistics about the distribution of carat and price. For skewed data, it is necessary to apply the appropriate transformation before entering the predictive analysis.

**Normal Quartile-Quartile Plot** – Compared to the way to check the normality using histogram, we can also use “`qqplot`” in “`proc univariate`” to examine the normality of data distribution. In the option after the slash, a keyword “normal” is provided along with the mean and standard deviation that are simplified with “`mu`” and “`sigma`” respectively. The value of mean and standard deviation is from previous histogram export. QQ-plot in proc univariate allows to draw multiple variables. The code at below, we only use price and carat. You can see the full list of variables in the QQ-Plot in the source code. 

```
ODS GRAPHICS ON;
TITLE 'Q-Q plot';
proc univariate data=project.diamonds_clean noprint;
	qqplot price /normal(mu=3931.2 sigma=3985.9) 
         odstitle = 'Normal Quartile-Quartile Plot for Diamonds (price)';

	qqplot carat /normal(mu=0.7975 sigma=0.4732) 
         odstitle='Normal Quartile-Quartile Plot for Diamonds (carat)';
run;

```
**Output:**
<p align="center">
<img src=images/carat_qqplot.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/price_qqplot.jpg alt="Your image title" width="450" />
</p>

The result is consistent with the result from histogram that both price and carat are not normally distributed. Some transformations are required afterwards.

**Scatter for Pair of Continuous Variables**– After normality examination, it would be interesting to explore the relationship between a pair of variables. For example, we want to know what pattern will look like if we plot the price variable against the carat variable. This is two way or two dimensional plotting. The `scatter` in “`proc sgplot`” provides the function and options to plot the paired variables with capability of customization for symbol, axis, and format. The code at below is only the scatter plot for price and carat. Scatter plot for other paired variables such as price vs depth, price vs table, price vs x, price vs y and price vs z is provided in the source code. In the code at below, the option after the slash in scatter statement is the place to customize `transparency`, `symbol`, `marker size` and `color`. `Xasis` and `yaxis` are customized through `axis label`, `value range`, `grid`, `tick`, and etc. The format allows to customize the data into dollar. 
```
ODS GRAPHICS ON;
proc sgplot data=project.diamonds_clean;
  scatter x=carat y=price/ transparency=0.9
			          markerattrs=(symbol=circlefilled
				      size=5
				      color=dodgerblue);
 
title color=white 'Scatter Plot of Price by Carat';
footnote color=white 'Remark: data has carat > 3';

xaxis label='carat'
	  labelattrs=(color=dimgray weight=bold)
	  values=(0 1 2 3)
	  valueattrs=(color=gray)
        minor display=(noline);

yaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
       display=(noline noticks);
format price DOLLAR.;
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/price_carat_scatter.jpg alt="Your image title" width="450" />
</p>

The scatter plot shows how carat fits the price well. However, the data points start dispersed when the values increase. Also the points are not continuously distributed and seemly affected by some vertical “unknown” lines.   

**Correlation between Continuous Variables** – Compared to the scatter plot, which can only provide a glance at relationship about a pair of variables, correlation coefficient can tell more accurate information about if a pair of variables are correlated and how strong they are. “`proc corr`” helps to create a coefficient matrix for all numeric variables, not only one pair. Proc corr provides many options to explore the correlation. In the code at below, however, we only select `pearson` correlation. In syntax, you can provide the variables after keyword “`var`”. If you use `_numeric_` after `var`, the procedure will choose all numeric variables automatically. For the customization purpose, we provide 5 variables. Note that `proc corr` is only for numeric variable, not for categorical variable.  
```
ODS GRAPHICS ON;
IDS SELECT PearsonCorr;
title 'Pearson Correlation between Continuous Variables';
proc corr data=project.diamonds_clean;
	var price carat depth table x y z;
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/correlation_coefficients.jpg alt="Your image title" width="450" />
</p>

The matrix of correlation coefficient shows that carat is extremely and highly correlated to x, y, and z. It can be explained by the fact that the weight of diamond – carat is the result of diamond’s volume, aka x, y and z. In the same time, carat is also highly correlated to price. On the other hand, depth and table are very weakly correlated with price or carat. The coefficient matrix suggests that x, y, z should not be selected for the further predictive modeling for their collinearity nature with carat while depth and table should not be selected due to their weak correlation with the price.    

**Coefficient Matrix Visualization** – Compared to the coefficient number, visualizing this coefficient matrix would be more helpful to audience to read and compare the relationship between continuous variables on the same page.  The matrix in “`proc sgscatter`” is an effective way to visualize this matrix. Note that the procedure is computationally expensive. It takes the time to complete the entire plotting task. 

```
ODS GRAPHICS ON
TITLE 'Matrix of correlation between continuous variables';
proc sgscatter data=project.diamonds_clean; 
matrix price carat depth table x y z/diagonal=(histogram kernel);
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/correlation_matrix.jpg alt="Your image title" width="450" />
</p>

The visualized correlation matrix provides a big picture to compare the correlations between all paired variables. The result shows that carat almost perfectly correlated with x, y, and z and highly correlated to price. For that reason, price is also highly correlated to x, y, and z. On the other hand, depth and table are highly correlated to y, z, but not carat and price. 

**Association between Categorical Variables** – After the numeric variables, we also need to explore the categorical variables. Categorical variable is different from numeric or continuous variable. It is about discrete classes, levels, or subgroups, rather than the continuous number as in numeric variable. SAS provides several techniques to explore the categorical data. In this project, we will focus on association between categorical variables and association between categorical and continuous variables. The purpose to do this is to check whether they are independent and how strong they are associated if not. We also want to see how the continuous variable associates with the sub groups of categorical variable. The table in “`proc freq`” is to check the association between categorical variables. The `chisq` option after the slash is to use Chi-Square test. The first table statement in the code at below examines the association between clarity and cut, clarity and color by using ``*`` to associate with other two variables - cut and color. The second table statement checks the association between cut and color. These two table statements cover all possible associations between 3 C’s variables. The code will output 3 chi-square test result set (chi-square test and statistics). In this report, we only snapshot the result for the pair - clarity by cut.  

```
ODS GRAPHICS ON
TITLE 'Chi square test for 3Cs';
proc freq data=project.diamonds_clean;
	table clarity*(cut color)/chisq;
	table cut*color /chisq;
run; 
ODS GRAPHICS OFF;

```   
**Output:**
<p align="center">
<img src=images/chisq_test_clarity_cut.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/cramer_v_clarity_cut.jpg alt="Your image title" width="380" />
</p>

The first table in the output is the chi-square test table, which shows the frequency and percent of data distributed each other by clarity and cut. The second table shows the overall association, where Cramer’s V is a common indicator of independency with value from 0 to 1. If Cramer’s V is small, the association between two categorical variable is weak. In this case, the association between clarity and cut is very weak.  

**Association between Categorical and Numeric Variables by Box-plot** – In additional to the association between categorical variables, we also want to see the association pattern between categorical variables and numeric variables. The `vbox` in “`proc sgplt`” helps draw the box-plot, which is comprised of `minimum`, `maximum`, `median`, `whisker`, and `outliers`. It allows explore the continuous data within breakdowns of categorical data – aka sub groups of categorical variables. The code at below is the box plot for price vs clarity. For box plots for other pairs of variables such as price vs cut, price vs color, please see the source code. The syntax allows to customize the box plot by specifying the `dataskin`, `outliers`, `mean symbol`, `link line`. It also allow to format the data. 

```
ODS GRAPHICS ON;
TITLE 'Price vs clarity';
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
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/price_clarity_boxplot.jpg alt="Your image title" width="450" />
</p>

The result shows how the price is distributed across different sub groups in clarity. It is worthy to note that the sub-group of clarity is ordered by alphabet, not the meaningful grade. Therefore, it is necessary to apply this procedure to dataset with transformed ordinal variables so that the sub-group will be ordered by its grade. The output with the ordinal variable is showed at below.

<p align="center">
<img src=images/price_clarity_ord_boxplot.jpg alt="Your image title" width="450" />
</p>
The new box plot reveals that price in sub-groups of ordinal clarity is different. The mean price is the highest at sub-group 2 while that is the lowest at sub-group 7. The mean price in sub-groups of clarity from the worst to the best decreases except the sub-group 2 with the highest mean price.  


**Deal with Carat as Categorical Variable** – When exploring the carat variable, it is found carat values are not unique. It can be classified into different groups. We can deal it as the categorical variable and see what pattern it will have. The code at below uses the similar syntax as previous code except category with carat, `nooutliers` and `novalues` displayed in `xaxis`.  

```
ODS GRAPHICS ON;
title 'Price vs carat';
proc sgplot data=project.diamonds_clean;
  vbox price/   category=carat
  			  dataskin=sheen
			    nooutliers
			    connect=mean
			    connectattrs=(color=red);
xaxis display=(novalues);
format price DOLLAR.
run;
ODS GRAPHICS OFF
```
**Output:**
<p align="center">
<img src=images/price_carat_boxplot.jpg alt="Your image title" width="450" />
</p>

It reveals that carat fits the price very well. That also helps explain the fact that carat is highly correlated with price. 

### Recap of EDA
*	The raw diamond dataset involves in duplicates and invalid data with zero values in x, y, or z. 
*	Diamond price and carat are not normally distributed, especially price that extremely skewed to the right side. The transformation is necessary. 
*	Carat is highly correlated with x, y, and z while also highly correlated to price. Depth and table, on the other hand, are very weakly correlated with carat and price. 
*	Categorical variables are very weakly correlated each other between clarity, cut and color.
*	Diamond price varies over the sub-groups of categorical variables. 
*	As a result, depth, table, x, y, and z will not be selected to the further predictive analysis.
 
