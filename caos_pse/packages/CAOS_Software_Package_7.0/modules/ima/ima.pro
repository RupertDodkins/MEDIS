; $Id: ima.pro,v 7.0 2016/04/29 marcel.carbillet$
;+
; NAME:
;       ima
;
; ROUTINE'S PURPOSE:
;       IMA manages the simulation for the IMage Adding (IMA) module,
;       that is:
;       1-call the module's initialisation routine ima_init at the first
;         iteration of the simulation project
;       2-call the module's program routine ima_prog otherwise.
;
; MODULE'S PURPOSE:
;       IMA receives two wavefronts as inputs and returns their sum/difference
;       according to weights supplied by user. This module has been developed to
;       check performance of the software and does not care about
;       intensities. Accordingly, the output is assigned the same values of
;       n_phot and background (see doc on gpr for info on these tags) of the
;       first input, unless IMA is used as a "duplicator" of correction in which
;       case it detects which input is the correction and which one is the wf
;       to be corrected.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = ima(inp_img_t1, inp_img_t2, out_img_t, par)
;
; OUTPUT:
;       error:long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_img_t1:incoming image. (Bottom input in Application builder)
;
;       inp_img_t2:incoming image. (Top input in Application builder)
;
;       par       :parameters structure from ima_gui. In addition to the usual
;                  tags associated with the overall management of the program,
;                  it contains the following tags:
;
;                  par.wb: assigned weight (+1 or -1) to first input (in
;                          AppBuilder, bottom box!!)
;                  par.wt: assigned weight (+1 or -1) to second input (in
;                          AppBuilder, top box!!)
;
; INCLUDED OUTPUTS:
;       out_img_t :output wavefront with intensity arbitrarily normalized to 1.
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
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; MODIFICATION HISTORY:
;       program written: september 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ima, inp_img_t1, $ ; input structure 
              inp_img_t2, $ ; input structure
              out_img_t , $ ; output structure
              par           ; parameters from ima_gui

COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                      ; Init error code: no error as default

IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
   error = ima_init(inp_img_t1, inp_img_t2, out_img_t, par)
ENDIF ELSE BEGIN                                            ; NORMAL RUNNING
   error = ima_prog(inp_img_t1, inp_img_t2, out_img_t, par)
ENDELSE 

RETURN, error
END