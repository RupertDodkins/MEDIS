; $Id: closest.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;
;+
; NAME:
;       closest
;
; PURPOSE:
;       closest returns the index within an array which is closest to the
;       user supplied value. If value is outside bounds of array, closest
;       returns -1.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       err = closest(scalar,array)
; 
; INPUTS:
;       scalar: any scalar type.
;       array : array of values (Need not to be monotonic nor equally
;                spaced) 
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       err   : long. Index (within array) of the element lying nearest to
;               scalar. 
;
; OPTIONAL OUTPUTS:
;       See keywords 
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       None.
;
; PROCEDURE:
;       Computes ABSOLUTE distance and finds its minimum.
;
; EXAMPLE:
;       IDL> a=FINDGEN(10)
;       IDL> PRINT, CLOSEST(2.3,a)
;       % Compiled module: CLOSEST. 
;           2 
;
; MODIFICATION HISTORY:
;       program written: Oct 1998,
;                        B. Femenia (OAA) <bfemenia@arcetri.astro.it>
;-


FUNCTION closest, x, array
   ON_ERROR,2
   minimo= MIN(array,MAX=maximo)
   IF ( (x GT maximo) OR (x LT minimo) ) THEN $
       RETURN,-1                              $
   ELSE BEGIN
       minimo= MIN(ABS(x-array),index)
       RETURN, index
   ENDELSE

END
