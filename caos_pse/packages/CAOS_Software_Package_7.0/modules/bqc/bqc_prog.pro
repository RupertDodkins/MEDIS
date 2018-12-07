; $Id: bqc_prog.pro,v 7.0 2016/04/27 marcel.carbillet $
;
;+
; NAME:
;       bqc_prog
;
; PURPOSE:
;       bqc_prog represents the scientific algorithm for the
;       Barycenter/Quad-cell Centroiding (BQC) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       error = bqc_prog(inp_mim_t,  $  ; mim_t input  structure  
;                        out_meas_t, $  ; meas_t output structure  
;                        par       , $  ; parameters structure
;                        INIT= init)    ; initialisation structure
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;
;       modifications  : December 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -this module does not require INIT.
;
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION bqc_prog, inp_mim_t, out_meas_t, par, INIT=init

   error = !caos_error.ok                                   ;Init error code: no error as default


   ;;1/ CHECKS: - standard checks performed within bqc_init.pro
   ;;========== - here checking inp_mim_t.data_status is always valid.
   ds1 = inp_mim_t.data_status

   CASE ds1 OF
      !caos_data.not_valid: MESSAGE, 'Input mim_t.data_status cannot be not_valid.' 
 
     !caos_data.wait: BEGIN                           ;SWS module is integrating.
         out_meas_t.data_status = !caos_data.wait
         return, error
      END 

      !caos_data.valid: ds1 = ds1

      ELSE: MESSAGE, 'Input mim_t has an invalid data status.'

   ENDCASE



   ;;2/ CALCULATING BARYCENTER/Q-CELL ESTIMATOR;
   ;;==========================================;
   meas = FLTARR(2*inp_mim_t.nsp)                           ;Array of centroid MEASurements.
   nx   = inp_mim_t.npixpersub                              ;Number of CCD pixels on a side of subaperture.
   off  = inp_mim_t.pxsize/2.*(1.-(nx MOD 2))               ;Tilt: (0.5/0) pixel size if (even/odd) number of pixels.
   

   FOR isa = 0, inp_mim_t.nsp-1 DO BEGIN                    ;LOOP ON THE ACTIVE SUBAPERTURES: isa=subaperture index.

      icol = inp_mim_t.sub_ap[isa]  /  inp_mim_t.nxsub      ;COLUMN index (matches choice in SHS) of this VALID subap.
      irow = inp_mim_t.sub_ap[isa] MOD inp_mim_t.nxsub      ;ROW    index (matches choice in SHS) of this VALID subap.
      
      ix1 = icol*nx   &    iy1 = irow*nx
      ix2 = ix1+nx-1  &    iy2 = iy1+nx-1
      
      image = inp_mim_t.image [ix1:ix2, iy1:iy2]            ;Extracting this VALID subaperture image.


      CASE par.detector OF        


         ;;QUAD-CELL CALCULUS
         ;;==================
         0:BEGIN                                            
            qT = TOTAL(image)                               ;TOTAL signal
            qL  = TOTAL((image*init.weight_X)[0:nx/2-1, *]) ;LEFT  signal
            qD  = TOTAL((image*init.weight_Y)[*, 0:nx/2-1]) ;DOWN  signal
            
            IF (nx MOD 2) THEN BEGIN                          ;If Nb. pixels subapert. is odd then central row/column
               qR = TOTAL((image*init.weight_X)[nx/2+1:*, *]) ;contributes by 1/2 to either qup & qdown /qright & qleft
               qU = TOTAL((image*init.weight_Y)[*, nx/2+1:*]) ;and when computing sigx & sigy central row/col cancels!!
            ENDIF ELSE BEGIN 
               qR = TOTAL((image*init.weight_X)[nx/2:*, *]) ;RIGHT signal
               qU = TOTAL((image*init.weight_Y)[*, nx/2:*]) ;UP    signal
            ENDELSE

            alpha_x = (qR-qL)/qT*init.CalCte/inp_mim_t.pxsize ;This subaperture local x-tilt in UNITS OF PIXELS.
            alpha_y = (qU-qD)/qT*init.CalCte/inp_mim_t.pxsize ;This subaperture local y-tilt in UNITS OF PIXELS.
         END
         

         ;;BARYCENTER CALCULUS
         ;;===================
         1:BEGIN
            IF (nx MOD 2) THEN                   $          ;ODD Nb pixels=> origin at 1 pixel
              xccd = (FINDGEN(nx)- nx/2)         $
            ELSE                                 $          ;EVEN Nb pixels=>origin at 4 pixels
              xccd = (FINDGEN(nx)-(nx-1.)/2.)
            
            dummy   = TOTAL(image*init.weight_X, 2)
            dummy1  = TOTAL(dummy)
            IF dummy1 NE 0 THEN                  $
              alpha_x = TOTAL(dummy*xccd)/dummy1 $          ;This subaperture local x-tilt in UNITS OF PIXELS.
            ELSE                                 $
              alpha_x = 0.

            dummy   = TOTAL(image*init.weight_Y, 1)
            dummy1  = TOTAL(dummy)
            IF dummy1 NE 0 THEN                  $
              alpha_y = TOTAL(dummy*xccd)/dummy1 $          ;This subaperture local y-tilt in UNITS OF PIXELS.
            ELSE                                 $
              alpha_y = 0.

         END 
         
         ELSE: MESSAGE, 'BQC only intended to work'+ $
                        'on MIM_T structures.'
      ENDCASE 
  
      meas[isa              ] = alpha_x                     ;x-tilt in units of pixels on this VALID subaperture.
      meas[isa+inp_mim_t.nsp] = alpha_y                     ;y-tilt in units of pixels on this VALID subaperture.


   ENDFOR


    
   ;;3/  O/P ASSIGNEMENT
   ;;===================
   out_meas_t.data_status = !caos_data.valid
   out_meas_t.meas        = meas
   

   RETURN, error

END