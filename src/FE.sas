
/**************************************************************** 
Feature Engineering (FE) 

FE includes box-cox transformation with natural log for price and 
carat, ordinal feature creation and one hot encoding dummy features.

Macro for both diamonds data set and new diamonds data set.

*****************************************************************/

/*Log transformation and ordinal coding*/
%macro log_ord(infile, outfile);
data project.&outfile.;
	set project.&infile.;

	/*Log transformation - adding 1 to prevent the negative*/
	logcarat=log(1 + carat);
	%if &infile.=diamonds_clean %then 
		%do; 
			logprice=log(1 + price);
			drop depth table x y z;
	%end;

	/*Create ordinal features based on the grade provided by the document*/
	Select (color);
        when ('J') color_ord = 1;
        when ('I') color_ord = 2;
        when ('H') color_ord = 3;
        when ('G') color_ord = 4;           /* G-J = Nearly Colorless */
        when ('F') color_ord = 5;           
        when ('E') color_ord = 6;           
        when ('D') color_ord = 7;           /* D-F = Colorless is highest color grade */
        otherwise;
    End;
	%if &infile.=diamonds_clean %then 
		%do;
			Select (cut);
		        when ('Fair')      cut_ord = 1;     /* Lowest level of fire and brilliance */
		        when ('Good')      cut_ord = 2;
		        when ('Very Good') cut_ord = 3;
		        when ('Premium')   cut_ord = 4;
		        when ('Ideal')     cut_ord = 5;     /* Highest level of fire and brilliance */
		        otherwise;
		    End;

		    Select (clarity);
		        when ('I1')   clarity_ord = 1;      /* Inclusions 1 is the worst */
		        when ('SI2')  clarity_ord = 2;      /* Small Inclusions 1 */
		        when ('SI1')  clarity_ord = 3;      /* Small Inclusions 2 */
		        when ('VS2')  clarity_ord = 4;      /* Very Small Inclusions 1 */
		        when ('VS1')  clarity_ord = 5;      /* Very Small Inclusions 2 */
		        when ('VVS2') clarity_ord = 6;      /* Very Very Small Inclusions 1 */
		        when ('VVS1') clarity_ord = 7;      /* Very Very Small Inclusions 2 */
		        when ('IF')   clarity_ord = 8;      /* Internally Flawless is the best */
		        otherwise;
		    End;
	%end;
run;
%mend;
%log_ord(diamonds_clean, diamonds_FE)
%log_ord(newdiamonds, TestDiamonds_FE)

/*Create dummy features with one hot encoding method*/
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
