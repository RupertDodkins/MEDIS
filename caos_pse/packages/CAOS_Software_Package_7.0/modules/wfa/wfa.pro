; $Id: wfa.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       wfa
;
; ROUTINE'S PURPOSE:
;       WFA manages the simulation for the WaveFront Adding (WFA) module,
;       that is:
;       1-call the module's initialisation routine wfa_init at the first
;         iteration of the simulation project
;       2-call the module's program routine wfa_prog otherwise.
;
; MODULE'S PURPOSE:
;       WFA receives two wavefronts as inputs and returns their sum/difference
;       according to weights supplied by user. This module has been developed to
;       check performance of the software and does not care about
;       intensities. Accordingly, the output is assigned the same values of
;       n_phot and background (see doc on gpr for info on these tags) of the
;       first input, unless WFA is used as a "duplicator" of correction in which
;       case it detects which input is the correction and which one is the wf
;       to be corrected.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = wfa(inp_wfp_t1, inp_wfp_t2, out_wfp_t, par)
;
; OUTPUT:
;       error:long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_wfp_t1:incident wavefront. (Bottom input in Application builder)
;
;       inp_wfp_t2:incident wavefront. (Top input in Application builder)
;
;       par       :parameters structure from wfa_gui. In addition to the usual
;                  tags associated with the overall management of the program,
;                  it contains the following tags:
;
;                  par.wb: assigned weight (+1 or -1) to first input (in
;                          AppBuilder, bottom box!!)
;                  par.wt: assigned weight (+1 or -1) to second input (in
;                          AppBuilder, top box!!)
;
; INCLUDED OUTPUTS:
;       out_wfp_t :output wavefront with intensity arbitrarily normalized to 1.
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
;       This module does not consider the effect on the intensity as it is not
;       intended to simulate interferometry. It's been developed only to allow
;       easy and fast visualization of AO effects on wavefronts.
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; MODIFICATION HISTORY:
;       program written: April 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;       modifications  : Dec 1999, 
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole CAOS Software System.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written: B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;       modifcations  : for version 2.0,
;                       B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : for version 4.0,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole CAOS Software System.
;                      : for version 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted.
;-
;
FUNCTION wfa, inp_wfp_t1, $ ; input structure 
              inp_wfp_t2, $ ; input structure
              out_wfp_t , $ ; output structure
              par           ; parameters from wfa_gui


COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                      ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
                                                            ;===============
   error = wfa_init(inp_wfp_t1,inp_wfp_t2, out_wfp_t, par)

ENDIF ELSE BEGIN                                            ; NORMAL RUNNING: WFA does not consider
                                                            ;===============  integration nor delay
   error = wfa_prog(inp_wfp_t1,inp_wfp_t2, out_wfp_t, par)

ENDELSE 

RETURN, error
END