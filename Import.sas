/**************************************************************** 
Project: Diamond Price Prediction
Project Manager: Paul Du 
Date: Sep 15 - Oct 5 2019
Don Valley Solution Ltd.

The code include data import, exploratory data analysis (EDA), 
feature engineering(FE), feature selection, modeling and price 
prediction.
*****************************************************************/

/*Import raw diamonds and new diamonds data sets*/
%macro import(folder, input, ouput);
proc import datafile="D:\DSPS\DIAMONDS\DATA\&folder.\&input..csv"
     out=project.&ouput.
     dbms=csv
     replace;
     guessingrows=Max; /* or guessingrows=100 */     
     getnames=yes;     /* datarow=1 if no header name */
run;

Data project.&ouput.;
     Format rec_id BEST12.;
     Set project.&ouput.;
     rec_id = input(VAR1, BEST12.);
     Drop VAR1;
Run;
%mend;

%import(training, diamonds, diamonds_raw)
%import(test, new_diamonds, TestDiamonds)