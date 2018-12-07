; $Id: tce_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;
;+
; NAME:
;       tce_prog
;
; PURPOSE:
;       tce_prog represents the scientific algorithm for the 
;       Tip-tilt CEntroiding (TCE) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       error = tce_prog(           $
;                        inp_img_t, $  ; img_t input  structure  
;                        out_com_t, $  ; com_t output structure  
;                        par,       $  ; parameters structure    
;                        INIT=init  $  ; initialisation structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;    program written: Oct 1998, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : Feb 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -written to match general style and requirements on
;                     how to manage initialization process, calibration
;                     procedure and time management according to  released
;                     templates on Feb 1999.
;                   : June 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -allows to use spline fit  or linear fit to convert Q-cell
;                     signals into tilt angles.
;                   : June 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -allows to use a THRESHOLD value so that px with a Nb of
;                     detected photons < THRESHOLD are not used in computations.
;                   : Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
;                   : Jan 2000,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -TCE now accepts inputs coming from IMG module whose
;                     output structure is now of type img_t.
;                   : Feb 2000,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -inp_img_t.pxsize changed to inp_img_t.resolution.
;                   : Apr 2001,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -TCE_GUI considers a new field where Q-cell calibration
;                     constant is fed.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.dmi.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION tce_prog, inp_img_t, out_com_t, par, INIT= init

error = !caos_error.ok                    ;Init error code: no error as default


;1/ CHECKS: - standard checks performed within tce_init.pro
;========== - here checking inp_img_t.data_status is always valid.

ds1 = inp_img_t.data_status

CASE ds1 OF

   !caos_data.not_valid: MESSAGE,'Input img_t.data_status cannot be not_valid.' 

   !caos_data.wait     : BEGIN         ;IMG module is integrating.
      out_com_t.command    = [0.,0.] 
      out_com_t.data_status= !caos_data.wait
      return, error
   END 

   !caos_data.valid    : ds1= ds1

   ELSE                : MESSAGE,'Input img_t has an invalid data status.'

ENDCASE

      ;========================================;
      ; CALCULATING BARYCENTER/Q-CELL ESTIMATOR;
      ;========================================;
    
image= inp_img_t.image
r1   = WHERE(image LT par.threshold, count)
IF (count GT 0) THEN image[r1]=0.

CASE par.detector OF        

   0:BEGIN                                                  ;Quad-cell calculus
      nel = N_ELEMENTS(image[*,0])
      qtotal = TOTAL(image)
   
      qleft  = TOTAL(image[  0  :nel/2-1,*])
      qright = TOTAL(image[nel/2:   *   ,*])

      qdown  = TOTAL(image[*,  0  :nel/2-1])
      qup    = TOTAL(image[*,nel/2:   *   ])
      
      sigx=(qright-qleft)/qtotal
      sigy=(qup-qdown)/qtotal
      
      CASE par.method OF 
         
         0: BEGIN                                           ;WE HAVE SELECTED LINEAR INTERPOLATION!!
            alpha_x = (sigx-init.calibration[0])/         $ ;  LINEAR FIT: q=a+b*tilt where a and b
                      init.calibration[1]*init.sign         ;  have been obtained in a linear fit to
            alpha_y = (sigy-init.calibration[0])/         $ ;  the signal vs tilt angle in the calib.
                      init.calibration[1]*init.sign
         END 

         1: BEGIN                                           ;WE HAVE SELECTED SPLINE INTERPOLATION!!
            alpha_x = init.sign*                          $ ; We then make use of the curve signal vs
                      SPLINE(init.signal, init.tilt, sigx)  ;  tilt angle obtained in the calibration.
            alpha_y = init.sign*                          $
                      SPLINE(init.signal, init.tilt, sigy)
         END 

         2: BEGIN                                           ;WE HAVE SELECTED USING DIRECTLY A CALIB CTE
            alpha_x= sigx*par.cal_cte
            alpha_y= sigy*par.cal_cte
         END 

         ELSE: MESSAGE,'Unknown method to work with ' + $
           'Q-cell. PAR.METHOD must be 0 (linear fit)'+ $
           ' or 1 (spline fit) or 2 (use a cal cte.)'
         
      ENDCASE 
      
   END
   
   1:BEGIN                                                  ;Barycenter calculus
      np = inp_img_t.npixel
      ps = inp_img_t.resolution                             ;Pixel size in [arcsec]
      off= ps/2.*(1.-(np MOD 2))                            ;Half pixel size tilt if even #pixel
                                                            ;  or zero tilt if odd #pixel
      
      IF (np MOD 2) THEN                   $                ;ODD Nb pixels=> origin at 1 pixel
        xccd= (FINDGEN(np)- np/2)*ps       $                ;   Detector axis [arcsec]
      ELSE                                 $                ;EVEN Nb pixels=>origin at 4 pixels
        xccd= (FINDGEN(np)-(np-1.)/2.)*ps                   ;   Detector axis [arcsec]
      
      dummy  =TOTAL(image,2)
      alpha_x=TOTAL(dummy*xccd)/TOTAL(dummy)                ;Tilt along x-axis in [arcsec]
      
      dummy  =TOTAL(image,1)
      alpha_y=TOTAL(dummy*xccd)/TOTAL(dummy)                ;Tilt along y-axis in [arcsec]
   END 
   
   ELSE: BEGIN
      MESSAGE,'TCE only intended to work'+ $
        'on IMG_T structures from IMA',    $
        CONT = NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN,error
   END 
   
ENDCASE 

      ;================;
      ; O/P ASSIGNEMENT;
      ;================;
out_com_t.data_status= !caos_data.valid
out_com_t.command    = [alpha_x,alpha_y]     ;TFL is now the responsible to 
                                             ;invert signs to balance Tiptilt
RETURN,error


END
