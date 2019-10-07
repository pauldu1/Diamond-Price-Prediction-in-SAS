
/*Model 3 GLMSESLECT model selection and evaluation*/

ODS graphics on;
Proc GLMSELECT data=project.Diamonds_Training valdata=project.Diamonds_Validation
               PLOTS=All;
     
     Class Cut Color Clarity;

     Model logprice = logcarat|cut|color|clarity @2 / Choose=Validate
                                                      Stats=(ASE AIC ADJRSQ)
                                                      ;
     output out=project.Model_3_Stat
            P=pred_price3
            R=Residual3            
            ;
Run;
ODS graphics off;

/*Evaluate the performance of model in price prediction*/
Data project.Model_3_stat (keep=price Predicted_Price residual carat cut color clarity);
    Set project.Model_3_stat;   
    Predicted_Price = exp(pred_price3)-1;
	residual=Predicted_price-price;
Run;

/*Visualize the performance of model*/
ods graphics on;
proc sgplot data=project.model_3_stat;
  scatter x=price y=predicted_price/ transparency=0.9
						   markerattrs=(symbol=circlefilled
						     			size=5
										color=dodgerblue )
						;
title color=white 'Scatter Plot of Price by Predicted Price';
footnote color=white 'Remark: Predicted price has outliers';
footnote2 color=white 'as large as $30,000 although very few';

xaxis label='price'
	  labelattrs=(color=dimgray weight=bold)
	  
	  valueattrs=(color=gray)
      minor display=(noline) 
      ;
yaxis label='predicted price'
	  labelattrs=(color=dimgray weight=bold)
	  valueattrs=(color=gray)
	  grid
	  gridattrs=(color=lightgray)
	  minorgrid
	  minorgridattrs=(color=lightgray)
      display=(noline noticks) 
      ;
format price predicted_price DOLLAR.;
run;
ods graphics off;

ods graphics on;
ods noproctitle;
ods select Histogram;
title;
footnote;
proc univariate data=project.model_3_stat;
  histogram Predicted_Price residual/normal;
  inset min max mean std Q1 Q3 skewness kurtosis/pos=ne;
run;
ods graphics off;

