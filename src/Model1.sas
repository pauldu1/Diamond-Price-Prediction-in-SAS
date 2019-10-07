
/*Model 1: Regression with ordinal features*/

ODS graphics on;

/*Build and train the model*/
Proc REG data=project.Diamonds_Training
         outest=project.Model_1_ParameterEst;
     logprice_ord: Model logprice = logcarat cut_ord color_ord clarity_ord; 
Run;

/*Evaluate the performance in validation data set*/
Proc Score Data=project.Diamonds_Validation      
           Score=project.Model_1_ParameterEst
           Type=parms
           predict out=project.Model_1_val;

	var logcarat cut_ord color_ord clarity_ord;

Run;

Data project.Model_1_val (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_1_val;   
    Predicted_Price = exp(logprice_ord)-1;
	residual=Predicted_price-price;
Run;

/*Visualize the performance of model*/
ods graphics on;
proc sgplot data=project.model_1_val;
  scatter x=price y=predicted_price/ transparency=0.9
			markerattrs=(symbol=circlefilled
				size=5
			color=dodgerblue);

title color=white 'Scatter Plot of Price by Predicted Price';
footnote color=white 'Remark: Predicted price has outliers';
footnote2 color=white 'as large as $150,000 although very few';

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
ods graphics off;

ods graphics on;
ods noproctitle;
ods select Histogram;
title;
footnote;
proc univariate data=project.model_1_val;
  histogram Predicted_Price residual/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ods graphics off;

/*Predict diamond price in new diamond data set*/
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
