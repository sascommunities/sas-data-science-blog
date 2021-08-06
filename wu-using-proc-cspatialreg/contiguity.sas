/*---------------------------------------------------------------------
 *  Copyright (C), 2021
 *  SAS Institute Inc., Cary, N.C. 27513, U.S.A.  All rights reserved.
 * --------------------------------------------------------------------
 *
 *  NAME:         %contiguity macro
 *  LANGUAGE:     SAS
 *  SCRIPT:
 *  PURPOSE:
 *     Create a spatial weights matrix based on the contiguity measure using the SAS
 *   data set returned from the call to %NEIGHBOR macro in SAS STAT. The input SAS data set
 *   contains adjacency information for observation units in the data.
 *
 *  NOTES:
 *     Input:
 *        adjacency data set:
 *           The SAS data set returned from the %NEIGHBOR macro containg adjacency information
 *       for observation units.
 *     Output: sparse representation of a spatial weights matrix
 *           W has three columns. The firt two columns are spatial IDs
 *        corresponding to neighboring pairs and the third column is 1 to indicate 
 *        a neighbor relationship.
 *  DISCLAIMER:
 *      THIS INFORMATION IS PROVIDED BY SAS INSTITUTE INC. AS A SERVICE
 *      TO ITS USERS.  IT IS PROVIDED "AS IS".  THERE ARE NO WARRANTIES,
 *      EXPRESSED OR IMPLIED, AS TO MERCHANTABILITY OR FITNESS FOR A
 *      PARTICULAR PURPOSE REGARDING THE ACCURACY OF THE MATERIALS OR CODE
 *      CONTAINED HEREIN.
 *
 *--------------------------------------------------------------------*/


%macro contiguity(adjacency,OUTWS=W);
  %put NOTE: The CONTIGUITY macro creates a sparse spatial weights matrix using adjacent observation units returned by NEIGHBOR macro;

  /*Check if the input adjacency data set exists or not*/
  %let dsexist=%sysfunc(exist(&adjacency));
  %if &dsexist=0 %then %do;
      %put ERROR: Error Reading the data set &adjacency.;
      %goto endit;
  %end;

  proc iml;
  use &adjacency;
    read all var _ALL_ into tmp[colname=col];
  close; 

  nunit=nrow(tmp);
  nvars=ncol(tmp);
  maxK=nvars-1;
  idvar=col[nvars];

  Ws=j(nunit*maxK,3,1);
  rowid=0;
  do i=1 to nunit;
     done=0;
     do j=1 to maxK until(done);
	    if (tmp[i,j] ^= .) then
           do;
		     rowid=rowid+1;
		     Ws[rowid,1]=tmp[i,maxK+1];
		     Ws[rowid,2]=tmp[i,j];
		   end;
		else done=1;
	 end;
  end;

  Ws=Ws[1:rowid,];
  cname=idvar // catx("","c",idvar) // "Weight";
  create &OUTWS from Ws[colname=cname];
  append from Ws;
  close &OUTWS;
quit;

%endit:
%mend contiguity;

%contiguity(adjacent,OUTWS=W1);


