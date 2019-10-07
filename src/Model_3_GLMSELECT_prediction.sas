
/*Model 3 GLMSESLECT predict diamond price in new dataset*/

ODS graphics on;

/* Prepare Unknown dataset for prediction */
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

Data project.Model_3_new_pred (drop=logprice);
    Set project.Model_3_new_pred;
    If DS = "TEST";
    Predicted_Price = exp(Predicted_Price_3)-1;
Run;
