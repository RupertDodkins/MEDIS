; $Id: interval.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;
;+
; NAME:
;       interval
;
; PURPOSE:
;       Given two intervals [x1,x2] and [y1,y2], INTERVAL finds the fraction of
;       the overlap between them in terms of the total length of the smallest
;       interval.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       frac = interval(x1,x2,y1,y2)
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
;       frac : fraction of the smallest interval falling within the largest
;              interval 
;
; OPTIONAL OUTPUTS:
;       None.
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
;       Mar 1999: written by B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;-

FUNCTION interval, x1,x2,y1,y2

   ON_ERROR,2

   IF (x1 GT x2) THEN $
     MESSAGE,'Inputs for first interval are reveresed!'

   IF (y1 GT y2) THEN $
     MESSAGE,'Inputs for second interval are reveresed!'


   c1=FLOAT(x1+x2)/2.
   r1=FLOAT(x2-x1)/2.

   c2=FLOAT(y1+y2)/2.
   r2=FLOAT(y2-y1)/2.

   CASE 1 OF

       (r1*r2 EQ 0): RETURN, 0.                  ;One of the intervals of zero length

       (ABS(c1-c2) GE (r1+r2)): RETURN, 0.       ;=> NO  overlap!

       ELSE: BEGIN

           delta= MIN([2*r1,2*r2])

           left_pts = [x1,y1]
           right_pts= [x2,y2]

           l1= MIN(left_pts,index1)
           r1= MAX(left_pts,index2)

           l2=right_pts[index1]
           r2=right_pts[index2]
       
           IF (l1 LE r1) AND (l2 GE r2) THEN   $ ;=> Completely inside!!
                frac= 1.                       $
           ELSE frac= FLOAT(l2-r1)/FLOAT(delta)  ;=> Partially  inside!!

           RETURN,frac

       END 

   ENDCASE


END 
