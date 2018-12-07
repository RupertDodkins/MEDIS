; $Id: stdev_weighted.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;
;+
; NAME:
;       stdev_weighted
;
; PURPOSE:
;       stdev_weighted computes the weighted standard deviation, mean and
;       stadndard deviation of mean of a vector of data points (first column of
;       input) having associated a vector of weights (second column of
;       input). Weights are used as if they were the corresponding standard
;       deviations of each data point.
;
; CATEGORY:
;       Utility; Statistics.
;
; CALLING SEQUENCE:
;       std = stdev_weighted(array, mean, std_mean)
; 
; INPUTS:
;       array: 2d array, such that the data poins are in column 0 and their
;              standard deviation in column 1 (Routine uses standard deviation
;              of each data point as weight)
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       std  : weighted standard deviation.
;
; OPTIONAL OUTPUTS:
;       mean    : weighted mean.
;       std_mean: standard deviation of mean.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       The input must be a 2d array, such that the data poins are in column 0
;       and their associated standard deviations in column 2. Weights are used
;       as if they were the corresponding standard deviations of each data
;       point. 
;
; PROCEDURE:
;       None.
;
; EXAMPLE:
;       Write here an example!       
;
; MODIFICATION HISTORY:
;       Mar 1999: written by B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;-


FUNCTION stdev_weighted, array, mean, std_mean

   ON_ERROR,2

   points= N_ELEMENTS(array[0,*])
   
   w= TRANSPOSE(array[1,*])
   
   w= 1./w^2
   
   error_index=CHECK_MATH()
   
   IF (error_index EQ 16) THEN $
     MESSAGE,'Dividing by zero. Check column of standard deviations'
   
   mean    = TOTAL( TRANSPOSE(array[0,*])* w )/ TOTAL(w)
   std_mean= 1./SQRT(TOTAL(w))

   container1= TRANSPOSE(array[0,*]) - mean
   variance  = TOTAL( container1^2*w )/ TOTAL(w)* points/(points-1)
   
   RETURN, SQRT(variance)

END

