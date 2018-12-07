; $Id: rebin_ccd.pro,v 1.1.1.1 2003/03/07 10:46:32 marcel Exp $
;
;+
; NAME:
;       rebin_ccd
;
; PURPOSE:
;       rebin_ccd function shrinks the size of a square  array by an arbitrary
;       ammount. Unlike the standard IDL routine CONGRID, rebin_ccd conserves
;       the total value of the array as it does not involve any linear
;       interpolation. rebin_ccd has been written to simulate the process of
;       sampling a 2D field from a given resolution into a second resolution
;       with higher pixel size of the original 2D array. It is assumed that the
;       original square matrix and the resized matrix are centred.
;
; CATEGORY:
;       Matrix manipulation.
;
; CALLING SEQUENCE:
;       array_ccd = rebin_ccd(xwf,xccd,array_wf)
; 
; INPUTS:
;       xwf      : x-coordinate values of the original squared matrix.
;
;       xccd     : x-coordinate values of the pixels at which original squared
;                  matrix is wished to be resized.
;
;       array_wf : original squared matrix at a resolution given by pixels with
;                  x- and y-coordinate values given in xwf.
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       array_ccd: resized matrix. This is also a square matrix with a TOTAL value
;       equal to the input matrix and pixelized according to the input array
;       xccd. In case that a original pixel is shared by more than one xccd
;       pixel, the value of the original pixel is shared between the concerned
;       xccd pixels according to the fraction of the area of original pixel
;       falling on each of the xccd pixels.
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
;
; PROCEDURE:
;       None.
;
; EXAMPLE:
;       Write here an example!       
;
; MODIFICATION HISTORY:
;       Nov 1998: written by B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;-


FUNCTION rebin_ccd, xwf,xccd,I_wf

   ON_ERROR,2                               ;Return to caller if error occurs!

   swf= SIZE(I_wf)

   IF ( (swf[0]+swf[1]) LT 2) THEN MESSAGE,'I_wf is undefined or not a 2D array'
   IF (swf[1] NE swf[2])      THEN MESSAGE,'only square matrices are allowed'

   nx    = swf[1]
   fill_x= FLTARR(nx)
   np    = N_ELEMENTS(xccd)

   taux= (xwf[ nx-1]-xwf[ 0])/(nx-1.)         ;WF  pixel size ["]
   w   = (xccd[np-1]-xccd[0])/(np-1.)         ;CCD pixel size ["]
   IF (taux GE w) THEN MESSAGE,'xccd sampled at higher rate than xwf. Should be the opposite!'

   ;Choosing type of I_ccd
   ;======================

   CASE swf[3] OF
       1: I_cdd= LONARR(np+2,np+2)           ;From BIN to LON or INT to 
       2: I_ccd= LONARR(np+2,np+2)           ;   LON to avoid overflow.
       3: I_ccd= LONARR(np+2,np+2)
       4: I_ccd= DBLARR(np+2,np+2)           ;FLT->DBL to avoid overflow
       5: I_ccd= DBLARR(np+2,np+2)
       ELSE: MESSAGE,'ccd_int only works on real valued matrices!!'
   ENDCASE


   ;PROCEED TO REBIN
   ;================

   xaxis=[xccd[0]-w,xccd,xccd[np-1]+w]

   index1= CLOSEST(xwf[0]   , xaxis) > 0
   index2= CLOSEST(xwf[nx-1], xaxis)
   IF (index2 LT 0) THEN index2= np
   IF ((xwf[nx-1]+taux/2) GT (xaxis[index2]+w/2.)) THEN index2=index2+1


;First concerned XAXIS pixel: special case.
;------------------------------------------
   r1= WHERE( ABS(xwf-xaxis[index1]) LT (w+taux)/2., c1 )
   fill_x[r1]= 1.


;From 2nd concerned XAXIS to before last pixels.
;-----------------------------------------------

   FOR i=index1+1,index2-1 DO BEGIN
       r1= WHERE( ABS(xwf-xaxis[i]) LT (w+taux)/2., c1 )      ; CCD pixels don't overlap => only 
       fill_x[r1[1:*]]= 1.                                    ; possible shared pixel is first one

       IF (fill_x[r1[0]] AND (i NE 0)) THEN BEGIN
           fill_x[r1[0]]=(xaxis[i-1]+w/2.-xwf[r1[0]]+taux/2.)/taux
           XAXIS[0]=XAXIS[0]+0.
       ENDIF ELSE BEGIN
           fill_x[r1[0]]= 1.
           XAXIS[0]=XAXIS[0]+0.
       ENDELSE
   ENDFOR


;Last concerned XAXIS pixel: special case.
;-----------------------------------------

   r1= WHERE( ABS(xwf-xaxis[index2]) LT (w+taux)/2., c1 )

   IF ( fill_x[r1[0]]) THEN                                           $
        fill_x[r1[0]]= (xaxis[index2-1]+w/2.-xwf[r1[0]]+taux/2.)/taux $
   ELSE fill_x[r1[0]]= 1.

   IF (c1 GE 2) THEN fill_x[r1[1:*]]= 1. 


;STANDARD CASE:   Pixels are the same big in both x & y-directions. Same
;**************    number of pixels and CCD center aligned with WF center

   ywf = xwf     &    fill_y= fill_x    &    i1= index1    &    j1= index1
   yccd= xccd    &    yaxis = xaxis     &    i2= index2    &    j2= index2


   dx= fill_x
   dy= fill_y


   FOR j= j1, j2 DO BEGIN

       r2= WHERE( ABS(ywf-yaxis[j]) LT (w+taux)/2., c2)

       FOR i= i1, i2 DO BEGIN

           r1= WHERE( ABS(xwf-xaxis[i]) LT (w+taux)/2., c1)

           dummy1= REBIN(          dx[r1[0]:r1[c1-1]] ,c1,c2)
           dummy2= REBIN(TRANSPOSE(dy[r2[0]:r2[c2-1]]),c1,c2)

           I_ccd[i,j]= TOTAL(I_wf[r1[0]:r1[c1-1],r2[0]:r2[c2-1]]*dummy1*dummy2)

           dx[r1[0]:r1[c1-1]]= ABS(1.- dx[r1[0]:r1[c1-1]])

       ENDFOR

       dy[r2[0]:r2[c2-1]]= ABS(1.- dy[r2[0]:r2[c2-1]])
       dx= fill_x

   ENDFOR
   
        
   RETURN, I_ccd[1:np,1:np]

END
