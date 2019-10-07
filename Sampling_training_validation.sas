
/**************************************************************** 
Split diamonds feature engineering file into training and 
validation data sets.
*****************************************************************/

/*Spliting: Select 70% sample data with simple random sampleing method*/
proc surveyselect data=project.diamonds_FE
    out=project.Diamonds_Train_Valid /*exports to work library*/
    method=SRS    /*simple random sampling*/
    samprate=0.7     /* Wanted Training Dataset 70% */
    seed=1357924
    outall; /*includes all observations from the input data set
	         and also each observation’s selection status*/
run;

/*Select training and validation data sets and export*/
Data project.Diamonds_Training project.Diamonds_Validation;
    Set project.Diamonds_Train_Valid;
    If Selected Then /*selection staus - 1 is selected*/
        output project.Diamonds_Training;
    Else 
        output project.Diamonds_Validation;
Run;



