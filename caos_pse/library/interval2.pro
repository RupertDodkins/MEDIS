; $Id: interval2.pro,v 1.2 2003/03/10 09:03:22 marcel Exp $
;
;+
; NAME:
;       interval2
;
; PURPOSE:
;       Given two intervals [x1,x2] and [y1,y2], INTERVAL finds the fraction of
;       the overlap between them in terms of the total length of interval [y1,y2]
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       frac = interval2(x1,x2,y1,y2,x1_out,x2_out)
; 
; INPUTS:
;       x1   : left  end of first  interval
;       x2   : right end of first  interval
;       y1   : left  end of second interval
;       y2   : right end of second interval
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       frac : fraction of the smallest interval falling within the 2nd  interval 
;
; OPTIONAL OUTPUTS:
;       x1_out,x2_out: define new first interval after removal of portion of second interval
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
;       None.
;
; EXAMPLE:
;       Write here an example!       
;
; MODIFICATION HISTORY:
;       Sep 2001: written by B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;-

FUNCTION interval2, x1, x2, y1, y2, x1_out, x2_out

   ON_ERROR,2

   IF (x1 GT x2) THEN $
     MESSAGE,'Inputs for first interval are reversed!'
   
   IF (y1 GT y2) THEN $
     MESSAGE,'Inputs for second interval are reversed!'
   
   
   c1=FLOAT(x1+x2)/2.
   r1=FLOAT(x2-x1)/2.
   
   c2=FLOAT(y1+y2)/2.
   r2=FLOAT(y2-y1)/2.

   x1_out = x1
   x2_out = x2
   
   CASE 1 OF
      
      (r1*r2 EQ 0): frac = 0.                               ;One of the intervals of zero length
      
      (ABS(c1-c2) GE (r1+r2)): frac = 0.                    ;=> NO  overlap!
      
      (ABS(c1-c2)+r2 LE r1): BEGIN                          ;=> Second interval completely within first interval
         frac   = 1.
         x1_out = y2
         x2_out = x2
      END 

      (ABS(c1-c2)+r1 LE r2): BEGIN                          ;=> First interval completely within second interval
         frac = r1/r2
         x1_out = x2
         x2_out = x2
      END

      (y1 LT x2) AND (y1 GT x1): BEGIN
         frac   = (x2-y1)/(2*r2)
         x1_out = x1
         x2_out = y1
      END 

      (y1 LT x1) AND (y2 LT x2): BEGIN
         frac = (y2-x1)/(2*r2)
         x1_out = y2
         x2_out = x2
      END
         

      ELSE: MESSAGE,'Which case is this that has not been taken into account?'
      
   ENDCASE

   RETURN,frac
   
END 
