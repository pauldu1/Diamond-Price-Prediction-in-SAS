
/*Model 2: Regression with one hot dummy features*/

ODS graphics on;

/*Feature selection - forward method*/
Proc REG data=project.Diamonds_Training;
     logprice_1hot: Model logprice = logcarat 
			cut_1 cut_2 cut_3 cut_4 cut_5
 			color_1 color_2 color_3 color_4 color_5 color_6 color_7 
			clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_6 clarity_7
			clarity_8 /slentry=0.99 selection=forward;
Run;

/*Select cut_3, color_5 and clarity_6 out as feature
selected in forward selection above and build the model*/
Proc REG data=project.Diamonds_Training
         outest=project.Model_2_ParameterEst;
     logprice_1hot: Model logprice = logcarat 
			cut_1 cut_2 cut_4 cut_5
 			color_1 color_2 color_3 color_4 color_6 color_7 
			clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7
			clarity_8;
Run;


/*Evaluate the performance in validation data set*/
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

/*Visualize the performance of model*/
ods graphics on;
proc sgplot data=project.model_2_val;
  scatter x=price y=predicted_price/ transparency=0.9
			markerattrs=(symbol=circlefilled
				size=5
			color=dodgerblue );
			
title color=white 'Scatter Plot of Price by Predicted Price';
footnote color=white 'Remark: Predicted price has outliers';
footnote2 color=white 'as large as $120,000 although very few';

xaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
          minor display=(noline) ;

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
proc univariate data=project.model_2_val;
  histogram Predicted_Price residual/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ods graphics off;

/*Predict diamond price in new diamond data set*/
Proc Score Data=project.TestDiamonds_FE      
           Score=project.Model_2_ParameterEst
           Type=parms
           predict out=project.Model_2_pred;
     
     var logcarat cut_1 cut_2 cut_4 cut_5
 			color_1 color_2 color_3 color_4 color_6 color_7 
			clarity_1 clarity_2 clarity_3 clarity_4 clarity_5 clarity_7
			clarity_8;
Run;

Data project.Model_2_Pred (keep=Predicted_Price carat cut color clarity);
    Set project.Model_2_pred;   
    Predicted_Price = exp(logprice_1hot)-1;
Run;
