/*---------------------------------------------------------------------
 *  Copyright (C), 2021
 *  SAS Institute Inc., Cary, N.C. 27513, U.S.A.  All rights reserved.
 * --------------------------------------------------------------------
 *
 *  NAME:         %distance macro
 *  LANGUAGE:     SAS
 *  SCRIPT:
 *  PURPOSE:
 *     Use K-nearest neighbor criterion to define a neighbor relationship.
 *  The distance between two observation units is defined to be the
 *  geodetic distance between them using their longitude and latitude coordinates.
 *
 *  NOTES:
 *     Restrictions:
 *        - Supports only numeric IDVAR
 *     Input:
 *        shapefile:
 *           String with path to file.
 *         idvar:
 *             spatial id variable
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
%macro distance(shapefile,idvar=ID,K=K,OUTWS=W);

  %put NOTE: The DISTANCE macro creates sparse representation of a spatial weights matrix using K-nearest neighbor criterion;

  /*Import the Shapefile into SAS*/	
  proc mapimport datafile=&shapefile out=mapdata;
  run;

  /*Check if the shape file exists*/
  %if &syserr > 4 %then %do;
      %put ERROR: Error Reading shapefile &shapefile.;
      %goto endit;
  %end;

  /*Check if the user specified ID variable exists*/
  %let fid=%sysfunc(open(mapdata));
  %if %sysfunc(varnum(&fid,&idvar)) <= 0 %then %do;
      %put ERROR: ID variable &idvar does not exist in the shapefile.;
	  %goto endit;
  %end;

  %let idvarType=%sysfunc(vartype(&fid,%sysfunc(varnum(&fid,&idvar))));
  %let fid=%sysfunc(close(&fid));

  /*Check if the type of idvar is NUMERIC*/
  %if &idvarType^=N %then %do;
     %put ERROR: ID variable &idvar has to be of NUMERIC type.;
     %goto endit;
  %end;


  proc iml;
  use mapdata;
    read all var {&idvar lon lat} into temp[colname=col];
  close; 

  /*Obtain longitude and latitude coordinates for each observation unit.
   */
  rowno=uniqueby(temp,1);
  id=temp[rowno,1];
  clon=temp[rowno,2];
  clat=temp[rowno,3];

  /*
   *Get the number of unique observation units.
   */
  nunits=nrow(rowno);
  distvec=j(nunits,1,.);
  Ws=j(nunits*&K,3,1);
  ndx=j(nunits,1,.);

  /*Use K nearest-neighbor criterion to define a neighbor relationship.
   */
  do i=1 to nunits;
     do j=1 to nunits;
	    dist=geodist(clat[i],clon[i],clat[j],clon[j],"m");
        distvec[j]=dist;
	 end;
	 call sortndx(ndx,distvec,1);
	 rid_start=(i-1)*&K;
	 do k=1 to &K;
        Ws[rid_start+k,1]=id[i];
        Ws[rid_start+k,2]=id[ndx[k+1]];
	 end;
  end;

  idvarname=col[1];
  cname=idvarname // catx("","c",idvarname) // "Weight";
  create &OUTWS from Ws[colname=cname];
  append from Ws;
  close &OUTWS;
quit;

%endit:
%mend distance;

%distance("U:\SGF\data\boston_tracts.shp",IDVAR=tract,K=6,OUTWS=W2);
