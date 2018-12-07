; $Id: convolve_even.pro,v 1.1.1.1 2003/03/07 10:46:32 marcel Exp $
;
;+
; NAME:
;       convolve_even 
;
; PURPOSE:
;       Convolves two images of same size and with x and y dimension with an
;       even number of elements.This routine explicitely assumes that origin is
;       sampled by a unique pixel unless ORIGIN keywork is set to non-zero.
;
; CATEGORY:
;       Matrix manipulation.
;
; CALLING SEQUENCE:
;       image = convolve_even(image1, image2, DOUBLE= double, REDIM= redim)
; 
; INPUTS:
;       image1   : square matrix of even size each dimension.
;
;       image2   : idem.
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       double   : if present and non-zero, FFT operations are performed in
;                  double precission.
;
;       redim    : if present and non-zero, images are reverted into larger
;                  arrays of dimension a power of 2 so that FFT operations are
;                  faster. THIS SOULD BE SET TO ZERO WHEN USING PERIODIC IMAGES.
;
;       origin   : if present and non-zero, CONVOLVE_EVEN understands the images
;                  are sampled at half pixel positions (i.e. origin of each
;                  image is shared by 4 different pixels). In this case,
;                  CONVOLVE_EVEN introduces complex factor so that convolved
;                  image is returned with equal sampling as the input images.
;
; OUTPUTS:
;       image    : result from convolving image1 with image2. Same dimension and
;                  size as image1 and image2.
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
;       Images are:
;       1/ REAL images.
;       2/ Images must be bidimensional (i.e, images) and of same size.
;       3/ Both dimensions x and y must be of even number of elements.
;       
; PROCEDURE:
;       None.
;
; EXAMPLE:
;       Write here an example!       
;
; MODIFICATION HISTORY:
;       Mar 1999: written by B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;       June 1999: B. Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                  -adding ORIGIN keyword.
;-


FUNCTION convolve_even, image1, image2, DOUBLE= double, REDIM= redim, ORIGIN= origin 

   ON_ERROR,2           ;Return to caller if an error occurs.


   ;Checking section
   ;================

   s1 = SIZE(image1)
   s2 = SIZE(image2)

   CASE 1 OF

       (s1[0] NE 2) OR (s2[0] NE 2):                  $
         MESSAGE,'Both inputs must be 2D arrays.'

       (  ABS(s1[3]-3.5) GT 1.5) OR                   $
         (ABS(s2[3]-3.5) GT 1.5):                     $
         MESSAGE,'Both inputs must be or integer or'+ $
         'long-integer, or float or double precission'

       (s1[1] NE s2[1]) OR (s1[2] NE s2[2]):          $
         MESSAGE,'Both images must be of same size.'

       (s1[1] MOD 2) OR (s1[2] MOD 2):                $
         MESSAGE,'Both dimensions of input must ' +   $
         'contain an even number of elements'
       
       KEYWORD_SET(redim): BEGIN

           dummy1 = [64,128,256,512,1024]

           dummy2 = CLOSEST(s1[1],dummy1)
           CASE 1 OF
               (dummy2 EQ -1): nx= s1[1]
               (dummy2 LT  4): BEGIN
                   IF (s1[1] GT dummy1[dummy2]) THEN  $
                     nx=dummy1[dummy2+1]              $
                   ELSE nx=dummy1[dummy2]
               END
               (dummy2 EQ 4): nx=1024
           ENDCASE
           
           dummy2 = CLOSEST(s1[2],dummy1)
           CASE 1 OF
               (dummy2 EQ -1): ny= s1[1]
               (dummy2 LT  4): BEGIN
                   IF (s1[2] GT dummy1[dummy2]) THEN  $
                     ny=dummy1[dummy2+1]              $
                   ELSE ny=dummy1[dummy2]
               END
               (dummy2 EQ 4): ny=1024
           ENDCASE

       END

       ELSE: BEGIN
           nx= s1[1]
           ny= s1[2]
       END

   ENDCASE

   
   ;Storing images in intermediate vars and rearrange
   ;=================================================

   type= s1[3] > s2[3]

   dummy = MAKE_ARRAY(nx,ny, TYPE= type)
   dummy1= MAKE_ARRAY(nx,ny, TYPE= type)
   dummy2= MAKE_ARRAY(nx,ny, TYPE= type)

   dummy[nx/2-s1[1]/2:nx/2+s1[1]/2-1,ny/2-s1[2]/2:ny/2+s1[2]/2-1]= image1
   dummy1=SHIFT(dummy,nx/2,ny/2)

   dummy[nx/2-s1[1]/2:nx/2+s1[1]/2-1,ny/2-s1[2]/2:ny/2+s1[2]/2-1]= image2
   dummy2=SHIFT(dummy,nx/2,ny/2)
  

   ;Fourier transforming
   ;====================

   IF KEYWORD_SET(double) THEN double=1 ELSE double=0
   dummy1= FFT(dummy1,-1,/OVERWRITE, DOUBLE= double) 
   dummy2= FFT(dummy2,-1,/OVERWRITE, DOUBLE= double) 


   ;Taken care of sampling of image
   ;===============================

   IF KEYWORD_SET(origin) THEN BEGIN

       factor= DCOMPLEXARR(nx,ny)

       freq  = (FINDGEN(nx)-nx/2)/FLOAT(nx)
       freq  = SHIFT(freq,-nx/2)
       dummy= EXP(-DCOMPLEX(0,1)*!DPI*freq)
       FOR i=0,ny-1 DO factor[*,i]= dummy

       freq  = (FINDGEN(ny)-ny/2)/FLOAT(ny)
       freq  = SHIFT(freq,-ny/2)
       dummy = EXP(-DCOMPLEX(0,1)*!DPI*freq)
       FOR i=0,nx-1 DO factor[i,*]= dummy * $
         factor[i,*]

   ENDIF ELSE factor=MAKE_ARRAY(nx,ny,VALUE=1.)


   ;Convolution theorem and Fourier transforming.
   ;=============================================

   dummy1= dummy1*dummy2*factor
   dummy1= FFT(dummy1,1,/OVERWRITE, DOUBLE= double)


   ;Rearranging terms and delivering output
   ;=======================================

   dummy2= SHIFT(dummy1,nx/2,ny/2)
                                    
   IF double THEN $
       dummy1= DOUBLE(dummy2[nx/2-s1[1]/2:nx/2+s1[1]/2-1,   $
                             ny/2-s1[2]/2:ny/2+s1[2]/2-1])  $
   ELSE $
       dummy1= FLOAT(  dummy2[nx/2-s1[1]/2:nx/2+s1[1]/2-1,  $
                              ny/2-s1[2]/2:ny/2+s1[2]/2-1])

   RETURN,dummy1*(FLOAT(nx)*FLOAT(ny))                       ;nx*ny= normalization factor

END
