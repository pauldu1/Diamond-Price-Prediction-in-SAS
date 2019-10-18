# Diamond Price Prediction in SAS
 
## Introduction
A jewelry company wants to put in a bid to purchase but is unsure how much it should bid. The objectives are to collect the historical diamond data set and conduct exploratory data analysis and predictive analysis to provide the predicted prices for 3,000 diamonds to bid.

#### Steps Covered:
*	Importing Data
*	Exploratory Data Analysis
*	Feature Engineering
*	Predictive Analysis

## Importing Data
There are two diamond datasets - one is historical data named diamonds.csv and the other new diamond named new_diamonds.csv.

CSV files are loaded with **proc import** and **macro**. There is an unnamed column (var1), therefore, a new rec_id field is created and var1 is dropped. 

Suppose the library is defined as “project”, diamonds.csv in training folder and new_diamonds.csv in the test folder.

```
%macro import(folder=, infile=, outfile=);
proc import datafile="your_data_source\&folder.\&in_put..csv"
     out=project.&outfile.
     dbms=csv
     replace;
     guessingrows=Max;     
     getnames=yes;     
run;

Data project.&outfile.;
     Format rec_id BEST12.;
     Set project.&outfile.;
     rec_id = input(VAR1, BEST12.);
     Drop VAR1;
Run;
%mend import;

%import(folder=training, infile=diamonds, outfile=diamonds_raw)
%import(foler=test, infile=new_diamonds, outfile=TestDiamonds)

```
## Exploratory Data Analysis (EDA)

### Dataset:
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

### 5 Number Statistics 
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

### Duplication Check 
```
proc sort data=project.diamonds_raw nodupkey 
	out=project.diamonds_uniq 
	dupout=project.diamonds_dup;
	by carat cut color clarity depth table price x y z;
run;   

```

### Validity Check
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
After removing the duplicates and records with zero values, the total number of records of diamond dataset – diamonds_clean is 53,775.

### Histogram for Individual Variables 
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

### Normal Quartile-Quartile Plot 
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

### Scatter for Pair of Continuous Variables
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

### Correlation between Continuous Variables
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

The matrix of correlation coefficient shows that carat is highly correlated to x, y, and z. It can be explained by the fact that the weight of diamond – carat is the result of diamond’s volume, aka x, y and z. In the same time, carat is also highly correlated to price. On the other hand, depth and table are very weakly correlated with price or carat. The coefficient matrix suggests that x, y, z should not be selected for the further predictive modeling for their collinearity nature with carat while depth and table should not be selected due to their weak correlation with the price.    

### Coefficient Matrix Visualization 
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

The visualized correlation matrix provides a big picture to compare the correlations between paired variables. The result shows that carat almost perfectly correlated with x, y, and z and highly correlated to price. For that reason, price is also highly correlated to x, y, and z. On the other hand, depth and table are highly correlated to y, z, but not carat and price.

### Association between Categorical Variables   
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

### Association between Categorical and Numeric Variables by Box-plot 
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
		    connectattrs=(color=red);
		    
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

### Deal with Carat as Categorical Variable   
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

## Feature Engineering (FE)
### Log Transformation and Ordinal Coding
```
%macro log_ord(infile=, outfile=);
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
%log_ord(infile=diamonds_clean, outfile=diamonds_FE)
%log_ord(infile=TestDiamonds, outfile=TestDiamonds_FE)

```
### Creating Dummy Features
```
%macro dummy_proc(cls, lvl, fe);
data DS.&fe.;
    set DS.&fe.;
    array &cls._(&lvl.) &cls._1-&cls._&lvl.;
    do i=1 to &lvl.;
        if &cls._ord=i then &cls._(i)=1; else &cls._(i)=0;
    end;
drop i;
run;
%mend dummy_proc;
%dummy_proc(cls=cut, lvl=5, fe=diamonds_FE)
%dummy_proc(cls=color, lvl=7, fe=diamonds_FE)
%dummy_proc(cls=clarity, lvl=8, fe=diamonds_FE)
%dummy_proc(cls=cut, lvl=5, fe=TestDiamonds_FE)
%dummy_proc(cls=color, lvl=7, fe=TestDiamonds_FE)
%dummy_proc(cls=clarity, lvl=8, fe=TestDiamonds_FE)

```
## Predictive Modeling
### Split Dataset
```
proc surveyselect data=project.diamonds_FE
	out=project.Diamonds_Train_Valid
	method=SRS    
	samprate=0.7     
	seed=1357924
	outall;
run;

```
```
Data project.Diamonds_Training project.Diamonds_Validation;
	Set project.Diamonds_Train_Valid;
	If Selected Then
		output project.Diamonds_Training;
	Else
		output project.Diamonds_Validation;
Run;

```

### Model 1: Multiple Linear Regression with Ordinal Features
**Model Training**
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

**Model Evaluation**
```
Proc Score Data=project.Diamonds_Validation      
           Score=project.Model_1_ParameterEst
           Type=parms
           predict out=project.Model_1_val;
	var logcarat cut_ord color_ord clarity_ord;
Run;

```
```
Data project.Model_1_val (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_1_val;   
    Predicted_Price = exp(logprice_ord)-1;
    residual=Predicted_price-price;
Run;

```

**Visualize the Performance**

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

It tells that the residual is a normally distributed but with a large range of outliers in the right side. The mean residual of predicted price is $249.

**Predict Price in New Diamond Dataset** 
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

### Model 2: Multiple Linear Regression with One Hot Dummy Features 
**Feature Selection - Forward Method**
```
Proc REG data=DS.Diamonds_Training;
    logprice_1hot: Model logprice = logcarat 
                                    cut_1 cut_2 cut_3 cut_4 cut_5
                                    color_1 color_2 color_3 color_4 color_5 color_6 color_7 
                                    clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_6 clarity_7 clarity_8 
                                    /slentry=0.99 selection=forward;
Run;
```
**Output:**
<p align="center">
<img src=images/model2_featureselection.jpg alt="Your image title" width="450" />
</p>

It shows that cut_3, color_5 and clarity_6 were selected out and model’s R-Square achieved at 0.9581 and Cp at 19. Then we apply those selected features into regression model to get parameter estimates.

**Model Training**
```
Proc REG data=DS.Diamonds_Training outest=DS.Model_2_ParameterEst;
     logprice_1hot: Model logprice = logcarat 
                                     cut_1 cut_2 cut_4 cut_5
                                     color_1 color_2 color_3 color_4 color_6 color_7 
                                     clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7 clarity_8;
Run;

```

**Model Evaluation**
```
Proc Score Data=DS.Diamonds_Validation      
           Score=DS.Model_2_ParameterEst
           Type=parms
           predict out=DS.Model_2_val;
           
    var logcarat cut_1 cut_2 cut_4 cut_5
        color_1 color_2 color_3 color_4 color_6 color_7 
        clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7 clarity_8;
Run;

Data DS.Model_2_val (keep=price Predicted_Price residual carat cut color clarity);
    Set DS.Model_2_val;   
    Predicted_Price = exp(logprice_1hot)-1;
    residual=Predicted_price-price;
Run;
```
**Visualize the Performance**

**Output:**
<p align="center">
<img src=images/model2_evaluation1.jpg alt="Your image title" width="450" />
</p>

The result shows that model performance is improved with regard to the residual range of predicted price in the validation dataset.

<p align="center">
<img src=images/model2_evaluation2.jpg alt="Your image title" width="450" />
</p>
The mean residual of predicted price is reduced to $239 from model 1’s $249 and the maximum residual is reduced to $95,630.

**Predict the Price in New Diamond Dataset**
```
Proc Score Data=DS.TestDiamonds_FE      
           Score=DS.Model_2_ParameterEst
           Type=parms
           predict out=DS.Model_2_pred;
           
    var logcarat cut_1 cut_2 cut_4 cut_5
        color_1 color_2 color_3 color_4 color_6 color_7 
        clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7 clarity_8;
Run;

Data DS.Model_2_Pred (keep=Predicted_Price carat cut color clarity);
    Set DS.Model_2_pred;   
    Predicted_Price = exp(logprice_1hot)-1;
Run;

```
The total amount of predicted price from 3,000 diamonds is $12.6 million.

### Model 3: Multiple Linear Regression with Interactions by GLMSELECT
**Model Selection**
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
**Visualize the Performance**

**Output:**
<p align="center">
<img src=images/model3_evaluation1.jpg alt="Your image title" width="450" />
</p>
<p align="center">
<img src=images/model3_evaluation2.jpg alt="Your image title" width="450" />
</p>
The mean residual is reduced to $175 from $249 in model 1 and $240 in model 2. It suggests that the model performs better than previous two models.  
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
```
Data project.Model_3_new_pred (drop=logprice);
    Set project.Model_3_new_pred;
    If DS = "TEST";
    Predicted_Price = exp(Predicted_Price_3)-1;
Run;

```
The new diamond dataset with predicted price for model 3 is exported to the spreadsheet and the total amount of predicted price from 3,000 diamonds is $12.3 million.

### Model Summary
Three predictive models are summarized in the following table. 
<p align="center">
<img src=images/model_comparison.jpg alt="Your image title" width="450" />
</p>

Model 1 uses ordinal as the predictors with manual feature selection to the linear multiple regression model. It ends with a 0.9525 R2 and average residual at validation dataset $249. The total dollars in new diamond dataset predicted is $12.7 million and the suggested total investment for 3,000 diamonds is $8.9 million (the suggest investment is the predicted price multiplied by 0.7).  
<p></p>
Model 2 uses dummy features from one hot encoding and machine learning forward feature selection method, which provides with a better performance in comparison with model 1. The R2 is 0.9581 and average residual at validation dataset is $240. The total predicted dollars in new diamond dataset is $12.6 million and the suggested total investment for 3,000 diamonds is $8.8 million.
<p></p>
Model 3 performs the best by using categorical features and letting the machine learning `GLMSELECT` to select effects that consider the interaction, which, indeed, is a process of machine learning in both feature engineering and feature selection. The model results in a R2 at 0.9723 and average residual at validation dataset $175. The total predicted dollars in new diamond dataset is $12.3 million and the suggested total investment for 3,000 diamonds is $8.6 million. 

## CONCLUSIONS
Diamond price prediction used SAS EG 8.1 as the platform and went through the entire lifecycle of data science process starting from EDA to obtain the understanding of dataset about diamond. The EDA provided the fundament for the further predictive modeling analysis, which included feature engineering, feature selection, model training, validation and diamond price prediction. The model has achieved a 0.9723 R Square and an average residual between predicted price and actual price at $175.  And the final suggested investment for entire 3,000 diamonds will be $8.6 million, which saved $0.3 million from model 1. Although the historical diamond price was not normally distributed and the transformed price showed a bimodal distribution pattern, the machine learning particularly `GLMSELECT` performed very well with taking the interaction between features into account, which indeed, a process of machine learning in both feature engineering and feature selection. 



