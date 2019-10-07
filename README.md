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
TITLE '5 Number Summary';
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
<p></p>

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

## Feature Engineering (FE)
Feature engineering is the process of using domain knowledge of data to create new features that make the machine learning algorithms work. From what we have learned from EDA, we will remove depth, table, x, y, and z. Diamond price and carat data are not normally distributed, thus, a Box-Cox transformation (aka log transformation in this case) is required. The log transformation uses the natural logarithm, which is by default. To prevent the log result to be negative, we will add 1 to original price and carat. In addition to log transformation, we also need to create ordinal features from original categorical variables based on the grade from the worst to the best that was provided by the company. And finally, we will create one hot dummy features from new created ordinal features.

Feature engineering will result in two data sets: Diamonds_FE and TestDiamonds_FE. Diamonds_FE is the data set for further predictive modeling while TestDiamonds_FE will be used to predict the diamond price. The code at below uses macro. The reason to develop macro is to increase the efficiency of feature engineering. Feature engineering usually involves in tremendously tedious and repeated work, which is not only time consuming but also easy to introduce errors. There are two macros in feature engineering process.  

The first macro is to conduct log transformation, dropping unwanted variables and creating ordinal features. It deals with the two diamond datasets – clean diamond dataset and new diamond dataset differently as their columns are different. For example, in clean diamond dataset, we will transform both price and carat as well as drop depth, table, x, y, and z while the new diamond dataset does not have price, depth, table, x, y, z and ordinal features for clarity and cut are already created.   

```
%macro log_ord(infile, outfile);
data project.&outfile.;
	set project.&infile.;

	logcarat=log(1 + carat);
	%if &infile.=diamonds_clean %then
		%do;
			logprice=log(1 + price);
			drop depth table x y z;
	%end;

	Select (color);
        when ('J') color_ord = 1;
        when ('I') color_ord = 2;
        when ('H') color_ord = 3;
        when ('G') color_ord = 4;
        when ('F') color_ord = 5;           
        when ('E') color_ord = 6;           
        when ('D') color_ord = 7;
        otherwise;
    End;
	%if &infile.=diamonds_clean %then
		%do;
			Select (cut);
		        when ('Fair')      cut_ord = 1;
		        when ('Good')      cut_ord = 2;
		        when ('Very Good') cut_ord = 3;
		        when ('Premium')   cut_ord = 4;
		        when ('Ideal')     cut_ord = 5;
		        otherwise;
		    End;

		    Select (clarity);
		        when ('I1')   clarity_ord = 1;  
		        when ('SI2')  clarity_ord = 2;  
		        when ('SI1')  clarity_ord = 3;  
		        when ('VS2')  clarity_ord = 4;  
		        when ('VS1')  clarity_ord = 5;      
		        when ('VVS2') clarity_ord = 6;      
		        when ('VVS1') clarity_ord = 7;      
		        when ('IF')   clarity_ord = 8;      
		        otherwise;
		    End;
	%end;
run;
%mend;
%log_ord(diamonds_clean, diamonds_FE)
%log_ord(newdiamonds, TestDiamonds_FE)

```
The second macro is to create dummy features using one hot encoding method from ordinal features.

Macro applies to both diamond datasets. D is original categorical field name, dim is the number of sub-groups of ordinal features, and fe the output feature engineered dataset.  

```
%macro dummy_proc(D, dim, fe);
data project.&fe.;
	set project.&fe.;
	array &D._(&dim.) &D._1-&D._&dim.;
	do i=1 to &dim.;
		if &D._ord=i then &D._(i)=1; else &D._(i)=0;
	end;
drop i;
run;
%mend;
%dummy_proc(cut, 5, diamonds_FE)
%dummy_proc(color, 7, diamonds_FE)
%dummy_proc(clarity, 8, diamonds_FE)
%dummy_proc(cut, 5, TestDiamonds_FE)
%dummy_proc(color, 7, TestDiamonds_FE)
%dummy_proc(clarity, 8, TestDiamonds_FE)

```
### Recaps of FE
*	Feature engineering is an indispensable step for preparing features that make machine learning algorithms work.
*	Log transformation from price and carat, ordinal and dummy features from original categorical variables have been successfully created.
*	Macro makes the feature engineering easier.  

## Predictive Modeling
Predictive modeling is to build model and use the built model to predict the result in new data set. It involves in several phases - sampling data, feature selection, training model, evaluating model, and predicting the outcome in new dataset.  

<p align="center">
<img src=images/model_process.jpg alt="Your image title" width="300" />
</p>

The predictive modeling is an iterative process where the model relies on the performance and allows to try different models, different features and different validations (cross validation) until getting the optimal performance.

**Split Dataset**- After feature engineering, we need to split data set into training dataset and testing dataset or validation dataset. As the rule of thumb, 70% data is randomly split for training dataset while the other 30% for the validation dataset. “`proc surveyselect`” randomly split two data sets, which are exported to an output SAS dataset with the selection status column - selected.

```
proc surveyselect data=project.diamonds_FE
    out=project.Diamonds_Train_Valid
    method=SRS    
    samprate=0.7     
    seed=1357924
    outall;
run;

```
The training and validation data sets are obtained by the selection status in the previous output SAS dataset.
```
Data project.Diamonds_Training project.Diamonds_Validation;
    Set project.Diamonds_Train_Valid;
    If Selected Then
        output project.Diamonds_Training;
    Else
        output project.Diamonds_Validation;
Run;

```
**Feature Selection:** There are many ways to select features to the model. For example, you can select features manually to the model. This is not uncommon. You can tentatively enter features as you like. One of common ways to select features is to rank the coefficients and select the highest one to the model – called filtering method. However, the most rational and reliable choice of feature selection is the machine learning feature selection. SAS provides several feature selection options – such as forward, backward, stepwise and LASSO, etc. This project will use manual selection in model 1 with the ordinal features, forward machine learning in model 2 with one hot encoding dummy features and machine learning “`proc glmselect`” in model 3 with interactive effects (categorical class features and continuous feature).

**Model/Algorithm Choice:** The model is usually determined by the business problem you defined. For example, in this project, the business problem is to predict the diamond price from carat and other categorical features. The price as the target is a continuous variable. The simple model is the multiple linear regression, rather than binary problem model such as logistic regression, or classification problem model such as random forest, decision trees, or support machine vector (SMV). This project will start with a multiple `linear regression` model with ordinal features in model 1, one hot encoding dummy features in model 2 and categorical features plus continuous logcarat in model 3, which uses machine learning selection with interaction effects by “`proc glmselect`”.

**Evaluation:** Performance evaluation varies from types of models. In multiple linear regression, the most common metrics of model performance include `R Square`, `Adjusted R Square`, `Mollow’s Cp`, `Akaike Information criterion` (AIC), `Average Square Error` (ASE), `Mean Squared Error` (MSE). Note that in this project, model’s performance is not only the R Square or Adjusted R Square from the log transformed form, but also the residuals or errors from the regular dollars between predicted price and original price.    

**Prediction:** The price prediction is in the new dataset that does not have diamond price. In model 1 and 2, we simply apply “`proc score`” to the prepared new diamond dataset to obtain the predicted price while in model 3, we merged the validation dataset and prepared new diamond dataset before predicting diamond price. After predicting the price in the merged diamond dataset, we select out the predicted price for 3,000 diamonds.

### Model 1: Ordinal Multiple Linear Regression
Model 1 use “`proc reg`” is a multiple linear regression using ordinal features. Model is trained in the training dataset and the parameter estimates is saved to a SAS dataset.

```
ODS GRAPHICS ON;
Proc REG data=project.Diamonds_Training
         outest=project.Model_1_ParameterEst;
     logprice_ord: Model logprice = logcarat cut_ord color_ord clarity_ord;
Run;

```
**Output:**
<p align="center">
<img src=images/model1_variance.jpg alt="Your image title" width="350" />
</p>
<p align="center">
<img src=images/model1_performance.jpg alt="Your image title" width="280" />
</p>
<p align="center">
<img src=images/model1_parameters.jpg alt="Your image title" width="350" />
</p>

Model 1 achieved Adjusted R Square at 0.9525.

To evaluate the model, “`proc score`” is used to create predicted log price in validation dataset. The model keeps the exactly same features as they are in the training phase. Score allows to use the parameter estimates produced from previous step model.

```
Proc Score Data=project.Diamonds_Validation      
           Score=project.Model_1_ParameterEst
           Type=parms
           predict out=project.Model_1_val;
     var logcarat cut_ord color_ord clarity_ord;
Run;

```
After creating the predicted log price, it needs to be converted back to the regular price, where the residual column is also created for further evaluation.

```
Data project.Model_1_val (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_1_val;   
    Predicted_Price = exp(logprice_ord)-1;
    residual=Predicted_price-price;
Run;

```
Once we get the predicted regular price, we can visualize the predicted price against actual price.

```
ODS GRAPHICS ON;
proc sgplot data=project.model_1_val;
  scatter x=price y=predicted_price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						   size=5
						   color=dodgerblue);

TITLE color=white 'Scatter Plot of Price by Predicted Price';
FOOTNOTE color=white 'Remark: Predicted price has outliers';
FOOTNOTE2 color=white 'as large as $150,000 although very few';

xaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
       minor display=(noline);
yaxis label='predicted price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks);
format price predicted_price DOLLAR.;
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/model1_evaluation1.jpg alt="Your image title" width="450" />
</p>
It suggests that predicted price fits the actual price well overall. However, it involves in a large range of outliers although they are very few. To see the residuals, we plot it in the histogram.

```
ODS GRAPHICS ON;
ODS NOPROCTITLE;
ODS SELECT Histogram;
TITLE;
FOOTNOTE;
proc univariate data=project.model_1_val;
  histogram residual/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/model1_evaluation2.jpg alt="Your image title" width="450" />
</p>

It tells that the residual is a normally distributed but with a large range of outliers in the right side. The mean residual of predicted price is $249 while the maximum is $133,252.

After evaluating the performance of model 1 in both log form and regular price form, we will use this model to predict the diamond price in the new diamond dataset, which does not have price.

```
Proc Score Data=project.TestDiamonds_FE      
           Score=project.Model_1_ParameterEst
           Type=parms
           predict out=project.Model_1_pred;

     var logcarat cut_ord color_ord clarity_ord;
Run;

Data project.Model_1_Pred (keep=Predicted_Price carat cut color clarity);
    Set project.Model_1_pred;   
    Predicted_Price = exp(logprice_ord)-1;
Run;

```
The new diamond dataset with predicted price is exported to the spreadsheet and the total amount of predicted price from 3,000 diamonds is $12.7 million.

### Model 2: One Hot Dummy Multiple Linear Regression
Model 2 keeps the same type of regression model as model 1 but replaces ordinal features with dummy features. However, model 2 uses machine learning feature selection method – forward, in which the significance level is specified at 0.99.
```
ODS GRAPHICS ON;
Proc REG data=project.Diamonds_Training;
     logprice_1hot: Model logprice = logcarat
	cut_1 cut_2 cut_3 cut_4 cut_5
 	color_1 color_2 color_3 color_4 color_5 color_6 color_7
     clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_6
     clarity_7 clarity_8 /slentry=0.99 selection=forward;
Run;
ODS GRAPHICS OFF;
```
**Output:**
<p align="center">
<img src=images/model2_featureselection.jpg alt="Your image title" width="450" />
</p>

It shows that cut_3, color_5 and clarity_6 were selected out and model’s R-Square achieved at 0.9581 and Cp at 19. Then we apply those selected features into regression model to get parameter estimates.

```
Proc REG data=project.Diamonds_Training
         outest=project.Model_2_ParameterEst;
     logprice_1hot: Model logprice = logcarat
			cut_1 cut_2 cut_4 cut_5
 		   color_1 color_2 color_3 color_4 color_6 color_7
			clarity_1 clarity_2 clarity_3 clarity_4 clarity_5  
                clarity_7 clarity_8;
Run;

```
We use the same way as model 1 to create predicted price in validation dataset.
```
Proc Score Data=project.Diamonds_Validation      
           Score=project.Model_2_ParameterEst
           Type=parms
           predict out=project.Model_2_val;
     var logcarat cut_1 cut_2 cut_4 cut_5
 	   color_1 color_2 color_3 color_4 color_6 color_7
		clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7
		clarity_8;
Run;

Data project.Model_2_val (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_2_val;   
    Predicted_Price = exp(logprice_1hot)-1;
	residual=Predicted_price-price;
Run;

```
We also visualize the predicted price against the actual price in the validation dataset.

**Output:**
<p align="center">
<img src=images/model2_evaluation1.jpg alt="Your image title" width="450" />
</p>

The result shows that model performance is improved with regard to the residual range of predicted price in the validation dataset.

<p align="center">
<img src=images/model2_evaluation2.jpg alt="Your image title" width="450" />
</p>
The mean residual of predicted price is reduced to $239 from model 1’s $249 and the maximum residual is reduced to $95,630.

As model1, we will use parameter estimates in model 2 to predict the diamond price in the new diamond dataset.

```
Proc Score Data=project.TestDiamonds_FE      
           Score=project.Model_2_ParameterEst
           Type=parms
           predict out=project.Model_2_pred           ;
     var logcarat cut_1 cut_2 cut_4 cut_5
 		color_1 color_2 color_3 color_4 color_6 color_7
		clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7 clarity_8;
Run;

Data project.Model_2_Pred (keep=Predicted_Price carat cut color clarity);
    Set project.Model_2_pred;   
    Predicted_Price = exp(logprice_1hot)-1;
Run;

```
The new diamond dataset with predicted price is exported to the spreadsheet and the total amount of predicted price from 3,000 diamonds is $12.6 million.

### Model 3: GLMSELECT Interaction Multiple Regression
Model 1 and 2 do not consider interaction between features. The `GLMSELECT` procedure performs effect selection in the framework of general linear models. It is very close to `REG` and `GLM`. The REG procedure supports a variety of model-selection methods but does not support a `CLASS` statement. The `GLM` procedure supports a `CLASS` statement but does not include effect selection methods. The `GLMSELECT` fill this gap.

In GLMSELECT model, each term in a model is an effect. There are two kinds of variables: class variables and continuous variables. The variables in `CLASS` statement are called main effects. An independent variable that is not declared in the `CLASS` statement is assumed to be continuous, which must be numeric. There are two primary operators: crossing and nesting. A third operator, the bar operator, is used to simplify effect specification. For example, model **Y = A &nbsp;B&nbsp; C&nbsp;   A`*`B&nbsp; A`*`C&nbsp; B`*`C&nbsp;   A`*`B`*`C** is equivalent to model **Y = A|B|C**.

`GLMSELCT` allows to automatically break down categorical variables and select all possible effects in the model. Indeed, `GLMSELECT` has used machine learning in both feature engineering and feature selection. This project uses “`proc glmselect`” with original categorical variables – cut, clarity and color.

```
ODS GRAPHICS ON;
Proc GLMSELECT data=project.Diamonds_Training        valdata=project.Diamonds_Validation
               PLOTS=All;

     Class Cut Color Clarity;

     Model logprice = logcarat|cut|color|clarity @2 / Choose=Validate
                                                      Stats=(ASE AIC          ADJRSQ);
     output out=project.Model_3_Stat
            P=pred_price3
            R=Residual3;
Run;
ODS GRAPHICS OFF;

```
**Output:**
<p align="center">
<img src=images/model3_summary.jpg alt="Your image title" width="350" />
</p>
<p align="center">
<img src=images/model3_classlevel.jpg alt="Your image title" width="280" />
</p>
<p align="center">
<img src=images/model3_dimension.jpg alt="Your image title" width="180" />
</p>
<p align="center">
<img src=images/model3_stepwise_summary.jpg alt="Your image title" width="600" />
</p>
<p align="center">
<img src=images/model3_coefficient_progress.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/model3_fit_criteria.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/model3_progressionASE.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/model3_performance.jpg alt="Your image title" width="180" />
</p>
Model 3 involves 11 effects and 173 parameters, stopping at step5 by adding cut class effect with Adjusted R Square at 0.9723, Root MSE 0.17, AIC -96220.
<p></p>
11 effects include: intercept, clarity, cut, color, logcarat, logcarat*clarity, logcarat*cut, logcarat*color, clarity*cut, clarity*color, cut*color. The paramters include all break downs of categorical levels plut the intercept.
<p></p>
The code above also output the statistical SAS dataset, which allows to further evaluate the model performance with regard to the predicted price.

```
Data project.Model_3_stat (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_3_stat;   
    Predicted_Price = exp(pred_price3)-1;
	residual=Predicted_price-price;
Run;

```
We use the same way as it is in model 1 and 2 to visualize the predicted price.

**Output:**
<p align="center">
<img src=images/model3_evaluation1.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/model3_evaluation2.jpg alt="Your image title" width="450" />
</p>
The maximum residual is $35,852 (not $50,000 interpreted in the previous scatter plot) and its mean residual is reduced to $175 from $249 in model 1 and $240 in model 2. It suggests that the model performs better than previous two models.  
<p></p>
After model selection and validation, we will go to predict the diamond price in the new diamond dataset.
<p></p>
GLMSELECT allows for directly apply the model to new dataset, but requires the target variable in the new dataset. New diamond dataset does not include the log price variable. The solution is to create a new dataset called Unknown_TestDiamonds by merging previous validation dataset and new diamond dataset from the feature engineering with the separate label “validation” and “test”. After we get the predicted price, we can select the predicted price for 3,000 diamonds in new diamond dataset with condition of “test”.

```
Data project.Diamonds_Validation2 (keep=DS logprice logcarat cut color clarity);
    Retain DS logprice logcarat cut color clarity;
    Set project.Diamonds_Validation;
    Format DS $10.;
    Format cut $11.;
    Format color $3.;
    Format clarity $6.;

    DS = "VALIDATION";    
Run;

Data project.TestDiamonds_FE2 (Keep=DS logcarat cut color clarity);
    Retain DS logcarat cut color clarity;
    Set project.TestDiamonds_FE;    
    Format DS $10.;
    Format cut $11.;
    Format color $3.;
    Format clarity $6.;

    DS = "TEST";
Run;

Data project.Unknown_TestDiamonds;
    Set project.Diamonds_Validation2 project.TestDiamonds_FE2;
Run;  

```
Apply the GLMSELECT model to unknown dataset.

```
Proc GLMSELECT data=project.Unknown_TestDiamonds
     PLOTS=ALL;
     Class Cut Color Clarity;
     Model logprice = logcarat logcarat|cut|color|clarity @2 / choose=adjrsq
showpvalues
stats=all;
     output out=project.Model_3_new_pred
            predicted=Predicted_Price_3;
Run;
ODS Graphics off;

```
Select dataset and convert log price back to predicted price.

```
Data project.Model_3_new_pred (drop=logprice);
    Set project.Model_3_new_pred;
    If DS = "TEST";
    Predicted_Price = exp(Predicted_Price_3)-1;
Run;

```
The new diamond dataset with predicted price for model 3 is exported to the spreadsheet and the total amount of predicted price from 3,000 diamonds is $12.3 million.

When we replace main effects with ordinal features with meaningful grade, the model keeps the same without any improvement. It indicates that the grade code is recognized as original categorical nature by the model, rather than what we expected the meaningful grade from the worst to the best.

### Recaps of Predictive Modeling
*	The predictive modeling is an iterative process, starting from data splitting, select features, model building and training, evaluating until getting the best performance and ending with the prediction in the new dataset.
*	Model 3 with GLMSELECT procedure achieved the best performance in predicting diamond price with machine learning feature selection where the interaction between both main effects and numeric effect are taken into account, which uses machine learning in both feature engineering and feature selection.
*	One hot encoding improved the model from the model that simply uses the ordinal features.
*	When we replace categorical class with ordinal class, the model did not involve any change. It indicates that GLMSELECT model does not deal them as the ordinal grade as we expected.

## RESULTS AND DISCUSSIONS
Diamond price prediction data science process produces a lot of analytic results that allow us to better understand data and provide the best solution to decision makers. This section will recap the most important findings and insights as well as the critical considerations.   
### Data Quality Assessment
The raw diamond dataset includes 35,940 observations where 289 observations involve duplication issue and 146 duplicates are removed. Also, the raw data has invalid data with zero values in x, y, or z variables. The number of invalid observations before removing the duplicates is 20. There are total 165 observations that were removed, which are account for 0.31% from original diamond dataset. The final clean diamond dataset includes 35,775 observations.
<p align="center">
<img src=images/data_quality.jpg alt="Your image title" width="250" />
</p>

### Data insights
**Data Distributions:** The variable carat and price are not normally distributed, especially price that is extremely skewed to the right. After the log transformation, the data become not as skewed as the original. However, log transformed price seems to be a bimodal distribution. This makes the prediction more challenging. For instance, when we use the central measure to evaluate the performance of model, any point away from the central fitness line will be considered as errors or outliers. If the target is not normally distributed, the central rule will be challenged. The diamond data might be merged from two different samples originally. To confirm the integrity of data sources, a further research is required.  
<p align="center">
<img src=images/logcarat.jpg alt="Your image title" width="300" />
<img src=images/logprice.jpg alt="Your image title" width="300" />
</p>

**Correlation and Association between Variables:** Carat is highly correlated with x, y, and z while also highly correlated to price. Depth and table, on the other hand, are very weakly correlated with carat and price. 
<p></p>
The Cramer’s V tells that categorical variables – clarity, cut and color are very weakly associated each other. Diamond price varies over the sub-groups of categorical variables. 
<p></p>
<p align="center">
<img src=images/cramerv.jpg alt="Your image title" width="250" />
</p>
<p align="center">
<img src=images/price_clarity_boxplot.jpg alt="Your image title" width="300" />
<img src=images/price_clarity_ord_boxplot.jpg alt="Your image title" width="300" />
</p>

### Model Comparison
Three predictive models are summarized in the following table. 
<p align="center">
<img src=images/model_comparison.jpg alt="Your image title" width="450" />
</p>

Model 1 uses ordinal as the predictors with manual feature selection to the linear multiple regression model. It ends with a 0.9525 R2 and average residual at validation dataset $249. The total dollars in new diamond dataset predicted is $12.7 million and the suggested total investment for 3,000 diamonds is $8.9 million (the suggest investment is the predicted price multiplied by 0.7).  
<p></p>
Model 2 uses dummy features from one hot encoding and machine learning forward feature selection method, which provides with a better performance in comparison with model 1. The R2 is 0.9581 and average residual at validation dataset is $240. The total predicted dollars in new diamond dataset is $12.6 million and the suggested total investment for 3,000 diamonds is $8.8 million.
<p></p>
Model 3 performs the best by using categorical features and letting the machine learning `GLMSELECT` to select effects that consider the interaction, which, indeed, is a process of machine learning in both feature engineering and feature selection. The model results in a R2 at 0.9723 and average residual at validation dataset $175. The total predicted dollars in new diamond dataset is $12.3 million and the suggested total investment for 3,000 diamonds is $8.6 million. 

## CONCLUSION AND RECOMMENDATIONS
Diamond price prediction used SAS EG 8.1 as the platform and went through the entire lifecycle of data science process starting from EDA to obtain the understanding of dataset about diamond. The EDA provided the fundament for the further predictive modeling analysis, which included feature engineering, feature selection, model training, validation and diamond price prediction. The model has achieved a 0.9723 R Square and an average residual between predicted price and actual price at $175.  And the final suggested investment for entire 3,000 diamonds will be $8.6 million, which saved $0.3 million from model 1. Although the historical diamond price was not normally distributed and the transformed price showed a bimodal distribution pattern, the machine learning particularly `GLMSELECT` performed very well with taking the interaction between features into account, which indeed, a process of machine learning in both feature engineering and feature selection. 
  
To improve the performance of diamond price prediction model, the recommendations include: 

*	Conduct the research to investigate the original data source. The bimodal distribution in transformed price showed that the original dataset may not be uniform. 
*	Continue the effort to improve the model in feature engineering and feature selection. The achieved model showed that there is some space to improve. It is possible to use nesting to achieve more complicated effects. Also cross validation and deep learning may also help fine tune the model.
*	Continue the research on data science machine learning algorithms and techniques in the future.



