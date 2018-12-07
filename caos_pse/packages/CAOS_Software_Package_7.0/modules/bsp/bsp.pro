; $Id: bsp.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;       bsp
;
; ROUTINE'S PURPOSE:
;       BSP manages the simulation for the Beam SPlitter (BSP) module,
;       that is:
;       1-call the module's initialisation routine bsp_init at the first
;         iteration of the simulation project
;       2-call the module's program routine bsp_prog otherwise.
;
; MODULE'S PURPOSE:
;       BSP executes the simulation for the Beam SPlitter (BSP) module.  This
;       module receives a wavefront and splits it into two wavefronts with the
;       same wavefront perturbation and such that the sum of their intensities
;       is equal to the intensity of the incident wavefront.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = bsp(inp_wfp_t, out_wfp_t1, out_wfp_t2, par)
;
; OUTPUT:
;       error     :long scalar (error code, see !caos_error var in caos_init).
;
; INPUTS:
;       inp_wfp_t :incident wavefront of intensity I.
;
;       par       :parameters structure from bsp_gui. In addition to the usual
;                  tags associated with the overall management of the program,
;                  it contains the following tag:
;
;                    par.frac: Fraction of total intensity sent to first output
;                              wavefront (in AppBuilder, bottom box!!)
;
; INCLUDED OUTPUTS:
;       out_wfp_t1:output wavefront identical to inp_wfp_t except in intensity
;                  which is now I1, such that I1+I2= I.
;
;       out_wfp_t2:output wavefront identical to inp_wfp_t except in intensity
;                  which is now I2, such that I1+I2= I.
;
; KEYWORD PARAMETERS:
;       None.      
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : total number of iteration during the simulation run.
;       this_iter  : current iteration number.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       No chromatic behaviour: it splits the same way all wavelengths
;       travelling along the simulation with the wavefront.
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; ROUTINE MODIFICATION HISTORY:
;       program written: March 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Nov 1999, 
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole CAOS Software System.
;
; MODULE MODIFICATION HISTORY:
;       module written : B. Femenia   (OAA) [bfemenia@arcetri.astro.it].
;
;       modifications  : for version 2.0,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                       -adapted to new version CAOS (v 2.0).
;                      : for version 4.0,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole CAOS Software System.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
;;;;;;;;;;;;;;;
; module code ;
;;;;;;;;;;;;;;;
;
FUNCTION bsp, inp_wfp_t , $ ; input structure 
              out_wfp_t1, $ ; output structure
              out_wfp_t2, $ ; output structure
              par           ; parameters from bsp_gui


COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok           ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
                                                            ;===============
   error = bsp_init(inp_wfp_t ,out_wfp_t1,out_wfp_t2,par)

ENDIF ELSE BEGIN                                            ; NORMAL RUNNING: BSP does not consider
                                                            ;===============  integration nor delay
   error = bsp_prog(inp_wfp_t ,out_wfp_t1,out_wfp_t2,par)

ENDELSE 

RETURN, error
END